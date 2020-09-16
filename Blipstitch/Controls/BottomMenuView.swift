//
//  BottomNAVView.swift
//  blipcam
//
//  Created by Christopher Tufaro on 9/14/20.
//  Copyright © 2020 Christopher Tufaro. All rights reserved.
//

import SwiftUI

struct BottomMenuView: View {
    @ObservedObject var viewRouter : ViewRouter
    var body: some View {
        VStack {
            Spacer()
            VStack {
                Spacer()
                HStack(spacing: 0){
                    Button(action: {
                        self.viewRouter.index = 0
                        self.viewRouter.currentPage = .feed
                        self.viewRouter.showBottomNAV = true
                    }) {
                        Image(systemName: "house")
                        .font(.system(size: 25))
                        .foregroundColor(self.viewRouter.index == 0 ? .black : Color.black.opacity(0.35))
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 0)
                    
                    Button(action: {
                        self.viewRouter.index = 1
                    }) {
                        Image(systemName: "magnifyingglass")
                        .font(.system(size: 25))
                        .foregroundColor(self.viewRouter.index == 1 ? .black : Color.black.opacity(0.35))
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 0)
                    
                    Button(action: {
                        self.viewRouter.index = 2
                        self.viewRouter.currentPage = .camera
                        self.viewRouter.showBottomNAV = false
                    }) {
                        Image(systemName:"camera")
                        .font(.system(size: 25))
                        .foregroundColor(self.viewRouter.index == 2 ? .black : Color.black.opacity(0.35))
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 0)
                    
                    Button(action: {
                        self.viewRouter.index = 3
                    }) {
                        Image(systemName:"bubble.left")
                        .font(.system(size: 25))
                        .foregroundColor(self.viewRouter.index == 3 ? .black : Color.black.opacity(0.35))
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 0)
                    
                    Button(action: {
                        self.viewRouter.index = 4
                        self.viewRouter.currentPage = .profile
                        self.viewRouter.showBottomNAV = true
                    }) {
                        Image(systemName:"person")
                        .font(.system(size: 25))
                        .foregroundColor(self.viewRouter.index == 4 ? .black : Color.black.opacity(0.35))
                        .padding(.horizontal)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, (UIApplication.shared.windows.first?.safeAreaInsets.bottom)! + 15)
            .edgesIgnoringSafeArea(.all)
            .background(Color.white)
        }.frame(width:UIScreen.screenWidth,height: UIScreen.screenHeight/15)
    }
    
}

struct BottomMenuView_Previews: PreviewProvider {
    static var previews: some View {
        BottomMenuView(viewRouter: ViewRouter())
    }
}
