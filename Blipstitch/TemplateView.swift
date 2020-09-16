//
//  TemplateView.swift
//  Blipstitch
//
//  Created by Christopher Tufaro on 9/15/20.
//  Copyright © 2020 Christopher Tufaro. All rights reserved.
//

import SwiftUI

struct TemplateView: View {
    @ObservedObject var viewRouter:ViewRouter
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct TemplateView_Previews: PreviewProvider {
    static var previews: some View {
        TemplateView(viewRouter:ViewRouter())
    }
}
