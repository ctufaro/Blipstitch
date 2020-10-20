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
    var myAudioPlayer = AVAudioPlayer()
    func play(name:String) {
        
        guard let audioFileURL = Bundle.main.url(forResource: name, withExtension: "mp3") else {
            return
        }
        
        do {
            try myAudioPlayer = AVAudioPlayer(contentsOf: audioFileURL)
        } catch let error {
            print(error.localizedDescription)
        }
        
        myAudioPlayer.play()
        
    }
}
