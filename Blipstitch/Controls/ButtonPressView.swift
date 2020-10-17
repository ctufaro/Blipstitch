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
            ButtonPress(method: myfunc, recordMethod: myfunc)
        }
    }
    func myfunc() -> Void {
        print("called")
    }
}

struct ButtonPress: View{
    @State private var timer: Timer?
    @State var isLongPressing = false
    @State var method: () -> Void
    @State var recordMethod: () -> Void
    var body: some View{
        HStack(spacing:40) {
            Button(action: {
                if(self.isLongPressing){
                    //this tap was caused by the end of a longpress gesture, so stop our fastforwarding
                    self.isLongPressing.toggle()
                    self.timer?.invalidate()
                } else {
                    self.method()
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
                    self.method()
                })
            })
        
            //Record Button In HStack
            Button(action: {
                self.recordMethod()
            }) {
                Image("Circle")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: UIScreen.screenWidth / 8, height: UIScreen.screenWidth / 8)
                    .foregroundColor(.white)
            }
        
        }
    }
}

struct ButtonPressView_Previews: PreviewProvider {
    static var previews: some View {
        ButtonPressView()
    }
}

