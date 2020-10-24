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
    Album(album_name: "Buddy", album_author: "Royalty Free", album_cover: "buddy", album_state: .paused),
    Album(album_name: "Country Boy", album_author: "Royalty Free", album_cover: "countryboy", album_state: .paused),
    Album(album_name: "Dance Dance", album_author: "Royalty Free", album_cover: "dance", album_state: .paused),
    Album(album_name: "Dreams", album_author: "Royalty Free", album_cover: "dreams", album_state: .paused),
    Album(album_name: "Dubstep", album_author: "Royalty Free", album_cover: "dubstep", album_state: .paused),
    Album(album_name: "Epic Song", album_author: "Royalty Free", album_cover: "epic", album_state: .paused),
    Album(album_name: "Hip Jazz", album_author: "Royalty Free", album_cover: "hipjazz", album_state: .paused),
    Album(album_name: "House Music", album_author: "Royalty Free", album_cover: "house", album_state: .paused),
    Album(album_name: "Perception", album_author: "Royalty Free", album_cover: "perception", album_state: .paused),
    Album(album_name: "Punky Punk", album_author: "Royalty Free", album_cover: "punky", album_state: .paused),
    Album(album_name: "Rumble", album_author: "Royalty Free", album_cover: "rumble", album_state: .paused)]).observeChildrenChanges()

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
                                Image("Album")
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
