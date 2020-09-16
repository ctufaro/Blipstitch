//
//  ViewRouter.swift
//  blipcam
//
//  Created by Christopher Tufaro on 9/14/20.
//  Copyright © 2020 Christopher Tufaro. All rights reserved.
//

import SwiftUI
import Combine

class ViewRouter: ObservableObject {
    @Published var currentPage: ContainedViewType = .feed
    @Published var showBottomNAV: Bool = true
    @Published var index: Int = 0
    
    func currentPageName() -> String{
        switch currentPage {
        case .feed:
            return "Feed"
        case .camera:
            return "Camera"
        case .profile:
            return "Profile"
        }
    }
    
}

enum ContainedViewType {
    case feed
    case camera
    case profile
}
