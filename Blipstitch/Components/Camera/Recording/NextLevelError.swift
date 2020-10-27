//
//  NextLevelError.swift
//  Blipstitch
//
//  Created by Christopher Tufaro on 10/27/20.
//  Copyright © 2020 Christopher Tufaro. All rights reserved.
//

import Foundation

public enum NextLevelError: Error, CustomStringConvertible {
    case unknown
    case started
    case deviceNotAvailable
    case authorization
    case fileExists
    case nothingRecorded
    case notReadyToRecord
    
    public var description: String {
        get {
            switch self {
            case .unknown:
                return "Unknown"
            case .started:
                return "NextLevel already started"
            case .fileExists:
                return "File exists"
            case .authorization:
                return "Authorization has not been requested"
            case .deviceNotAvailable:
                return "Device Not Available"
            case .nothingRecorded:
                return "Nothing recorded"
            case .notReadyToRecord:
                return "NextLevel is not ready to record"
            }
        }
    }
}
