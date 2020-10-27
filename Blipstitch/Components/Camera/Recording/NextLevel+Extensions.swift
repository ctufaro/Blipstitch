//
//  NextLevel+Metadata.swift
//  Blipstitch
//
//  Created by Christopher Tufaro on 10/27/20.
//  Copyright © 2020 Christopher Tufaro. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation
import CoreMedia
import ImageIO

fileprivate let NextLevelMetadataTitle = "NextLevel"
fileprivate let NextLevelMetadataArtist = "http://nextlevel.engineering/"

extension CMSampleBuffer {

    public func metadata() -> [String : Any]? {
        
        if let cfmetadata = CMCopyDictionaryOfAttachments(allocator: kCFAllocatorDefault, target: self, attachmentMode: kCMAttachmentMode_ShouldPropagate) {
            if let metadata = cfmetadata as? [String : Any] {
                return metadata
            }
        }
        return nil
        
    }

    public func append(metadataAdditions: [String: Any]) {
        
        // append tiff metadata to buffer for proagation
        if let tiffDict: CFDictionary = CMCopyDictionaryOfAttachments(allocator: kCFAllocatorDefault, target: kCGImagePropertyTIFFDictionary, attachmentMode: kCMAttachmentMode_ShouldPropagate) {
            let tiffNSDict = tiffDict as NSDictionary
            var metaDict: [String: Any] = [:]
            for (key, value) in metadataAdditions {
                metaDict.updateValue(value as AnyObject, forKey: key)
            }
            for (key, value) in tiffNSDict {
                if let keyString = key as? String {
                    metaDict.updateValue(value as AnyObject, forKey: keyString)
                }
            }
            CMSetAttachment(self, key: kCGImagePropertyTIFFDictionary, value: metaDict as CFTypeRef?, attachmentMode: kCMAttachmentMode_ShouldPropagate)
        } else {
            CMSetAttachment(self, key: kCGImagePropertyTIFFDictionary, value: metadataAdditions as CFTypeRef?, attachmentMode: kCMAttachmentMode_ShouldPropagate)
        }
    }
    
    public class func createSampleBuffer(fromSampleBuffer sampleBuffer: CMSampleBuffer, withTimeOffset timeOffset: CMTime, duration: CMTime?) -> CMSampleBuffer? {
        var itemCount: CMItemCount = 0
        var status = CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, entryCount: 0, arrayToFill: nil, entriesNeededOut: &itemCount)
        if status != 0 {
            return nil
        }
        
        var timingInfo = [CMSampleTimingInfo](repeating: CMSampleTimingInfo(duration: CMTimeMake(value: 0, timescale: 0), presentationTimeStamp: CMTimeMake(value: 0, timescale: 0), decodeTimeStamp: CMTimeMake(value: 0, timescale: 0)), count: itemCount)
        status = CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, entryCount: itemCount, arrayToFill: &timingInfo, entriesNeededOut: &itemCount);
        if status != 0 {
            return nil
        }
        
        if let dur = duration {
            for i in 0 ..< itemCount {
                timingInfo[i].decodeTimeStamp = CMTimeSubtract(timingInfo[i].decodeTimeStamp, timeOffset);
                timingInfo[i].presentationTimeStamp = CMTimeSubtract(timingInfo[i].presentationTimeStamp, timeOffset);
                timingInfo[i].duration = dur
            }
        } else {
            for i in 0 ..< itemCount {
                timingInfo[i].decodeTimeStamp = CMTimeSubtract(timingInfo[i].decodeTimeStamp, timeOffset);
                timingInfo[i].presentationTimeStamp = CMTimeSubtract(timingInfo[i].presentationTimeStamp, timeOffset);
            }
        }
        
        var sampleBufferOffset: CMSampleBuffer? = nil
        CMSampleBufferCreateCopyWithNewTiming(allocator: kCFAllocatorDefault, sampleBuffer: sampleBuffer, sampleTimingEntryCount: itemCount, sampleTimingArray: &timingInfo, sampleBufferOut: &sampleBufferOffset);
        
        if let output = sampleBufferOffset {
            return output
        } else {
            return nil
        }
    }
    
}

extension NextLevelSession {
    
    internal class var tiffMetadata: [String: Any] {
        return [ kCGImagePropertyTIFFSoftware as String : NextLevelMetadataTitle,
                 kCGImagePropertyTIFFArtist as String : NextLevelMetadataArtist,
                 kCGImagePropertyTIFFDateTime as String : Date().iso8601() ]
    }
    
    internal class var assetWriterMetadata: [AVMutableMetadataItem] {
        let currentDevice = UIDevice.current
        
        let modelItem = AVMutableMetadataItem()
        modelItem.keySpace = AVMetadataKeySpace.common
        modelItem.key = AVMetadataKey.commonKeyModel as (NSCopying & NSObjectProtocol)
        modelItem.value = currentDevice.localizedModel as (NSCopying & NSObjectProtocol)
        
        let softwareItem = AVMutableMetadataItem()
        softwareItem.keySpace = AVMetadataKeySpace.common
        softwareItem.key = AVMetadataKey.commonKeySoftware as (NSCopying & NSObjectProtocol)
        softwareItem.value = NextLevelMetadataTitle as (NSCopying & NSObjectProtocol)
        
        let artistItem = AVMutableMetadataItem()
        artistItem.keySpace = AVMetadataKeySpace.common
        artistItem.key = AVMetadataKey.commonKeyArtist as (NSCopying & NSObjectProtocol)
        artistItem.value = NextLevelMetadataArtist as (NSCopying & NSObjectProtocol)
        
        let creationDateItem = AVMutableMetadataItem()
        creationDateItem.keySpace = .common
        
        if #available(iOS 13.0, *) {
            creationDateItem.key = AVMetadataKey.commonKeyCreationDate as NSString
            creationDateItem.value = Date() as NSDate
        } else {
            creationDateItem.key = AVMetadataKey.commonKeyCreationDate as (NSCopying & NSObjectProtocol)
            creationDateItem.value = Date().iso8601() as (NSCopying & NSObjectProtocol)
        }
        
        return [modelItem, softwareItem, artistItem, creationDateItem]
    }

}

extension Date {
    
    static let dateFormatter: DateFormatter = iso8601DateFormatter()
    fileprivate static func iso8601DateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        return formatter
    }
    
    // http://nshipster.com/nsformatter/
    // http://unicode.org/reports/tr35/tr35-6.html#Date_Format_Patterns
    public func iso8601() -> String {
        return Date.iso8601DateFormatter().string(from: self)
    }
    
}
