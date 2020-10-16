//
//  FontListView.swift
//  Blipstitch
//
//  Created by Christopher Tufaro on 9/28/20.
//  Copyright © 2020 Christopher Tufaro. All rights reserved.
//

import SwiftUI

struct FontListView: View {
    var body: some View {
            VStack {
                Divider()
                ScrollView(.horizontal) {
                    HStack(spacing: 10) {
                        ForEach(0..<10) { index in
                            CircleView(label: "\(index)")
                        }
                    }.padding()
                }.frame(height: 100)
                Divider()
                Spacer()
            }
        }
}

struct CircleView: View {
    @State var label: String
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.yellow)
                .frame(width: 70, height: 70)
            Text(label)
        }
    }
}

struct FontListView_Previews: PreviewProvider {
    static var previews: some View {
        FontListView()
    }
}
