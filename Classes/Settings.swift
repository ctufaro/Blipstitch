//
//  Settings.swift
//  Blipstitch
//
//  Created by Christopher Tufaro on 9/25/20.
//  Copyright © 2020 Christopher Tufaro. All rights reserved.
//

import Foundation
import SwiftUI

class Settings{
    
    static func clearDirectory(directory:FileManager.SearchPathDirectory) -> Bool{
        let fileManager = FileManager.default
        let documentsUrl =  FileManager.default.urls(for: directory, in: .userDomainMask).first! as NSURL
        let documentsPath = documentsUrl.path

        do {
            if let documentPath = documentsPath
            {
                let fileNames = try fileManager.contentsOfDirectory(atPath: "\(documentPath)")
                print("all files in folder: \(fileNames)")
                for fileName in fileNames {

                    if (fileName.hasSuffix(".mp4") || fileName.hasSuffix(".mov") || fileName.hasSuffix(".jpg"))
                    {
                        let filePathName = "\(documentPath)/\(fileName)"
                        try fileManager.removeItem(atPath: filePathName)
                    }
                }

                let files = try fileManager.contentsOfDirectory(atPath: "\(documentPath)")
                print("all files in folder after deletion: \(files)")
            }

        } catch {
            print("Could not clear temp folder: \(error)")
        }
        return true
    }

    static func deleteAllPosts() -> Bool{
        return true
    }
}
