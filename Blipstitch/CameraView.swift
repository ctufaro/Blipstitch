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
    @ObservedObject var metalHelper = MetalHelper()
    @ObservedObject var viewRouter:ViewRouter
    @State var selection: Int? = nil
    @State var show = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AVCamView(metalHelper: metalHelper)
                TextFlashView(flash: $metalHelper.flashText, textToFlash: self.metalHelper.filterName)
                VStack{
                    Spacer()
                    HStack{
                        if self.metalHelper.capturedImage != nil {
                            NavigationLink(destination: PreviewView(shots:$metalHelper.shots), tag: 1, selection: $selection) {
                                Button(action: {
                                    self.selection = 1
                                }) {
                                    ZStack{
                                        Image(uiImage: self.metalHelper.capturedImage!)
                                            .renderingMode(.original)
                                            .resizable()
                                            .aspectRatio(self.metalHelper.capturedImage!.size, contentMode: .fit)
                                            .frame(height:UIScreen.screenHeight/4)
                                            .cornerRadius(10)
                                            .overlay(RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.white, lineWidth: 2))
                                            .clipped()
                                        Text(String(self.metalHelper.count))
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
                                    self.metalHelper.changeCamera()
                                }) {
                                    VStack(spacing: 8) {
                                        Image("Flip").resizable().scaledToFit()
                                            .frame(width: UIScreen.screenWidth / 10, height: UIScreen.screenWidth / 10)
                                            .font(.title)
                                            .foregroundColor(.white)
                                        Text("Flip")
                                            .foregroundColor(.white)
                                    }
                                }
                                HStack {
                                    if self.show{
                                        PopOverView(metalHelper: self.metalHelper, show: self.$show).background(Color.white.opacity(0.5)).cornerRadius(15)
                                    }
                                    Button(action: {
                                        withAnimation(.spring()){
                                            self.show.toggle()
                                        }
                                    }) {
                                        VStack(spacing: 8) {
                                            Image("Clock").resizable().scaledToFit()
                                                .frame(width: UIScreen.screenWidth / 10, height: UIScreen.screenWidth / 10)
                                                .font(.title)
                                                .foregroundColor(.white)
                                            Text("Burst")
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                                Button(action: {
                                    self.metalHelper.clearImages()
                                }) {
                                    VStack(spacing: 8) {
                                        Image("Trash")
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
                        ButtonPress(method:self.metalHelper.captureShot).offset(y:-UIScreen.screenHeight / 15)
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
