//
//  File.swift
//  Blipstitch
//
//  Created by Christopher Tufaro on 9/14/20.
//  Copyright © 2020 Christopher Tufaro. All rights reserved.
//

import SwiftUI

struct FeedItem: Hashable, Codable, Identifiable {
    let id: Int
    let postTitle, postImage, userName, postMotion: String
    
    init(id:Int, postTitle: String, postImage: String, userName: String, postMotion: String){
        self.id = id
        self.postTitle = postTitle
        self.postImage = postImage
        self.userName = userName
        self.postMotion = postMotion
    }
    
    init(){
        self.id = 1
        self.postTitle = "Test Post"
        self.postImage = "avatar-chris"
        self.userName = "@preview"
        self.postMotion = "motion"
    }
    
}



