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
    @State var createText: Bool = false
    
    //Text Fields this should be a model
    @State var showingText = ""
    @State var font = "Arial-BoldMT"
    @State var fontSize: CGFloat = 40.0
    @State var fontRotation: Double = 0
    //Text Fields this should be a model
    
    @State private var desiredHeight: [CGFloat] = [0, 0]
    
    var body: some View {
        ZStack{
            PlayerView(images: shots + shots.reversed(), duration: $duration).edgesIgnoringSafeArea(.all)
            GestureControlView(gestureHelper:self.gestureHelper).edgesIgnoringSafeArea(.all)
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
        self.gestureHelper.printTextViewValues()
        print("Dimensions - width:\(UIScreen.screenSize.width) height:\(UIScreen.screenSize.height)")
    }
    
    func createVideoFromLayers(){
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
                OverlayExport.exportLayersToVideo(fileUrl, self.gestureHelper.textViewArray, completion:{ destination in
                    RestAPI.UploadVideo(fileURL: destination as URL, imageUrl: imageUrl!,completion:{
                        print("Process Video Completed")
                        self.showLoading = false
                        self.showingText = ""
                    }, working:{ percent in
                        self.showingText = "Uploading: \(Int(percent*100))%"
                    })
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

