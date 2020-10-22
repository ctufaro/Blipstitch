//
//  CameraViewController+KVO.swift
//  Blipstitch
//
//  Created by Christopher Tufaro on 10/18/20.
//  Copyright © 2020 Christopher Tufaro. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

extension CameraViewController{
    // MARK: - KVO and Notifications (NOT REALLY USED)
    func addObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(willEnterForground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(thermalStateChanged),
                                               name: ProcessInfo.thermalStateDidChangeNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sessionRuntimeError),
                                               name: NSNotification.Name.AVCaptureSessionRuntimeError,
                                               object: session)
        
        session.addObserver(self, forKeyPath: "running", options: NSKeyValueObservingOptions.new, context: &sessionRunningContext)
        
        // A session can run only when the app is full screen. It will be interrupted in a multi-app layout.
        // Add observers to handle these session interruptions and inform the user.
        // See AVCaptureSessionWasInterruptedNotification for other interruption reasons.
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sessionWasInterrupted),
                                               name: NSNotification.Name.AVCaptureSessionWasInterrupted,
                                               object: session)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(subjectAreaDidChange),
                                               name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange,
                                               object: videoInput.device)
    }
    
    func removeObservers() {
        NotificationCenter.default.removeObserver(self)
        session.removeObserver(self, forKeyPath: "running", context: &sessionRunningContext)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if context == &sessionRunningContext {
            let newValue = change?[.newKey] as AnyObject?
            guard (newValue?.boolValue) != nil else { return }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    @objc
    func sessionWasInterrupted(notification: NSNotification) {
        // In iOS 9 and later, the userInfo dictionary contains information on why the session was interrupted.
        if let userInfoValue = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as AnyObject?,
            let reasonIntegerValue = userInfoValue.integerValue,
            let reason = AVCaptureSession.InterruptionReason(rawValue: reasonIntegerValue) {
            print("Capture session was interrupted with reason \(reason)")
        }
    }
    
    @objc
    func sessionRuntimeError(notification: NSNotification) {
        guard let errorValue = notification.userInfo?[AVCaptureSessionErrorKey] as? NSError else {
            return
        }
        
        let error = AVError(_nsError: errorValue)
        print("Capture session runtime error: \(error)")
        
        /*
         Automatically try to restart the session running if media services were
         reset and the last start running succeeded. Otherwise, enable the user
         to try to resume the session running.
         */
        if error.code == .mediaServicesWereReset {
            sessionQueue.async {
                if self.isSessionRunning {
                    self.session.startRunning()
                    self.isSessionRunning = self.session.isRunning
                } else {
                    DispatchQueue.main.async {
                        //self.resumeButton.isHidden = false
                    }
                }
            }
        } else {
            //resumeButton.isHidden = false
        }
    }
    
}
