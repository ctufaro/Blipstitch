//
//  FeedView.swift
//  blipcam
//
//  Created by Christopher Tufaro on 9/11/20.
//  Copyright © 2020 Christopher Tufaro. All rights reserved.
//

import SwiftUI
import NavigationStack

struct FeedList: View {
    @ObservedObject var networkManager = NetworkManager()
    var body: some View{
        VStack {
            List {
                ForEach(self.networkManager.feedItems) { item in
                    PushView(destination: VideoPlayerView(myVidUrl: item.postMotion)) {
                        FeedItemRow(feedItem: item)
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        
                    }.buttonStyle(PlainButtonStyle())
                }.onDelete(perform: { indexSet in
                    self.networkManager.feedItems.remove(atOffsets: indexSet)
                    //print(self.networkManager.feedItems[indexSet.first!])
                })
            }
        }
    }
    
    func buildArray() -> [FeedItem]{
        var items = [FeedItem]()
        items.append(FeedItem(id: 0, postTitle: "Post Text Here", postImage: "Us1", userName: "@bliptester", postMotion: "postMotion"))
        items.append(FeedItem(id: 1, postTitle: "Post Text Here", postImage: "Us2", userName: "@bliptester", postMotion: "postMotion"))
        items.append(FeedItem(id: 2, postTitle: "Post Text Here", postImage: "Us3", userName: "@bliptester", postMotion: "postMotion"))
        items.append(FeedItem(id: 3, postTitle: "Post Text Here", postImage: "Us4", userName: "@bliptester", postMotion: "postMotion"))
        items.append(FeedItem(id: 4, postTitle: "Post Text Here", postImage: "Us5", userName: "@bliptester", postMotion: "postMotion"))
        return items
    }
}

struct FeedList_Previews: PreviewProvider {
    static var previews: some View {
        ZStack{
            Color.black
            FeedItemRow(feedItem:FeedItem(id: 0, postTitle: "Post Text Here", postImage: "https://tufarostorage.blob.core.windows.net/kickspins/C7DD4A6E-B1F2-466E-B429-71E6D43D2516.jpg", userName: "@bliptester", postMotion: "postMotion"))
                .frame(height:200)
        }.edgesIgnoringSafeArea(.all)
    }
}

struct FeedItemRow: View{
    @State var feedItem: FeedItem
    var body: some View{
        ZStack{
            VStack {
                FeedImageView(imageUrl: feedItem.postImage)
                //Text("hello").foregroundColor(.white)
            }
            VStack {
                Spacer()
                HStack{
                    VStack(alignment: .leading, spacing: 0){
                        Text(feedItem.userName)
                            .foregroundColor(.white)
                            .font(Font.custom("AvenirNext-Medium", size: 14.0))
                        
                        Text(feedItem.postTitle)
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
                            //self.feedItem.heartSelect()
                        }) {
                            Image(systemName: "heart")
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

struct FeedImageView: View {
    
    @ObservedObject var imageLoader: ImageLoader
    
    init(imageUrl: String) {
        imageLoader = ImageLoader(imageUrl: imageUrl)
    }
    
    var body: some View {
        Image(uiImage: (imageLoader.data.count == 0) ? UIImage(named: "Loading")! : UIImage(data: imageLoader.data)!)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: UIScreen.screenWidth+4, height: 200, alignment: .center)
            .clipped()
    }
}
