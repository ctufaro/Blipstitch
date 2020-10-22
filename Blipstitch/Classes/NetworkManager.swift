//
//  NetworkManager.swift
//  Blipstitch
//
//  Created by Christopher Tufaro on 9/17/20.
//  Copyright © 2020 Christopher Tufaro. All rights reserved.
//

import Foundation
import Combine

class NetworkManager: ObservableObject {
    var didChange = PassthroughSubject<NetworkManager, Never>()
    
    @Published var feedItems = [FeedItem]() {
        didSet {
            didChange.send(self)
        }
    }
    
    init() {
        guard let url = URL(string: "https://kickshowapi.azurewebsites.net/api/userpost") else { return }
        URLSession.shared.dataTask(with: url) { (data, _, _) in
            
            guard let data = data else { return }
            
            let feedItems = try! JSONDecoder().decode([FeedItem].self, from: data)
            DispatchQueue.main.async {
                self.feedItems = feedItems
            }
            print("completed fetching json")
            
        }.resume()
    }
}

