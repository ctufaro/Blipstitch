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

extension CameraViewController{
    // MARK: - Video Data Output Delegate
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        processPhoto(sampleBuffer: sampleBuffer)
        processVideo(output, sampleBuffer, connection)
    }
    
    func processVideo(_ captureOutput: AVCaptureOutput!, _ sampleBuffer: CMSampleBuffer!, _ connection: AVCaptureConnection!){
        guard captureOutput != nil,
              sampleBuffer != nil,
              connection != nil,
              CMSampleBufferDataIsReady(sampleBuffer) else { return }
        
        let writable = canWrite()
        
        if writable, sessionAtSourceTime == nil {
            sessionAtSourceTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            videoWriter.startSession(atSourceTime: sessionAtSourceTime!)
        }
        
        // Capturing/Buffering Video
        if writable, captureOutput == videoDataOutput, videoWriterInput.isReadyForMoreMediaData {
            if let pixelBuffer = mtkView.pixelBuffer{
                videoWriterInputPixelBufferAdaptor.append(pixelBuffer, withPresentationTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
            }
        }
        // Capturing/Buffering Audio
        else if writable, captureOutput == audioDataOutput, (audioWriterInput.isReadyForMoreMediaData) {
            audioWriterInput?.append(sampleBuffer)
        }
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
        
        if depthVisualizationEnabled {
            if !videoDepthMixer.isPrepared {
                videoDepthMixer.prepare(with: formatDescription, outputRetainedBufferCountHint: 3)
            }
            
            if let depthBuffer = currentDepthPixelBuffer {
                
                // Mix the video buffer with the last depth data received.
                guard let mixedBuffer = videoDepthMixer.mix(videoPixelBuffer: finalVideoPixelBuffer, depthPixelBuffer: depthBuffer) else {
                    print("Unable to combine video and depth")
                    return
                }
                
                finalVideoPixelBuffer = mixedBuffer
            }
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
    
}
