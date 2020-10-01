//
//  PlayerUIView.swift
//  blipcam
//
//  Created by Christopher Tufaro on 9/7/20.
//  Copyright © 2020 Christopher Tufaro. All rights reserved.
//  https://stackoverflow.com/questions/32450356/image-text-overlay-in-video-swift

import SwiftUI
import UIKit
import AVFoundation
import Photos

struct PreviewView: View {
    @Binding var shots: Array<UIImage>!
    @ObservedObject var gestureHelper = GestureHelper()
    @State var duration: Double = 1
    @State var showSpeed: Bool = false
    @State var showLoading: Bool = false
    @State var showTextEdit: Bool = false
    @State var createText: Bool = false
    
    //Text Fields this should be a model
    @State var showingText = ""
    @State var font = "Arial-BoldMT"
    @State var fontSize: CGFloat = 40.0
    @State var fontRotation: Double = 0
    @ObservedObject var textArray: TextFields = TextFields()
    //Text Fields this should be a model
    
    @State private var numberOfRects = 0
    @State private var desiredHeight: [CGFloat] = [0, 0]
    
    var body: some View {
        ZStack{
            PlayerView(images: shots + shots.reversed(), duration: $duration).edgesIgnoringSafeArea(.all)
            TextView(textField: TextField(), gestureHelper:self.gestureHelper, fontRotation: self.$fontRotation)
            /*if showTextEdit {
                ForEach(textArray.textFields){ txt in
                    TextView(textField: txt, fontRotation: self.$fontRotation)
                }
            }*/
            VStack{
                if self.showSpeed {
                    Slider(value: $duration, in: 1...calcBounds(), step: 1)
                    HStack{
                        Text("Fast")
                            .fontWeight(.bold)
                            .foregroundColor(Color.white)
                            .padding(5)
                            .background(Color.black)
                            .cornerRadius(10)
                        Spacer()
                        Text("Slow")
                            .fontWeight(.bold)
                            .foregroundColor(Color.white)
                            .padding(5)
                            .background(Color.black)
                            .cornerRadius(10)
                    }
                }
                Spacer()
            }.padding(40)
            VStack{
                Spacer()
                HStack {
                    Spacer()
                    VStack(alignment:.center,spacing: 30) {
                        Group{
                            Button(action: {
                                self.getTextInfo()
                            }) {
                                VStack(spacing: 8) {
                                    Image(systemName: "info.circle")
                                        .font(.system(size: 30))
                                        .foregroundColor(.white)
                                    Text("Info")
                                        .foregroundColor(.white)
                                }
                            }
                            Button(action: {
                                self.showKeyboard()
                                self.gestureHelper.createText()
                                //self.createText.toggle()
                                /*self.showTextEdit = true
                                self.numberOfRects += 1
                                self.textArray.add(textValue: "", fontName: "Arial-BoldMT", fontSize: 40.0)*/
                            }) {
                                VStack(spacing: 8) {
                                    Image(systemName: "textformat")
                                        .font(.system(size: 30))
                                        .foregroundColor(.white)
                                    Text("Text")
                                        .foregroundColor(.white)
                                }
                            }
                            Button(action: {
                                withAnimation(.spring()){
                                    self.showSpeed.toggle()
                                }
                            }) {
                                VStack(spacing: 8) {
                                    Image("Rabbit").resizable().scaledToFit()
                                        .frame(width: UIScreen.screenWidth / 10, height: UIScreen.screenWidth / 10)
                                        .font(.title)
                                        .foregroundColor(.white)
                                    Text("Speed")
                                        .foregroundColor(.white)
                                }
                            }
                            Button(action: {
                                //self.createVideo()
                                self.createVideoFromLayers()
                            }) {
                                VStack(spacing: 8) {
                                    Image("Send")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: UIScreen.screenWidth / 10, height: UIScreen.screenWidth / 10)
                                        .font(.title)
                                        .foregroundColor(.white)
                                    Text("Post").foregroundColor(.white)
                                }
                            }.opacity(self.showLoading ? 0 : 1)
                        }.padding(.trailing,UIScreen.screenWidth / 50)
                    }.padding(.bottom, 55).padding(.trailing,3)
                }
            }
            LoadingView(isShowing:$showLoading, showingText: $showingText)
            
        }.onAppear(){
            self.duration = Double(self.shots.count)/8
        }.navigationBarItems(trailing:
            Button(action: {
                self.hideKeyboard()
            }) {
                Text("Done")
                    .foregroundColor(.white)
                    .font(.system(size: 22))
            }
        )
    }
    
    func getTextInfo(){
        for txt in self.textArray.textFields {
            print("Text Layer - value:\(txt.textValue) font:\(txt.fontName) size:\(txt.fontSize)")
        }
        //rotation
        //location
    }
    
    func createVideoFromLayers(){
        print("Process Video Starting")
        let serialQueue = DispatchQueue(label: "mySerialQueue")
        serialQueue.async {
            var newDuration = Int32(self.duration)
            if newDuration == 0 { newDuration = 1 }
            var newFps = Int32(self.shots.count)/newDuration
            if newFps == 0 { newFps = 1 }
            ImageToVideo.create(images: self.shots+self.shots.reversed(), fps: newFps*2) { fileUrl in
                
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
                textLayer.string = self.showingText //
                textLayer.frame = CGRect(x: 0, y: -700, width: size.width, height: size.height)
                textLayer.alignmentMode = CATextLayerAlignmentMode.center
                textLayer.font = UIFont(name: self.font, size: self.fontSize) //
                textLayer.fontSize = self.fontSize*3 //
                textLayer.foregroundColor = UIColor.white.cgColor
                textLayer.shadowColor = UIColor.black.cgColor
                textLayer.shadowOffset = CGSize(width: 1.0, height: 0.0)
                textLayer.shadowOpacity = 0.2
                textLayer.shadowRadius = 1.0
                textLayer.backgroundColor = UIColor.clear.cgColor
                
                //rotation/position?
                //let degrees = self.fontRotation * -1
                //let radians = CGFloat(degrees * .pi / 180)
                //textLayer.transform = CATransform3DMakeRotation(CGFloat(degrees * .pi / 180), 0.0, 0.0, 1.0)
                //textLayer.transform = CATransform3DMakeTranslation(90, 50, 0)

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

                // Check exist and remove old file
                do { // delete old video
                    try FileManager.default.removeItem(at: movieDestinationUrl as URL)
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
    }
    
    func createVideo(){
        self.showLoading = true
        print("Process Video Starting")
        let serialQueue = DispatchQueue(label: "mySerialQueue")
        serialQueue.async {
            var newDuration = Int32(self.duration)
            if newDuration == 0 { newDuration = 1 }
            var newFps = Int32(self.shots.count)/newDuration
            if newFps == 0 { newFps = 1 }
            ImageToVideo.create(images: self.shots+self.shots.reversed(), fps: newFps*2) { fileUrl in
                let imageUrl = ImageToVideo.savePreviewImage(image: self.shots[0])
                RestAPI.UploadVideo(fileURL: URL(fileURLWithPath: fileUrl), imageUrl: imageUrl!,completion:{
                    print("Process Video Completed")
                    self.showLoading = false
                    self.showingText = ""
                }, working:{ percent in
                    self.showingText = "Uploading: \(Int(percent*100))%"
                })
            }
        }
    }
    
    func calcBounds() -> Double{
        if Double(shots.count/4) < 5 {
            return 4.0
        } else {
            return Double(shots.count/4)
        }
    }
    
    struct PreviewView_Previews: PreviewProvider {
        static var images: Array<UIImage>! = [
            UIImage(named: "Us1")!,
            UIImage(named: "Us2")!,
            UIImage(named: "Us3")!,
            UIImage(named: "Us4")!,
            UIImage(named: "Us5")!
        ]
        @State static var shots:Array<UIImage>! = images + images.reversed()
        
        static var previews: some View {
            PreviewView(shots:$shots)
        }
    }
}

///EXTENSIONS
#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    func showKeyboard(){
        UIApplication.shared.sendAction(#selector(UIResponder.becomeFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif

