//
//  TopMenuView.swift
//  Blipstitch
//
//  Created by Christopher Tufaro on 9/15/20.
//  Copyright © 2020 Christopher Tufaro. All rights reserved.
//

import SwiftUI

struct TopMenuView: View {
    @ObservedObject var viewRouter : ViewRouter
    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            Text(viewRouter.currentPageName())
                .font(Font.custom("AvenirNext-Bold", size: 24.0))
        }.frame(width:UIScreen.screenWidth, height:10)
    }
}

struct TopMenuView_Previews: PreviewProvider {
    static var previews: some View {
        TopMenuView(viewRouter: ViewRouter())
        .previewLayout(PreviewLayout.sizeThatFits)
        .padding()
    }
}
