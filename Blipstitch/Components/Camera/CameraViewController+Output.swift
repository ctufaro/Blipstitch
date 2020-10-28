//
//  CameraViewController+Output.swift
//  Blipstitch
//
//  Created by Christopher Tufaro on 10/18/20.
//  Copyright © 2020 Christopher Tufaro. All rights reserved.
//

import Foundation
import AVFoundation
import CoreImage
import UIKit

extension CameraViewController {
    // MARK: - Video Data Output Delegate
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        processPhoto(sampleBuffer: sampleBuffer)
        guard let recordSession = self.recordingSession else { return }
        handleVideoOutput(captureOutput: output, sampleBuffer: sampleBuffer, session: recordSession)
        handleAudioOutput(captureOutput: output, sampleBuffer: sampleBuffer, session: recordSession)
    }
    
    func processVideo(_ captureOutput: AVCaptureOutput!, _ sampleBuffer: CMSampleBuffer!, _ connection: AVCaptureConnection!){
        guard captureOutput != nil,
              sampleBuffer != nil,
              connection != nil,
              CMSampleBufferDataIsReady(sampleBuffer) else { return }
        
        let writable = false
        if writable, sessionAtSourceTime == nil {
            sessionAtSourceTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            videoWriter.startSession(atSourceTime: sessionAtSourceTime!)
        }
        
        // Capturing/Buffering Video
        //if writable, captureOutput == videoDataOutput, videoWriterInput.isReadyForMoreMediaData {
            //if let pixelBuffer = mtkView.pixelBuffer{
                //videoWriterInputPixelBufferAdaptor.append(pixelBuffer, withPresentationTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
            //}
        //}
        // Capturing/Buffering Audio
        //else if cameraHelper.micOn,writable, captureOutput == audioDataOutput, (audioWriterInput.isReadyForMoreMediaData) {
        //audioWriterInput?.append(sampleBuffer)
        //}
    }
    
    func processPhoto(sampleBuffer: CMSampleBuffer) {
        if !renderingEnabled {
            return
        }
        
        guard let videoPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
              let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) else {
            return
        }
        
        var finalVideoPixelBuffer = videoPixelBuffer
        if let filter = videoFilter {
            if !filter.isPrepared {
                /*
                 outputRetainedBufferCountHint is the number of pixel buffers the renderer retains. This value informs the renderer
                 how to size its buffer pool and how many pixel buffers to preallocate. Allow 3 frames of latency to cover the dispatch_async call.
                 */
                filter.prepare(with: formatDescription, outputRetainedBufferCountHint: 3)
            }
            
            // Send the pixel buffer through the filter
            guard let filteredBuffer = filter.render(pixelBuffer: finalVideoPixelBuffer) else {
                print("Unable to filter video buffer")
                return
            }
            
            finalVideoPixelBuffer = filteredBuffer
        }
        
        mtkView.pixelBuffer = finalVideoPixelBuffer
        
        DispatchQueue.main.async {
            if !self.cameraHelper.takePicture {
                return //we have nothing to do with the image buffer
            } else {
                let ciImage = CIImage(cvImageBuffer: finalVideoPixelBuffer)
                let ciContext = CIContext()
                let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent)
                let uiImage = UIImage(cgImage: cgImage!).rotate(radians: .pi/2)
                self.cameraHelper.saveImageToArray(uiImage: uiImage!)
                self.cameraHelper.takePicture = false
            }
        }
    }
    
    func captureShot() {
        DispatchQueue.main.async {
            self.flashScreen()
            self.cameraHelper.takePicture = true
        }
    }
    
    func handleVideoOutput(captureOutput: AVCaptureOutput,sampleBuffer: CMSampleBuffer, session: NextLevelSession) {
        session.setupVideo(videoSize: self.videoSize)
        if self.recording && captureOutput == videoDataOutput && session.currentClipHasStarted {
            if sessionAtSourceTime == nil {
                sessionAtSourceTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                session.startSessionIfNecessary(timestamp: sessionAtSourceTime!)
                session._startTimestamp = sessionAtSourceTime!
            }
            if let pixelBuffer = mtkView.pixelBuffer {
                if let pixelBufferAdapter = session._pixelBufferAdapter {
                    pixelBufferAdapter.append(pixelBuffer, withPresentationTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
                    session._currentClipHasVideo = true
                    session._currentClipDuration = 
                    session.calcVideoClipDuration(withSampleBuffer: sampleBuffer, minFrameDuration: device!.activeVideoMinFrameDuration)
                }
            }
        }
    }
    
    func handleAudioOutput(captureOutput: AVCaptureOutput,sampleBuffer: CMSampleBuffer, session: NextLevelSession){
        if self.recording && captureOutput == audioDataOutput && session.currentClipHasVideo {
            session.appendAudio(withSampleBuffer: sampleBuffer, completionHandler:{(success: Bool) -> Void in })
        }
    }
    
    func handleAudioOutputBlip(captureOutput: AVCaptureOutput,sampleBuffer: CMSampleBuffer, session: NextLevelSession) {
        if self.recording && captureOutput == audioDataOutput && session.currentClipHasVideo {
            if let audioWriterInput = session._audioInput{
                audioWriterInput.append(sampleBuffer)
                session._currentClipHasAudio = true
            }
        }
    }
    
    private func checkSessionDuration() {
        if let session = self.recordingSession,
            let maximumCaptureDuration = self.maximumCaptureDuration {
            if maximumCaptureDuration.isValid && session.totalDuration >= maximumCaptureDuration {
                self.recording = false
                session.endClip(completionHandler: { (sessionClip: NextLevelClip?, error: Error?) in
                })
            }
        }
    }
}
