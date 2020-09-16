//
//  PlayView.swift
//  blipcam
//
//  Created by Christopher Tufaro on 9/6/20.
//  Copyright © 2020 Christopher Tufaro. All rights reserved.
//

import SwiftUI

struct TimerView: View {
    @State var timeRemaining : Int
    @State var method: () -> Void
    @State var interval : Double
    @State var timer: Timer? = nil
    @Binding var show : Bool
    
    var body: some View {
        Button(action: {
            self.show.toggle()
            //show 3-2-1
            self.startTimer()
        }) {
            Image("Clock")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width:UIScreen.screenWidth/10,height:UIScreen.screenWidth/10)
            .foregroundColor(.black)
        }
    }
    
    func startTimer(){
        let defaultTimeRemaining = self.timeRemaining
        timer = Timer.scheduledTimer(withTimeInterval: self.interval, repeats: true){ tempTimer in
            if self.timeRemaining > 0 {
                self.method()
                self.timeRemaining -= 1
            } else {
                self.timer?.invalidate()
                self.timer = nil
                self.timeRemaining = defaultTimeRemaining
            }
        }
    }
}

struct TimerView_Previews: PreviewProvider {
    @State static var show = false
    static var previews: some View {
        TimerView(timeRemaining: 30, method: doSomething, interval: 0.03, show:$show)
    }
    
    static func doSomething(){
        print("call method")
    }
}
