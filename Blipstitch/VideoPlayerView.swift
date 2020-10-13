//
//  TemplateView.swift
//  Blipstitch
//
//  Created by Christopher Tufaro on 9/15/20.
//  Copyright © 2020 Christopher Tufaro. All rights reserved.
//

import SwiftUI
import UIKit
import AVFoundation
import NavigationStack

struct VideoPlayerView: View {
    @State private var showingSheet = true
    @EnvironmentObject private var navigationStack: NavigationStack
    var myVidUrl: String
    var body: some View {
        ZStack {
            VideoPlayer(vidUrl: myVidUrl)
            VStack{
                HStack {
                    Button(action: {
                        self.navigationStack.pop()
                    }) {
                        Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                        .font(.system(size: 22))
                        .frame(width: 30, height: 50)
                        .contentShape(Rectangle())
                        .padding([.leading,.top],5)
                    }
                    Spacer()
                }
                Spacer()
                
            }
            HStack {
                Spacer()
                VStack {
                    Spacer()
                    Image(systemName: "heart")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 55, height: 55)
                        .foregroundColor(.white)
                        .padding()
                }
            }
        }.edgesIgnoringSafeArea(.all)
    }
}

struct VideoPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        VideoPlayerView(myVidUrl: "https://tufarostorage.blob.core.windows.net/kickspins/display.mp4")
        //Text("Fix this")
    }
}

struct VideoPlayer: UIViewRepresentable {
    let vidUrl:String
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<VideoPlayer>) {
    }
    
    func makeUIView(context: Context) -> UIView {
        return PlayerUIView(vidUrl: vidUrl)
    }
}

class PlayerUIView: UIView {
    private var playerLayer = AVPlayerLayer()
    private var playerLooper: NSObject?
    
    init(vidUrl:String) {
        super.init(frame: .zero)
        let url = URL(string: vidUrl)!
        let playerItem = AVPlayerItem(url: url)
        let player = AVQueuePlayer(items: [playerItem])
        //let affineTransform = CGAffineTransform(rotationAngle: (.pi*90)/180.0)
        playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
        //playerLayer.setAffineTransform(affineTransform)
        playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        player.play()
        playerLayer.player = player
        layer.addSublayer(playerLayer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
    
}
