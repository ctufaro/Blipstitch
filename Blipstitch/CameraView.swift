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
    
    var body: some View {
        NavigationView {
            ZStack {
                AVCamView(cameraHelper:cameraHelper)
                TextFlashView(flash: $cameraHelper.flashText, textToFlash: self.cameraHelper.filterName)
                VStack{
                    Spacer()
                    HStack{
                        if self.cameraHelper.capturedImage != nil {
                            NavigationLink(destination: PreviewView(shots:$cameraHelper.shots), tag: 1, selection: $selection) {
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
                }.padding()
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(alignment:.trailing,spacing: 35) {
                            Group{
                                Button(action: {
                                    self.cameraHelper.changeCamera()
                                }) {
                                    VStack(spacing: 8) {
                                        Image("Flip")
                                            .renderingMode(.template)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: UIScreen.screenWidth / 10, height: UIScreen.screenWidth / 10)
                                            .font(.title)
                                            .foregroundColor(.white)
                                        Text("Flip")
                                            .foregroundColor(.white)
                                    }
                                }
                                Button(action: {
                                    self.cameraHelper.stopRecord()
                                }) {
                                    VStack(spacing: 8) {
                                        Image("Stop")
                                            .renderingMode(.template)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: UIScreen.screenWidth / 10, height: UIScreen.screenWidth / 10)
                                            .font(.title)
                                            .foregroundColor(.white)
                                        Text("Stop")
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
                        ButtonPress(method:self.cameraHelper.captureShot, recordMethod:self.cameraHelper.toggleRecord).offset(y:-UIScreen.screenHeight / 15)
                        Spacer()
                    }.padding(.bottom, 5)
                }
                    // due to all edges are ignored...
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
                            //.background(Color.gray)
                            .offset(x:-10)
                        }
                    )
                    //.navigationBarHidden(true)
                    .padding(.top, UIApplication.shared.windows.first?.safeAreaInsets.top)
                    .padding(.bottom, (UIApplication.shared.windows.first?.safeAreaInsets.bottom)! + 5)
            }.background(Color.black.edgesIgnoringSafeArea(.all)).edgesIgnoringSafeArea(.all)
        }.accentColor(.white)
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
