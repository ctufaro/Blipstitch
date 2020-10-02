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
    static func exportLayersToVideo(_ fileUrl:String, _ textValue: String, _ font:String, _ fontSize:CGFloat, _ position:CGPoint){
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
        
        // Watermark Effect
        let size = videoTrack.naturalSize
        let imglogo = UIImage(named: "trash")
        let imglayer = CALayer()
        imglayer.contents = imglogo?.cgImage
        imglayer.frame = CGRect(x: 5, y: 5, width: 100, height: 100)
        imglayer.opacity = 0.6
        
        // create text Layer
        let textLayer = CATextLayer()
        textLayer.string = textValue //
        textLayer.frame = CGRect(x: 0, y: -700, width: size.width, height: size.height)
        textLayer.alignmentMode = CATextLayerAlignmentMode.center
        textLayer.font = UIFont(name: font, size: fontSize) //
        textLayer.fontSize = fontSize*3 //
        textLayer.foregroundColor = UIColor.white.cgColor
        textLayer.shadowColor = UIColor.black.cgColor
        textLayer.shadowOffset = CGSize(width: 1.0, height: 0.0)
        textLayer.shadowOpacity = 0.2
        textLayer.shadowRadius = 1.0
        textLayer.backgroundColor = UIColor.clear.cgColor
        
        //rotation/position?
        let xnudge = UIScreen.screenSize.width
        let ynudge = UIScreen.screenSize.height/2
        textLayer.position = CGPoint(x: position.x+xnudge,y: position.y-ynudge)//
        //let degrees = self.fontRotation * -1
        //let radians = CGFloat(degrees * .pi / 180)
        //textLayer.transform = CATransform3DMakeRotation(CGFloat(degrees * .pi / 180), 0.0, 0.0, 1.0)
        //textLayer.transform = CATransform3DMakeTranslation(90, 50, 0)
        //rotation/position?
        
        let videolayer = CALayer()
        videolayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        
        let parentlayer = CALayer()
        parentlayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        parentlayer.addSublayer(videolayer)
        //parentlayer.addSublayer(imglayer)
        parentlayer.addSublayer(textLayer)
        
        
        let layercomposition = AVMutableVideoComposition()
        layercomposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        layercomposition.renderSize = size
        layercomposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videolayer, in: parentlayer)
        
        // instruction for watermark
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
                
                //self.myurl = movieDestinationUrl as URL
                
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
