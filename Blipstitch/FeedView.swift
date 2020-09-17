//
//  FeedView.swift
//  blipcam
//
//  Created by Christopher Tufaro on 9/11/20.
//  Copyright © 2020 Christopher Tufaro. All rights reserved.
//

import SwiftUI

struct FeedView: View {
    @ObservedObject var viewRouter : ViewRouter
    var body: some View {
        GeometryReader { reader in
            NavigationView{
                VStack {
                    TopMenuView(viewRouter:self.viewRouter).padding(.top,15)
                    List {
                        ForEach(self.buildArray()) { item in
                            NavigationLink(destination: TemplateView(viewRouter: self.viewRouter)) {
                                FeedItemRow(feedItem: item)
                                    .listRowInsets(EdgeInsets(top: -1, leading: 0, bottom: -1, trailing: 0)).offset(x:UIScreen.main.bounds.width-(UIScreen.main.bounds.width*1.05))
                                
                            }.buttonStyle(PlainButtonStyle())
                                .padding([.top,.bottom],-7)
                        }
                    }
                    .navigationBarTitle("")
                    .navigationBarHidden(true)
                    BottomMenuView(viewRouter: self.viewRouter)
                }
            }
        }
    }
    
    func buildArray() -> [FeedItem]{
        var items = [FeedItem]()
        items.append(FeedItem(id: 0, smallText: "Small Text Here", largeText: "LARGE TEXT HERE", imageName: "Us1"))
        items.append(FeedItem(id: 1, smallText: "Small Text Here", largeText: "LARGE TEXT HERE", imageName: "Us2"))
        items.append(FeedItem(id: 2, smallText: "Small Text Here", largeText: "LARGE TEXT HERE", imageName: "Us3"))
        items.append(FeedItem(id: 3, smallText: "Small Text Here", largeText: "LARGE TEXT HERE", imageName: "Us4"))
        items.append(FeedItem(id: 4, smallText: "Small Text Here", largeText: "LARGE TEXT HERE", imageName: "Us5"))
        return items
    }
}

struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView(viewRouter: ViewRouter())
    }
}


struct FeedItemRow: View{
    @State var feedItem: FeedItem
    var body: some View{
        ZStack{
            Image(feedItem.imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: UIScreen.screenWidth+4, height: 200, alignment: .center)
                .clipped()
            VStack {
                HStack {
                    Spacer()
                    AvatarView(size:35).padding()
                }
                Spacer()
                HStack{
                    VStack(alignment: .leading, spacing: 0){
                        Text(feedItem.smallText)
                            .foregroundColor(.white)
                            .font(Font.custom("AvenirNext-Medium", size: 14.0))
                        
                        Text(feedItem.largeText)
                            .foregroundColor(.white)
                            .font(Font.custom("AvenirNext-Bold", size: 24.0))
                            .offset(y:-5)
                    }.padding()
                    Spacer()
                }
            }
            VStack{
                Spacer()
                HStack(alignment: .bottom){
                    Spacer()
                    VStack {
                        Button(action: {
                            self.feedItem.heartSelect()
                        }) {
                            Image(systemName: feedItem.heartSelected ? "heart.fill" : "heart")
                                .foregroundColor(.white)
                                .font(.system(size: 35))
                        }
                        Text("1000")
                            .foregroundColor(.white)
                            .font(Font.custom("AvenirNext-Bold", size: 14.0))
                    }.offset(y:10)
                    
                }.padding()
            }
        }
    }
}
