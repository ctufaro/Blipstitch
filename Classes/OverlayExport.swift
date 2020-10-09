//
//  OverlayExport.swift
//  Blipstitch
//
//  Created by Christopher Tufaro on 10/1/20.
//  Copyright © 2020 Christopher Tufaro. All rights reserved.
//

import SwiftUI
import UIKit
import AVFoundation
import Photos

class OverlayExport {
    
    static func exportLayersToVideo(_ fileUrl:String, _ textView:UITextView){
        let fileURL = NSURL(fileURLWithPath: fileUrl)
        let composition = AVMutableComposition()
        let vidAsset = AVURLAsset(url: fileURL as URL, options: nil)
        
        // get video track
        let vtrack =  vidAsset.tracks(withMediaType: AVMediaType.video)
        let videoTrack: AVAssetTrack = vtrack[0]
        let vid_timerange = CMTimeRangeMake(start: CMTime.zero, duration: vidAsset.duration)
        
        let tr: CMTimeRange = CMTimeRange(start: CMTime.zero, duration: CMTime(seconds: 10.0, preferredTimescale: 600))
        composition.insertEmptyTimeRange(tr)
        
        let trackID:CMPersistentTrackID = CMPersistentTrackID(kCMPersistentTrackID_Invalid)
        
        if let compositionvideoTrack: AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: trackID) {
            
            do {
                try compositionvideoTrack.insertTimeRange(vid_timerange, of: videoTrack, at: CMTime.zero)
            } catch {
                print("error")
            }
            
            compositionvideoTrack.preferredTransform = videoTrack.preferredTransform
            
        } else {
            print("unable to add video track")
            return
        }
        
        let size = videoTrack.naturalSize
        
        let parentlayer = CALayer()
        parentlayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        
        let videolayer = CALayer()
        videolayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        
        // Convert UITextView to Image
        let renderer = UIGraphicsImageRenderer(size: textView.bounds.size)
        let image = renderer.image { ctx in
            textView.drawHierarchy(in: textView.bounds, afterScreenUpdates: true)
        }
        
        let imglayer = CALayer()
        let scaledAspect: CGFloat = image.size.width / image.size.height
        let scaledWidth = size.width
        let scaledHeight = scaledWidth / scaledAspect
        var relativePosition = parentlayer.convert(textView.frame.origin, from: textView.layer)
        let screenHeight = UIScreen.screenSize.height
        relativePosition.y = abs(size.height-((textView.frame.origin.y/screenHeight)*size.height)) - textView.frame.height*2 - 40
        imglayer.frame = CGRect(x: relativePosition.x, y: relativePosition.y, width: scaledWidth,height: scaledHeight)
        imglayer.contents = image.cgImage
        
        // Rotation
        let radians = atan2f(Float(textView.transform.b), Float(textView.transform.a))
        imglayer.transform = CATransform3DMakeRotation(CGFloat(radians), 0.0, 0.0, -1.0)
        

        
        
        // Adding videolayer and imglayer
        parentlayer.addSublayer(videolayer)
        parentlayer.addSublayer(imglayer)

        let layercomposition = AVMutableVideoComposition()
        layercomposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        layercomposition.renderSize = size
        layercomposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videolayer, in: parentlayer)
        
        // instruction for overlay
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: composition.duration)
        let videotrack = composition.tracks(withMediaType: AVMediaType.video)[0] as AVAssetTrack
        let layerinstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videotrack)
        instruction.layerInstructions = NSArray(object: layerinstruction) as [AnyObject] as! [AVVideoCompositionLayerInstruction]
        layercomposition.instructions = NSArray(object: instruction) as [AnyObject] as! [AVVideoCompositionInstructionProtocol]
        
        //  create new file to receive data
        let dirPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let docsDir = dirPaths[0] as NSString
        let movieFilePath = docsDir.appendingPathComponent("result.mov")
        let movieDestinationUrl = NSURL(fileURLWithPath: movieFilePath)
        
        // use AVAssetExportSession to export video
        let assetExport = AVAssetExportSession(asset: composition, presetName:AVAssetExportPresetHighestQuality)
        assetExport?.outputFileType = AVFileType.mov
        assetExport?.videoComposition = layercomposition
        
        // Check exist and remove old files
        do { // delete old video
            try FileManager.default.removeItem(at: movieDestinationUrl as URL)
        } catch { print("Error Removing Existing File: \(error.localizedDescription).") }
        
        do { // delete old video
            try FileManager.default.removeItem(at: fileURL as URL)
        } catch { print("Error Removing Existing File: \(error.localizedDescription).") }
        
        assetExport?.outputURL = movieDestinationUrl as URL
        assetExport?.exportAsynchronously(completionHandler: {
            switch assetExport!.status {
            case AVAssetExportSession.Status.failed:
                print("failed")
                print(assetExport?.error ?? "unknown error")
            case AVAssetExportSession.Status.cancelled:
                print("cancelled")
                print(assetExport?.error ?? "unknown error")
            default:
                print("Movie complete")
                
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: movieDestinationUrl as URL)
                }) { saved, error in
                    if saved {
                        print("Saved")
                    }
                }
                
            }
        })
    }
}
