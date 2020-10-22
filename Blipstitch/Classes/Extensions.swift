//
//  Extensions.swift
//  Blipstitch
//
//  Created by Christopher Tufaro on 9/25/20.
//  Copyright © 2020 Christopher Tufaro. All rights reserved.
//

import UIKit

extension UIView {
    
    // Using a function since `var image` might conflict with an existing variable
    // (like on `UIImageView`)
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
    
    
    func toImage() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.isOpaque, 0.0)
        self.drawHierarchy(in: self.bounds, afterScreenUpdates: false)
        let snapshotImageFromMyView = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return snapshotImageFromMyView!
    }
    
 
    
    @objc func toImageView() -> UIImageView {
        let tempImageView = UIImageView()
        tempImageView.image = toImage()
        tempImageView.frame = frame
        tempImageView.contentMode = .scaleAspectFit
        return tempImageView
    }
    
   
}

import AVFoundation

extension AVAsset {

    //func videoOrientation() -> (orientation: UIInterfaceOrientation, device: AVCaptureDevicePosition) {
    //  var orientation: UIInterfaceOrientation = .Unknown

    func videoOrientation() -> (orientation: AVCaptureVideoOrientation, device: AVCaptureDevice.Position, isPortrait: Bool) {
        var orientation: AVCaptureVideoOrientation = .portrait
        var device: AVCaptureDevice.Position = .unspecified
        var isPortrait: Bool = true
        
        let tracks :[AVAssetTrack] = self.tracks(withMediaType: AVMediaType.video)
        if let videoTrack = tracks.first {
            
            let t = videoTrack.preferredTransform
            
            if (t.a == 0 && t.b == 1.0 && t.d == 0) {
                orientation = .portrait
                
                if t.c == 1.0 {
                    device = .front
                } else if t.c == -1.0 {
                    device = .back
                }
            }
            else if (t.a == 0 && t.b == -1.0 && t.d == 0) {
                orientation = .portraitUpsideDown
                
                if t.c == -1.0 {
                    device = .front
                } else if t.c == 1.0 {
                    device = .back
                }
            }
            else if (t.a == 1.0 && t.b == 0 && t.c == 0) {
                orientation = .landscapeRight
                isPortrait = false
                
                if t.d == -1.0 {
                    device = .front
                } else if t.d == 1.0 {
                    device = .back
                }
            }
            else if (t.a == -1.0 && t.b == 0 && t.c == 0) {
                orientation = .landscapeLeft
                isPortrait = false

                if t.d == 1.0 {
                    device = .front
                } else if t.d == -1.0 {
                    device = .back
                }
            }
        }
        
        return (orientation, device, isPortrait)
    }
}


