//
//  File.swift
//  Blipstitch
//
//  Created by Christopher Tufaro on 9/14/20.
//  Copyright © 2020 Christopher Tufaro. All rights reserved.
//

import SwiftUI

struct FeedItem: Hashable, Codable, Identifiable {
    var id: Int
    var smallText: String
    var largeText: String
    var imageName: String
    var heartSelected: Bool
    
    init(id:Int, smallText: String, largeText: String, imageName: String){
        self.id = id
        self.smallText = smallText
        self.largeText = largeText
        self.imageName = imageName
        self.heartSelected = false
    }
    
    mutating func heartSelect(){
        self.heartSelected.toggle()
    }
    
}

