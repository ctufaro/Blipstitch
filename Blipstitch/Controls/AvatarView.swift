//
//  AvatarView.swift
//  Blipstitch
//
//  Created by Christopher Tufaro on 9/16/20.
//  Copyright © 2020 Christopher Tufaro. All rights reserved.
//

import SwiftUI

struct AvatarView: View {
    var size:CGFloat
    var body: some View {
        Image("Chris")
        .renderingMode(.original)
        .resizable()
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

struct AvatarView_Previews: PreviewProvider {
    static var previews: some View {
        AvatarView(size:55)
    }
}
