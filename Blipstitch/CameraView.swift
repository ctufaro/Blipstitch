//
//  TemplateView.swift
//  blipcam
//
//  Created by Christopher Tufaro on 9/9/20.
//  Copyright © 2020 Christopher Tufaro. All rights reserved.
//
import SwiftUI
struct CameraView: View {
    @State var top = 0
    @ObservedObject var cameraHelper = CameraHelper()
    @ObservedObject var viewRouter:ViewRouter
    @State var selection: Int? = nil
    @State var show = false
    @State var showMusicModal = false
    @State var showCountdown = false
    @State var musicPlayer:MusicPlayer = MusicPlayer()
    var body: some View {
        NavigationView {
            ZStack {
                AVCamView(cameraHelper:cameraHelper)
                TextFlashView(flash: $cameraHelper.flashText, textToFlash: self.cameraHelper.filterName)
                CountdownView(show:$showCountdown, recordVideoMethod:self.cameraHelper.startRecord, playMusicMethod:self.playMethod)
                VStack{
                    Spacer()
                    HStack{
                        if self.cameraHelper.capturedImage != nil {
                            NavigationLink(destination: ImagePreviewView(shots:$cameraHelper.shots), tag: 1, selection: $selection) {
                                Button(action: {
                                    self.selection = 1
                                }) {
                                    ZStack{
                                        Image(uiImage: self.cameraHelper.capturedImage!)
                                            .renderingMode(.original)
                                            .resizable()
                                            .aspectRatio(self.cameraHelper.capturedImage!.size, contentMode: .fit)
                                            .frame(height:UIScreen.screenHeight/4)
                                            .cornerRadius(10)
                                            .overlay(RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.white, lineWidth: 2))
                                            .clipped()
                                        Text(String(self.cameraHelper.count))
                                            .font(.system(size:40))
                                            .foregroundColor(.white)
                                            .opacity(0.6)
                                    }
                                }
                            }
                        }
                        Spacer()
                    }
                }.padding().padding(.bottom,30) //what happened here?
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(alignment:.trailing,spacing: 35) {
                            Group{
                                Button(action: {
                                    self.cameraHelper.micOn.toggle()
                                }) {
                                    VStack(spacing: 8) {
                                        Image("Microphone")
                                            .renderingMode(.template)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: UIScreen.screenWidth / 10, height: UIScreen.screenWidth / 10)
                                            .font(.title)
                                            .foregroundColor(.white)
                                        Text("Mic \(self.cameraHelper.micOn ? "on" : "off")")
                                            .foregroundColor(.white)
                                    }
                                }
                                Button(action: {
                                    self.showMusicModal.toggle()
                                }) {
                                    VStack(spacing: 8) {
                                        Image("Music")
                                            .renderingMode(.template)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: UIScreen.screenWidth / 10, height: UIScreen.screenWidth / 10)
                                            .font(.title)
                                            .foregroundColor(.white)
                                        Text("Music")
                                            .foregroundColor(.white)
                                    }
                                }.sheet(isPresented: $showMusicModal,onDismiss: { self.musicPlayer.stop() }) {MusicClipView(showMusicModal: $showMusicModal, musicPlayer: $musicPlayer, cameraHelper: cameraHelper)}
                                Button(action: {
                                    self.cameraHelper.stopRecord()
                                }) {
                                    VStack(spacing: 8) {
                                        Image("Done")
                                            .renderingMode(.template)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: UIScreen.screenWidth / 10, height: UIScreen.screenWidth / 10)
                                            .font(.title)
                                            .foregroundColor(.white)
                                        Text("Done")
                                            .foregroundColor(.white)
                                    }
                                }
                                HStack {
                                    if self.show{
                                        PopOverView(cameraHelper: self.cameraHelper, show: self.$show).background(Color.white.opacity(0.5)).cornerRadius(15)
                                    }
                                    Button(action: {
                                        withAnimation(.spring()){
                                            self.show.toggle()
                                        }
                                    }) {
                                        VStack(spacing: 8) {
                                            Image("Clock")
                                                .renderingMode(.template)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: UIScreen.screenWidth / 10, height: UIScreen.screenWidth / 10)
                                                .font(.title)
                                                .foregroundColor(.white)
                                            Text("Burst")
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                                Button(action: {
                                    self.cameraHelper.clearImages()
                                }) {
                                    VStack(spacing: 8) {
                                        Image("Trash")
                                            .renderingMode(.template)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: UIScreen.screenWidth / 10, height: UIScreen.screenWidth / 10)
                                            .font(.title)
                                            .foregroundColor(.white)
                                        Text("Trash").foregroundColor(.white)
                                    }
                                }
                            }.padding(.trailing,UIScreen.screenWidth / 50) //ugly
                        }.padding(.bottom, 55).padding(.trailing)
                    }

                    HStack(spacing: 0) {
                        Spacer()
                        CaptureButtons(
                            showCountdown: $showCountdown,
                            captureMethod:self.cameraHelper.captureShot,
                            recordVideoMethod:self.cameraHelper.startRecord,
                            pauseVideoMethod: self.cameraHelper.pauseRecord,
                            playMusicMethod: playMethod,
                            pauseMusicMethod: self.musicPlayer.pause)
                            .offset(y:-UIScreen.screenHeight / 15)
                        Spacer()
                    }.padding(.bottom, 5)
                }
                    .navigationBarTitle("")
                    .navigationBarItems(leading:
                        Button(action: {
                            self.viewRouter.currentPage = .feed
                            self.viewRouter.showBottomNAV.toggle()
                            self.viewRouter.index = 0
                        }) {
                            Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .font(.system(size: 22))
                            .frame(width: 30, height: 50)
                            .contentShape(Rectangle())
                            .offset(x:-10)
                        }, trailing:
                        Button(action: {
                            self.cameraHelper.changeCamera()
                        }) {
                            Image("Flip")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.white)
                            .frame(width: 30, height: 50)
                            .contentShape(Rectangle())
                            .offset(x:-10)
                        }
                    )
                    .padding(.top, UIApplication.shared.windows.first?.safeAreaInsets.top)
                    .padding(.bottom, (UIApplication.shared.windows.first?.safeAreaInsets.bottom)! + 5)
            }.background(Color.black.edgesIgnoringSafeArea(.all)).edgesIgnoringSafeArea(.all)
        }.accentColor(.white)
    }

    func playMethod()->Void {
        if let selectedAudio = self.cameraHelper.selectedAudio {
            self.musicPlayer.play(name: selectedAudio)
        }
    }
}

struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView(viewRouter: ViewRouter())
    }
}

extension UIScreen{
    static let screenWidth = UIScreen.main.bounds.size.width
    static let screenHeight = UIScreen.main.bounds.size.height
    static let screenSize = UIScreen.main.bounds.size
}
