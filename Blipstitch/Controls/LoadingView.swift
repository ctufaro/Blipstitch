//
//  ActivityIndicatorView.swift
//  Blipstitch
//
//  Created by Christopher Tufaro on 9/21/20.
//  Copyright © 2020 Christopher Tufaro. All rights reserved.
//

import SwiftUI

struct LoadingView: View{
    @Binding var isShowing: Bool
    @Binding var showingText: String
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {
                VStack {
                    Text(self.showingText)
                    ActivityIndicatorView(isAnimating: .constant(true), style: .large)
                }
                .frame(width: geometry.size.width / 2,
                       height: geometry.size.height / 5)
                    .background(Color.secondary.colorInvert())
                    .foregroundColor(Color.primary)
                    .cornerRadius(20)
                    .opacity(self.isShowing ? 0.9 : 0)
            }
        }
    }
}

struct LoadingView_Previews: PreviewProvider {
    @State static var isShowing = true
    @State static var showingText = "Loading..."
    static var previews: some View {
        LoadingView(isShowing:$isShowing, showingText: $showingText)
    }
}

struct ActivityIndicatorView: UIViewRepresentable {

    @Binding var isAnimating: Bool
    let style: UIActivityIndicatorView.Style

    func makeUIView(context: UIViewRepresentableContext<ActivityIndicatorView>) -> UIActivityIndicatorView {
        return UIActivityIndicatorView(style: style)
    }

    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityIndicatorView>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    }
}
