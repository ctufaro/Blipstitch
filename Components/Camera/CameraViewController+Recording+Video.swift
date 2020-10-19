//
//  CameraViewController+Session.swift
//  Blipstitch
//
//  Created by Christopher Tufaro on 10/18/20.
//  Copyright © 2020 Christopher Tufaro. All rights reserved.
//

import UIKit
import AVFoundation
import CoreVideo
import Photos
import MobileCoreServices
import MetalKit

extension CameraViewController{
    
    // MARK: - Recording Functions
    func setupWriter() {
        do {
            let url = videoFileLocation()
            videoWriter = try? AVAssetWriter(url: url, fileType: AVFileType.mp4)
            
            //Add video input
            videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: videoSize.width,
                AVVideoHeightKey: videoSize.height,
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: 6000000,
                    AVVideoProfileLevelKey: AVVideoProfileLevelH264High40,
                    AVVideoExpectedSourceFrameRateKey: 60,
                    AVVideoAverageNonDroppableFrameRateKey: 30,
                ],
            ])
            
            videoWriterInputPixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput, sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                kCVPixelBufferWidthKey as String: videoSize.width,
                kCVPixelBufferHeightKey as String: videoSize.height,
                kCVPixelFormatOpenGLESCompatibility as String: true,
            ])
            
            videoWriterInput.expectsMediaDataInRealTime = true //Make sure we are exporting data at realtime
            videoWriterInput.transform = .identity
            
            if videoWriter.canAdd(videoWriterInput) {
                videoWriter.add(videoWriterInput)
            }
            
            //Add audio input
            audioWriterInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVNumberOfChannelsKey: 1,
                AVSampleRateKey: 44100,
                AVEncoderBitRateKey: 64000,
            ])
            audioWriterInput.expectsMediaDataInRealTime = true
            if videoWriter.canAdd(audioWriterInput) {
                videoWriter.add(audioWriterInput)
                print("Audio Added To AVAssetWriter")
            } else {
                print("Audio NOT Added to AVAssetWriter")
            }
            
            //videoWriter.startWriting() //Means ready to write down the file
        }
        catch let error {
            debugPrint(error.localizedDescription)
        }
    }
    
    func videoFileLocation() -> URL {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let videoOutputUrl = URL(fileURLWithPath: documentsPath.appendingPathComponent("\(UUID()).mov"))
        do {
            if FileManager.default.fileExists(atPath: videoOutputUrl.path) {
                try FileManager.default.removeItem(at: videoOutputUrl)
                print("file removed")
            }
        } catch {
            print(error)
        }
        
        return videoOutputUrl
    }
    
    func canWrite() -> Bool {
        return isRecording
            && videoWriter != nil
            && videoWriter.status == .writing
    }
    
    func startRecording() {
        print("Video Recording Started")
        guard !isRecording else { return }
        isRecording = true
        sessionAtSourceTime = nil
        videoWriter.startWriting()
    }
    
    func stopRecording() {
        guard isRecording else { return }
        isRecording = false
        writingQueue.sync { [weak self] in
            videoWriter.finishWriting { [weak self] in
                print("Video Recording Stopped")
                self?.sessionAtSourceTime = nil
                guard let url = self?.videoWriter.outputURL else { return }
                //let videoAsset = AVURLAsset(url: url)
                //var info = videoAsset.videoOrientation()
                
                /*let textViewArrayDummy:[UITextView] = []
                 OverlayExport.exportLayersToVideo(url.path, textViewArrayDummy, completion:{ destination in
                 print("Process Video Completed???")
                 })*/
                
                //Do whatever you want with your asset here
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                }) { saved, error in
                    if saved {
                        print("Video Saved To Camera Roll")
                    }
                }
                print("exported?")
            }
        }
    }
    
    func pauseRecording() {
        isRecording = false
    }
    
    func resumeRecording() {
        isRecording = true
    }
    
    func toggleRecord() {
        if !isRecording{
            startRecording()
        } else if isRecording{
            stopRecording()
        }
    }
}
