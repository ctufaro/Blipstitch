//
//  TestContentView.swift
//  Blipstitch
//
//  Created by Christopher Tufaro on 9/18/20.
//  Copyright © 2020 Christopher Tufaro. All rights reserved.
//

import SwiftUI


struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView(viewRouter: ViewRouter())
    }
}

struct FeedView: View{
    @ObservedObject var viewRouter : ViewRouter
    @State var selectedIndex = ""
    @State var show = false

    var body: some View{
        ZStack{
            NavigationView{
                VStack{
                    TopMenu(show: $show, viewRouter: viewRouter)
                    
                    Spacer(minLength: 0)
                    
                    FeedList()
                    
                    Spacer(minLength: 0)
                    BottomMenuView(viewRouter: self.viewRouter)
                }.edgesIgnoringSafeArea(.all)
            }.accentColor(.white)
            
            SideMenu(show: $show, selectedIndex: $selectedIndex).edgesIgnoringSafeArea(.all)
            
        }
        //.edgesIgnoringSafeArea(.all)
    }
}

