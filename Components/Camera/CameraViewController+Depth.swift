//
//  CameraViewController+Depth.swift
//  Blipstitch
//
//  Created by Christopher Tufaro on 10/18/20.
//  Copyright © 2020 Christopher Tufaro. All rights reserved.
//

import Foundation
import AVFoundation

extension CameraViewController{
    // MARK: - Depth Data Output Delegate
    /// - Tag: StreamDepthData
    func depthDataOutput(_ depthDataOutput: AVCaptureDepthDataOutput, didOutput depthData: AVDepthData, timestamp: CMTime, connection: AVCaptureConnection) {
        processDepth(depthData: depthData)
    }
    
    func processDepth(depthData: AVDepthData) {
        if !renderingEnabled {
            return
        }
        
        if !depthVisualizationEnabled {
            return
        }
        
        if !videoDepthConverter.isPrepared {
            var depthFormatDescription: CMFormatDescription?
            CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                         imageBuffer: depthData.depthDataMap,
                                                         formatDescriptionOut: &depthFormatDescription)
            if let unwrappedDepthFormatDescription = depthFormatDescription {
                videoDepthConverter.prepare(with: unwrappedDepthFormatDescription, outputRetainedBufferCountHint: 2)
            }
        }
        
        guard let depthPixelBuffer = videoDepthConverter.render(pixelBuffer: depthData.depthDataMap) else {
            print("Unable to process depth")
            return
        }
        
        currentDepthPixelBuffer = depthPixelBuffer
    }
    
    // MARK: - Video + Depth Output Synchronizer Delegate
    func dataOutputSynchronizer(_ synchronizer: AVCaptureDataOutputSynchronizer, didOutput synchronizedDataCollection: AVCaptureSynchronizedDataCollection) {
        
        if let syncedDepthData: AVCaptureSynchronizedDepthData = synchronizedDataCollection.synchronizedData(for: depthDataOutput) as? AVCaptureSynchronizedDepthData {
            if !syncedDepthData.depthDataWasDropped {
                let depthData = syncedDepthData.depthData
                processDepth(depthData: depthData)
            }
        }
        
        if let syncedVideoData: AVCaptureSynchronizedSampleBufferData = synchronizedDataCollection.synchronizedData(for: videoDataOutput) as? AVCaptureSynchronizedSampleBufferData {
            if !syncedVideoData.sampleBufferWasDropped {
                let videoSampleBuffer = syncedVideoData.sampleBuffer
                processPhoto(sampleBuffer: videoSampleBuffer)
            }
        }
    }
    
    // MARK: - Photo Output Delegate
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        //flashScreen()
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error)")
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let photoPixelBuffer = photo.pixelBuffer else {
            print("Error occurred while capturing photo: Missing pixel buffer (\(String(describing: error)))")
            return
        }
        
        var photoFormatDescription: CMFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                     imageBuffer: photoPixelBuffer,
                                                     formatDescriptionOut: &photoFormatDescription)
        
        processingQueue.async {
            var finalPixelBuffer = photoPixelBuffer
            if let filter = self.photoFilter {
                if !filter.isPrepared {
                    if let unwrappedPhotoFormatDescription = photoFormatDescription {
                        filter.prepare(with: unwrappedPhotoFormatDescription, outputRetainedBufferCountHint: 2)
                    }
                }
                
                guard let filteredPixelBuffer = filter.render(pixelBuffer: finalPixelBuffer) else {
                    print("Unable to filter photo buffer")
                    return
                }
                finalPixelBuffer = filteredPixelBuffer
            }
            
            if let depthData = photo.depthData {
                let depthPixelBuffer = depthData.depthDataMap
                
                if !self.photoDepthConverter.isPrepared {
                    var depthFormatDescription: CMFormatDescription?
                    CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                                 imageBuffer: depthPixelBuffer,
                                                                 formatDescriptionOut: &depthFormatDescription)
                    
                    /*
                     outputRetainedBufferCountHint is the number of pixel buffers we expect to hold on to from the renderer.
                     This value informs the renderer how to size its buffer pool and how many pixel buffers to preallocate.
                     Allow 3 frames of latency to cover the dispatch_async call.
                     */
                    if let unwrappedDepthFormatDescription = depthFormatDescription {
                        self.photoDepthConverter.prepare(with: unwrappedDepthFormatDescription, outputRetainedBufferCountHint: 3)
                    }
                }
                
                guard let convertedDepthPixelBuffer = self.photoDepthConverter.render(pixelBuffer: depthPixelBuffer) else {
                    print("Unable to convert depth pixel buffer")
                    return
                }
                
                if !self.photoDepthMixer.isPrepared {
                    if let unwrappedPhotoFormatDescription = photoFormatDescription {
                        self.photoDepthMixer.prepare(with: unwrappedPhotoFormatDescription, outputRetainedBufferCountHint: 2)
                    }
                }
                
                // Combine image and depth map
                guard let mixedPixelBuffer = self.photoDepthMixer.mix(videoPixelBuffer: finalPixelBuffer,
                                                                      depthPixelBuffer: convertedDepthPixelBuffer)
                    else {
                        print("Unable to mix depth and photo buffers")
                        return
                }
                
                finalPixelBuffer = mixedPixelBuffer
            }
            
            let metadataAttachments: CFDictionary = photo.metadata as CFDictionary
            guard CameraViewController.jpegData(withPixelBuffer: finalPixelBuffer, attachments: metadataAttachments) != nil else {
                print("Unable to create JPEG photo")
                return
            }
        }
    }

}
