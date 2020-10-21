//
//  MusicClipView.swift
//  Blipstitch
//
//  Created by Christopher Tufaro on 10/19/20.
//  Copyright © 2020 Christopher Tufaro. All rights reserved.
//

import SwiftUI

struct MusicClipView: View {
    @Binding var showMusicModal:Bool
    @Binding var musicPlayer:MusicPlayer
    @ObservedObject var cameraHelper:CameraHelper
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack{
                VStack(spacing: 10){
                    ForEach(albums,id: \.album_name){album in
                        HStack(spacing: 15){
                            Button(action: {
                                //musicPlayer.play(name: album.album_cover)
                                self.cameraHelper.selectedAudio = album.album_cover
                                self.showMusicModal.toggle()
                            }){
                                Image("\(album.album_cover)")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 55, height: 55)
                                    .cornerRadius(15)
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("\(album.album_name)")
                                    Text("\(album.album_author)")
                                        .font(.caption)
                                }
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                .background(Color.white)
            }
        }
    }
}

struct MusicClipView_Previews: PreviewProvider {
    @State static var showMusicModal:Bool = false
    @State static var musicPlayer:MusicPlayer = MusicPlayer()
    @State static var cameraHelper:CameraHelper = CameraHelper()
    static var previews: some View {
        MusicClipView(showMusicModal: $showMusicModal, musicPlayer: $musicPlayer, cameraHelper: cameraHelper)
    }
}

struct Album{
    
    var album_name : String
    var album_author : String
    var album_cover : String
}

var albums = [
    
    Album(album_name: "Let Her Go", album_author: "Passenger", album_cover: "p1"),
    Album(album_name: "Bad Blood", album_author: "Taylor Swift", album_cover: "p2"),
    Album(album_name: "La La La", album_author: "Kurt Hugo Schneider", album_cover: "p3"),
    Album(album_name: "Let Me Love You", album_author: "DJ Snake", album_cover: "p4"),
    Album(album_name: "Castle On The Hill", album_author: "Ed Sherran", album_cover: "p5"),
    Album(album_name: "Blank Space", album_author: "Taylor Swift", album_cover: "p6"),
    Album(album_name: "Havana", album_author: "Camila Cabello", album_cover: "p7"),
    Album(album_name: "Red", album_author: "Taylor Swift", album_cover: "p8"),
    Album(album_name: "I Like It", album_author: "J Balvin", album_cover: "p9"),
    Album(album_name: "Lover", album_author: "Taylor Swift", album_cover: "p10"),
    Album(album_name: "7/27 Harmony", album_author: "Camila Cabello", album_cover: "p11"),
    Album(album_name: "Joanne", album_author: "Lady Gaga", album_cover: "p12"),
    Album(album_name: "Roar", album_author: "Kay Perry", album_cover: "p13"),
    Album(album_name: "My Church", album_author: "Maren Morris", album_cover: "p14"),
    Album(album_name: "Part Of Me", album_author: "Katy Perry", album_cover: "p15"),
]
