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

// MARK: - capture

extension CameraViewController {

    internal func startCapture() {
        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseInOut, animations: {
            self.recordButton?.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        }) { (completed: Bool) in
            self.recording = true
            if let _ = self.recordingSession {
                self.beginRecordingNewClipIfNecessary()
            }
        }
    }
    
    internal func pauseCapture() {
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: {
            self.recordButton?.transform = .identity
        }) { (completed: Bool) in
            self.recording = false
            self.sessionAtSourceTime = nil
            if let session = self.recordingSession {
                if session.currentClipHasStarted {
                    session.endClip(completionHandler: { (sessionClip: NextLevelClip?, error: Error?) in
                    })
                }
            }
        }
    }
    
    internal func endCapture() {
        if let session = self.recordingSession {
            
            /// Add MP3 To Video
            session.audioOverlay = self.cameraHelper.selectedAudio
            
            if session.clips.count > 1 {
                session.mergeClips(usingPreset: AVAssetExportPresetHighestQuality, completionHandler: { (url: URL?, error: Error?) in
                    if let url = url {
                        self.saveVideo(withURL: url)
                    } else if let _ = error {
                        print("failed to merge clips at the end of capture \(String(describing: error))")
                    }
                })
            }
            else if let lastClipUrl = session.lastClipUrl {
                self.saveVideo(withURL: lastClipUrl)
            }
            else if session.currentClipHasStarted {
                session.endClip(completionHandler: { (clip, error) in
                    if error == nil {
                        self.saveVideo(withURL: (clip?.url)!)
                    } else {
                        print("Error saving video: \(error?.localizedDescription ?? "")")
                    }
                })
            }
            else {
                // prompt that the video has been saved
                let alertController = UIAlertController(title: "Video Capture", message: "Not enough video captured!", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alertController.addAction(okAction)
                self.present(alertController, animated: true, completion: nil)
            }
            
            session.removeAllClips()
        
        }
        
    }
    
    internal func beginRecordingNewClipIfNecessary() {
        if let session = self.recordingSession,
            session.isReady == false {
            session.beginClip()
        }
    }
    
    internal func authorizePhotoLibaryIfNecessary() {
        let authorizationStatus = PHPhotoLibrary.authorizationStatus()
        switch authorizationStatus {
        case .restricted:
            fallthrough
        case .denied:
            let alertController = UIAlertController(title: "Oh no!", message: "Access denied.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
            break
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({ (status) in
                if status == .authorized {
                    
                } else {
                    
                }
            })
            break
        case .authorized:
            break
        case .limited:
            break
        @unknown default:
            fatalError("unknown authorization type")
        }
    }
    
    // Camera Helper Methods
    func startRecord() {
        self.startCapture()
    }
    
    func pauseRecord() {
        self.pauseCapture()
    }
}

// MARK: - media utilities

extension CameraViewController {
    
    internal func saveVideo(withURL url: URL) {
        PHPhotoLibrary.shared().performChanges({
                                                let albumAssetCollection = self.albumAssetCollection(withTitle: self.albumTitle)
            if albumAssetCollection == nil {
                let changeRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: self.albumTitle)
                let _ = changeRequest.placeholderForCreatedAssetCollection
            }}, completionHandler: { (success1: Bool, error1: Error?) in
                if let albumAssetCollection = self.albumAssetCollection(withTitle: self.albumTitle) {
                    PHPhotoLibrary.shared().performChanges({
                        if let assetChangeRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url) {
                            let assetCollectionChangeRequest = PHAssetCollectionChangeRequest(for: albumAssetCollection)
                            let enumeration: NSArray = [assetChangeRequest.placeholderForCreatedAsset!]
                            assetCollectionChangeRequest?.addAssets(enumeration)
                        }
                    }, completionHandler: { (success2: Bool, error2: Error?) in
                    if success2 == true {
                        print("Video Saved")
                    } else {
                        print("Something failed! \(String(describing: error2))")
                    }
                })
            }
        })
    }
    
    internal func savePhoto(photoImage: UIImage) {
        let NextLevelAlbumTitle = self.albumTitle
        
        PHPhotoLibrary.shared().performChanges({
            
            let albumAssetCollection = self.albumAssetCollection(withTitle: self.albumTitle)
            if albumAssetCollection == nil {
                let changeRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: NextLevelAlbumTitle)
                let _ = changeRequest.placeholderForCreatedAssetCollection
            }
            
        }, completionHandler: { (success1: Bool, error1: Error?) in
            
            if success1 == true {
                if let albumAssetCollection = self.albumAssetCollection(withTitle: self.albumTitle) {
                    PHPhotoLibrary.shared().performChanges({
                        let assetChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: photoImage)
                        let assetCollectionChangeRequest = PHAssetCollectionChangeRequest(for: albumAssetCollection)
                        let enumeration: NSArray = [assetChangeRequest.placeholderForCreatedAsset!]
                        assetCollectionChangeRequest?.addAssets(enumeration)
                    }, completionHandler: { (success2: Bool, error2: Error?) in
                        if success2 == true {
                            let alertController = UIAlertController(title: "Photo Saved!", message: "Saved to the camera roll.", preferredStyle: .alert)
                            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                            alertController.addAction(okAction)
                            self.present(alertController, animated: true, completion: nil)
                        }
                    })
                }
            } else if let _ = error1 {
                print("failure capturing photo from video frame \(String(describing: error1))")
            }
            
        })
    }
    
    internal func albumAssetCollection(withTitle title: String) -> PHAssetCollection? {
        let predicate = NSPredicate(format: "localizedTitle = %@", title)
        let options = PHFetchOptions()
        options.predicate = predicate
        let result = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: options)
        if result.count > 0 {
            return result.firstObject
        }
        return nil
    }
}

extension CameraViewController {

    func toggleRecord() {
        //toggleRecord
    }
    
    func stopRecord() {
        endCapture()
    }
}
