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
    @State var selectedIndex = ""
    @State var show = false
    var body: some View {
        ZStack{
            VStack {
                TopMenu(show: $show, viewRouter: viewRouter)
                Spacer()
                Text("Profile View")
                Spacer()
                BottomMenuView(viewRouter: viewRouter)
            }.edgesIgnoringSafeArea(.all)
            SideMenu(show: $show, selectedIndex: $selectedIndex).edgesIgnoringSafeArea(.all)
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(viewRouter: ViewRouter())
    }
}
