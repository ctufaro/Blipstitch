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
            videoWriterInput.transform = videoWriterInput!.transform.rotated(by: CGFloat.pi / 2)
            
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
        /*catch let error {
            debugPrint(error.localizedDescription)
        }*/
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
                guard let selectedAudio = self?.cameraHelper.selectedAudio else { return }
                guard let videoURL = self?.videoWriter.outputURL else { return }
                guard let audioURL = Bundle.main.url(forResource: selectedAudio, withExtension: "mp3") else { return }
                
                //let videoAsset = AVURLAsset(url: url)
                self!.makeMovie(videoURL: videoURL, audioURL: audioURL)
            }
        }
    }
    
    func makeMovie(videoURL:URL, audioURL:URL){
        // video //
        let videoAsset = AVURLAsset(url: videoURL)
        let videoTracks = videoAsset.tracks(withMediaType: .video)
        let videoTrack = videoTracks[0]
        let videoTimeRange = CMTimeRangeMake(start: CMTime.zero, duration: videoAsset.duration)
        let composition = AVMutableComposition()
        let compositionVideoTrack: AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: CMPersistentTrackID())!
        try! compositionVideoTrack.insertTimeRange(videoTimeRange, of: videoTrack, at: CMTime.zero)
        compositionVideoTrack.preferredTransform = videoTrack.preferredTransform

        // music //
        let audioAsset = AVURLAsset(url: audioURL)
        let audioTracks = audioAsset.tracks(withMediaType: .audio)
        let audioTrack = audioTracks[0]
        let audioCompositionTrack: AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!
        let newTimeRange = (audioTrack.timeRange.duration > videoTrack.timeRange.duration) ? videoTrack.timeRange : audioTrack.timeRange
        try! audioCompositionTrack.insertTimeRange(newTimeRange, of: audioTrack, at: CMTime.zero)
        
        // microphone //
        //let microphoneTrack: AVAssetTrack = videoAsset.tracks(withMediaType: AVMediaType.audio)[0]
        //try! audioCompositionTrack.insertTimeRange(newTimeRange, of: microphoneTrack, at: CMTime.zero)

        // video layer //
        let videoLayer = CALayer()
        videoLayer.isHidden = false
        videoLayer.opacity = 1.0
        videoLayer.frame = CGRect(x: 0, y: 0, width: videoSize.width, height: videoSize.height)


        // parent layer //
        let parentLayer = CALayer()
        parentLayer.isHidden = false
        parentLayer.opacity = 1.0
        parentLayer.frame = CGRect(x: 0, y: 0, width: videoSize.width, height: videoSize.height)
        parentLayer.addSublayer(videoLayer)


        // composition instructions //
        let layerComposition = AVMutableVideoComposition()
        layerComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        layerComposition.renderSize = CGSize(width: videoSize.width, height: videoSize.height)
        layerComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: composition.duration)
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        layerInstruction.setTransform(videoTrack.preferredTransform, at: CMTime.zero)
        instruction.layerInstructions = [layerInstruction] as [AVVideoCompositionLayerInstruction]
        layerComposition.instructions = [instruction] as [AVVideoCompositionInstructionProtocol]


        let assetExport = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)
        exportAsset(exporter: assetExport!)
    }
    
    func exportAsset(exporter: AVAssetExportSession) {
        let exportURL = videoFileLocation()
        exporter.outputURL = exportURL
        exporter.outputFileType = AVFileType.mov
        exporter.exportAsynchronously(completionHandler: {
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: exportURL)
            }) { saved, error in
                if saved {
                    print("Saved Movie")
                }
            }
        })
    }
    
    func pauseRecording() {
        isRecording = false
        print("Video Recording Paused")
    }
    
    func resumeRecording() {
        isRecording = true
        print("Video Recording Resumed")
    }
    
    func toggleRecord() {
        if !isRecording && sessionAtSourceTime == nil{
            startRecording()
        } else if !isRecording && sessionAtSourceTime != nil{
            resumeRecording()
        } else if isRecording{
            pauseRecording()
        }
    }

    func stopRecord(){
        self.stopRecording()
    }
}
