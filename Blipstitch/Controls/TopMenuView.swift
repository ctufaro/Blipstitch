//
//  TopMenuView.swift
//  Blipstitch
//
//  Created by Christopher Tufaro on 9/15/20.
//  Copyright © 2020 Christopher Tufaro. All rights reserved.
//

import SwiftUI

struct TopMenu: View{
    @State var edges = UIApplication.shared.windows.first?.safeAreaInsets
    @Binding var show: Bool
    @ObservedObject var viewRouter : ViewRouter
    var body: some View{
        ZStack{
            HStack{
                Button(action:{}, label:{
                    Image(systemName: "line.horizontal.3")
                        .font(.system(size:22))
                        .foregroundColor(.black)
                })
                Spacer(minLength: 0)
                Button(action:{
                    
                    withAnimation(.spring()){
                        self.show.toggle()
                    }
                    
                }, label:{
                    Image("Chris")
                        .resizable()
                        .renderingMode(.original)
                        .frame(width:35, height: 35)
                        .clipShape(Circle())
                })
            }
            
            Text(viewRouter.currentPageName())
                .font(.system(size:22))
                .fontWeight(.semibold)
        }
        .padding(7)
            // since top edges are ignored
            .padding(.top,edges!.top)
            .background(Color.white)
            .shadow(color:Color.black.opacity(0.1), radius: 5, x:0, y:5)
    }
}

struct TopMenuView: View {
    @ObservedObject var viewRouter : ViewRouter
    var body: some View {
        ZStack{
            HStack(alignment: .bottom, spacing: 0) {
                Text(viewRouter.currentPageName())
                    .font(Font.custom("AvenirNext-Bold", size: 24.0))
            }.frame(width:UIScreen.screenWidth, height:10)
                .padding(.top,15)
            HStack{
                Spacer()
                Button(action: {
                }) {
                    AvatarView(size:35)
                }
                .padding(.trailing,15)
            }
        }
    }
}

struct TopMenuView_Previews: PreviewProvider {
    static var previews: some View {
        TopMenuView(viewRouter: ViewRouter())
            .previewLayout(PreviewLayout.sizeThatFits)
            .padding()
    }
}
