//
//  MetalHelper.swift
//  blipcam
//
//  Created by Christopher Tufaro on 9/2/20.
//  Copyright © 2020 Christopher Tufaro. All rights reserved.
//

import Foundation
import UIKit

class CameraHelper : ObservableObject{
    var delegate:CameraDelegate?
    var shots: Array<UIImage>!
    var takePicture:Bool
    var recordVideo:Int
    var capturedImage:UIImage?
    var compressionQuality:CGFloat = 0.7
    @Published var flashText:Bool = false
    @Published var filterName : String = ""
    @Published var count:Int
    @Published var selectedAudio : String = ""
    @Published var micOn:Bool = false
    
    init(){
        self.shots = []
        self.count = 0
        self.takePicture = false
        self.recordVideo = -1
    }
    
    func changeCamera(){
        delegate!.changeCamera()
    }
    
    func captureShot(){
        delegate!.captureShot()
    }
    
    func startRecord(){
        delegate!.startRecord()
    }
    
    func pauseRecord(){
        delegate!.pauseRecord()
    }
    
    func stopRecord(){
        delegate!.stopRecord()
    }
    
    func swipedFilter(filterName:String){
        self.filterName = filterName
        self.flashText = true
        print(self.filterName)
    }
    
    func saveImageToArray(uiImage:UIImage){
        self.count += 1
        self.capturedImage = uiImage
        DispatchQueue.global(qos: .background).async {
            let newImage = uiImage.jpegData(compressionQuality: self.compressionQuality)! as Data
            self.shots.append(UIImage(data: newImage)!)
        }
    }
    
    func clearImages(){
        self.shots = []
        self.count = 0
        self.capturedImage = nil
    }
}

protocol CameraDelegate {
    func changeCamera()
    func captureShot()
    func startRecord()
    func pauseRecord()
    func stopRecord()
}

