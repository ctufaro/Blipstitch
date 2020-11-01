//
//  ButtonTapView.swift
//  blipcam
//
//  Created by Christopher Tufaro on 9/10/20.
//  Copyright © 2020 Christopher Tufaro. All rights reserved.
//

import SwiftUI

struct ButtonPressView: View {
    var body: some View{
        ZStack {
            Color.purple.opacity(0.2).edgesIgnoringSafeArea(.all)
            ButtonPress(captureMethod: myfunc, recordVideoMethod: myfunc, pauseVideoMethod: myfunc, playMusicMethod: myfunc, pauseMusicMethod: myfunc)
        }
    }
    func myfunc() -> Void {
        print("called")
    }
}

struct ButtonPress: View{
    @State private var timer: Timer?
    @State var isLongPressing = false
    @State var captureMethod: () -> Void
    @State var recordVideoMethod: () -> Void
    @State var pauseVideoMethod: () -> Void
    @State var playMusicMethod: () -> Void
    @State var pauseMusicMethod: () -> Void
    var body: some View{
        HStack(spacing:30) {
            Button(action: {
                if(self.isLongPressing){
                    //this tap was caused by the end of a longpress gesture, so stop our fastforwarding
                    self.isLongPressing.toggle()
                    self.timer?.invalidate()
                } else {
                    self.captureMethod()
                }
            }, label: {
                Image("Capture")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: UIScreen.screenWidth / 8, height: UIScreen.screenWidth / 8)
                    .foregroundColor(.white)
                
            })
            .simultaneousGesture(LongPressGesture(minimumDuration: 0.2).onEnded { _ in
                self.isLongPressing = true
                //or fastforward has started to start the timer
                self.timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true, block: { _ in
                    self.captureMethod()
                })
            })
        
            //Record Button In HStack
            LongPressButtonView(pauseVideoMethod:self.pauseVideoMethod, recordVideoMethod:self.recordVideoMethod, playMusicMethod:self.playMusicMethod, pauseMusicMethod:self.pauseMusicMethod)
        
        }
    }
}

struct ButtonPressView_Previews: PreviewProvider {
    static var previews: some View {
        ButtonPressView()
    }
}

