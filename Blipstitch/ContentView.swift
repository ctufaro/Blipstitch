//
//  ContentView.swift
//  blipcam
//
//  Created by Christopher Tufaro on 9/9/20.
//  Copyright © 2020 Christopher Tufaro. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var viewRouter : ViewRouter
    var body: some View {
        VStack {
            ContainedView()
        }
    }
    
    func ContainedView() -> AnyView {
        switch viewRouter.currentPage {
        case .feed:
            return AnyView(FeedView(viewRouter: viewRouter))
        case .camera:
            return AnyView(CameraView(viewRouter: viewRouter))
        case .profile:
            return AnyView(ProfileView(viewRouter: viewRouter))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(viewRouter: ViewRouter())
    }
}


