//
//  TemplateView.swift
//  Blipstitch
//
//  Created by Christopher Tufaro on 9/21/20.
//  Copyright © 2020 Christopher Tufaro. All rights reserved.
//

import SwiftUI


struct LongPressButtonView: View{
    @State var isLongPressing = false
    @State var pauseVideoMethod: () -> Void
    @State var recordVideoMethod: () -> Void
    @State var playMusicMethod: () -> Void
    @State var pauseMusicMethod: () -> Void
    var body: some View{
        HStack(spacing:40) {
            Button(action: {
                if(self.isLongPressing){
                    self.pauseMusicMethod()
                    self.pauseVideoMethod()
                    self.isLongPressing.toggle()
                } else {
                    //print("tap")
                }
            }, label: {
                Image("Circle")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: UIScreen.screenWidth / 8, height: UIScreen.screenWidth / 8)
                    .foregroundColor(.white)
            })
            .buttonStyle(ScaleButtonStyle())
            .simultaneousGesture(LongPressGesture(minimumDuration: 0.2).onEnded { _ in
                self.isLongPressing = true
                self.playMusicMethod()
                self.recordVideoMethod()
            })
        }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 2 : 1)
            //.animation(Animation.easeInOut(duration: 0.15))
        
    }
}


struct LongPressButtonView_Previews: PreviewProvider {
    static var previews: some View {
        //LongPressButtonView()
        Text("Fix This")
    }
}

