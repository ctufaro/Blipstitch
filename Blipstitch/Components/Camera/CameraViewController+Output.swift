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
        processMetal(sampleBuffer: sampleBuffer)
        guard let recordSession = self.recordingSession else { return }
        handleVideoOutput(captureOutput: output, sampleBuffer: sampleBuffer, session: recordSession)
        handleAudioOutput(captureOutput: output, sampleBuffer: sampleBuffer, session: recordSession)
    }
    
    func processMetal(sampleBuffer: CMSampleBuffer) {
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
}
