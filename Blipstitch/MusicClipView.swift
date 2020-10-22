//
//  MusicClipView.swift
//  Blipstitch
//
//  Created by Christopher Tufaro on 10/19/20.
//  Copyright © 2020 Christopher Tufaro. All rights reserved.
//

import SwiftUI
import Combine

struct MusicClipView: View {
    @Binding var showMusicModal:Bool
    @Binding var musicPlayer:MusicPlayer
    @ObservedObject var cameraHelper:CameraHelper
    @ObservedObject var albums: ObservableArray<Album> = ObservableArray(array: [
    Album(album_name: "Let Her Go", album_author: "Passenger", album_cover: "p1", album_state: .paused),
    Album(album_name: "Bad Blood", album_author: "Taylor Swift", album_cover: "p2", album_state: .paused),
    Album(album_name: "La La La", album_author: "Kurt Hugo Schneider", album_cover: "p3", album_state: .paused),
    Album(album_name: "Let Me Love You", album_author: "DJ Snake", album_cover: "p4", album_state: .paused),
    Album(album_name: "Castle On The Hill", album_author: "Ed Sherran", album_cover: "p5", album_state: .paused),
    Album(album_name: "Blank Space", album_author: "Taylor Swift", album_cover: "p6", album_state: .paused),
    Album(album_name: "Havana", album_author: "Camila Cabello", album_cover: "p7", album_state: .paused),
    Album(album_name: "Red", album_author: "Taylor Swift", album_cover: "p8", album_state: .paused),
    Album(album_name: "I Like It", album_author: "J Balvin", album_cover: "p9", album_state: .paused),
    Album(album_name: "Lover", album_author: "Taylor Swift", album_cover: "p10", album_state: .paused),
    Album(album_name: "7/27 Harmony", album_author: "Camila Cabello", album_cover: "p11", album_state: .paused),
    Album(album_name: "Joanne", album_author: "Lady Gaga", album_cover: "p12", album_state: .paused),
    Album(album_name: "Roar", album_author: "Kay Perry", album_cover: "p13", album_state: .paused),
    Album(album_name: "My Church", album_author: "Maren Morris", album_cover: "p14", album_state: .paused),
    Album(album_name: "Part Of Me", album_author: "Katy Perry", album_cover: "p15", album_state: .paused)]).observeChildrenChanges()

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack{
                VStack(spacing: 10){
                    ForEach(albums.array){album in
                        HStack(spacing: 15){
                            Button(action: {
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
                            Button(action: {
                                togglePlayState(album : album)
                            }) {
                                Image(systemName: album.album_state == .paused ? "play.circle" : "pause.circle")
                                .foregroundColor(.blue)
                                .font(.system(size: 25))
                                .frame(width: 30, height: 50)
                                .offset(x:-10)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                .background(Color.white)
            }
        }
    }

    func togglePlayState(album:Album){
        if album.album_state == .paused {
            resetAllState()
            musicPlayer.play(name: album.album_cover)
            album.album_state = .playing
        } else if album.album_state == .playing {
            musicPlayer.pause()
            album.album_state = .paused
        }
    }
    
    func resetAllState(){
        albums.array.forEach {
            $0.album_state = .paused
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

class Album:Identifiable,ObservableObject {
    var id = UUID()
    var album_name : String
    var album_author : String
    var album_cover : String
    @Published var album_state : PlayState = .paused
    
    init(album_name:String, album_author:String, album_cover:String, album_state: PlayState){
        self.album_name = album_name
        self.album_author = album_author
        self.album_cover = album_cover
        self.album_state = album_state
    }
}


enum PlayState:String {
    case paused
    case playing
}

class ObservableArray<T>: ObservableObject {

    @Published var array:[T] = []
    var cancellables = [AnyCancellable]()

    init(array: [T]) {
        self.array = array

    }

    func observeChildrenChanges<T: ObservableObject>() -> ObservableArray<T> {
        let array2 = array as! [T]
        array2.forEach({
            let c = $0.objectWillChange.sink(receiveValue: { _ in self.objectWillChange.send() })

            // Important: You have to keep the returned value allocated,
            // otherwise the sink subscription gets cancelled
            self.cancellables.append(c)
        })
        return self as! ObservableArray<T>
    }
}
