//
//  MusicPlayer.swift
//  Blipstitch
//
//  Created by Christopher Tufaro on 10/19/20.
//  Copyright © 2020 Christopher Tufaro. All rights reserved.
//

import Foundation
import AVFoundation


public class MusicPlayer {
    public static var instance = MusicPlayer()
    public var playerCreated = false
    var myAudioPlayer = AVAudioPlayer()
    func play(name:String) -> Void {
        guard let audioFileURL = Bundle.main.url(forResource: name, withExtension: "mp3") else {
            return
        }
        do {
            if !playerCreated {
                try myAudioPlayer = AVAudioPlayer(contentsOf: audioFileURL)
                playerCreated = true
            }
            print("playing: \(name).mp3")
            myAudioPlayer.play()
        } catch let error {
            print("error \(error.localizedDescription)")
        }
    }
    
    func pause(){
        self.myAudioPlayer.pause()
    }
    
    func stop(){
        self.myAudioPlayer.stop()
    }
}
