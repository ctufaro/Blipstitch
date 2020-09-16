//
//  ProfileView.swift
//  blipcam
//
//  Created by Christopher Tufaro on 9/14/20.
//  Copyright © 2020 Christopher Tufaro. All rights reserved.
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject var viewRouter : ViewRouter
    var body: some View {
        VStack {
            TopMenuView(viewRouter:viewRouter)
            Spacer()
            Text("Profile View")
            Spacer()
            BottomMenuView(viewRouter: viewRouter)
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(viewRouter: ViewRouter())
    }
}
