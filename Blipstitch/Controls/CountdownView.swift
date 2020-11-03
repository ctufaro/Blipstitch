//
//  CountdownView.swift
//  Blipstitch
//
//  Created by Christopher Tufaro on 11/2/20.
//  Copyright © 2020 Christopher Tufaro. All rights reserved.
//

import SwiftUI

struct CountdownView: View {
    @State var seconds: Int = 5
    @State var timer: Timer? = nil
    @Binding var show:Bool
    @State var recordVideoMethod: () -> Void
    @State var playMusicMethod: () -> Void
    
    var body: some View {
        if show {
            GeometryReader{g in
                ZStack {
                    Circle().strokeBorder(Color.white.opacity(0), lineWidth: 0).padding()
                    Button(action: {
                        self.startTimer()
                    }, label: {
                        Text("\(seconds)")
                            .foregroundColor(Color.white)
                            .font(.system(size: g.size.height > g.size.width ? g.size.width * 0.4: g.size.height * 0.4)).bold()
                    })
                }.onAppear(){
                    self.startTimer()
                }
            }
        }
    }
    
    func startTimer(){
        self.seconds = 5
        self.show = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true){ tempTimer in
            if(self.seconds <= 0){
                stopTimer()
            } else {
                self.seconds = self.seconds - 1
            }
        }
    }
    
    func stopTimer(){
        self.show.toggle()
        //self.playMusicMethod()
        //self.recordVideoMethod()
        timer?.invalidate()
        timer = nil
    }
    
}

struct CountdownView_Previews: PreviewProvider {
    @State static var show = false
    static func myfunc() -> Void {
        print("LongPressButtonView_Previews")
    }
    static var previews: some View {
        ZStack {
            Color(.black).ignoresSafeArea(.all)
            CountdownView(show: $show, recordVideoMethod: myfunc, playMusicMethod: myfunc)
        }
    }
}


