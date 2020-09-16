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
                    HStack(spacing: 15) {
                        Button(action: {
                            self.top = 0
                        }) {
                            Text("Following")
                                .foregroundColor(self.top == 0 ? .white : Color.white.opacity(0.45))
                                .fontWeight(self.top == 0 ? .bold : .none)
                                .padding(.vertical)
                        }
                        Button(action: {
                            self.top = 1
                        }) {
                            Text("For You")
                                .foregroundColor(self.top == 1 ? .white : Color.white.opacity(0.45))
                                .fontWeight(self.top == 1 ? .bold : .none)
                                .padding(.vertical)
                        }
                    }
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(alignment:.trailing,spacing: 35) {
                            Button(action: {
                                self.viewRouter.currentPage = .feed
                                self.viewRouter.showBottomNAV.toggle()
                                self.viewRouter.index = 0
                            }) {
                                AvatarView(size:55)
                            }
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
                        ButtonPress(method:self.metalHelper.captureShot)
                        Spacer()
                    }.padding(.bottom, 5)
                }
                    // due to all edges are ignored...
                    .padding(.top, UIApplication.shared.windows.first?.safeAreaInsets.top)
                    .padding(.bottom, (UIApplication.shared.windows.first?.safeAreaInsets.bottom)! + 5)
            }.background(Color.black.edgesIgnoringSafeArea(.all)).edgesIgnoringSafeArea(.all)
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
