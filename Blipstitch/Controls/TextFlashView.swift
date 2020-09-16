//
//  TextFlashView.swift
//  blipcam
//
//  Created by Christopher Tufaro on 9/5/20.
//  Copyright © 2020 Christopher Tufaro. All rights reserved.
//

import SwiftUI
import Combine

struct TextFlashView: View {
    @Binding var flash: Bool
    var textToFlash: String
    var body: some View {
        ZStack {
            VStack{
                Text(self.textToFlash)
                    .padding()
                    .font(.system(size: 50))
                    .opacity(flash ? 0.6 : 0.0)
                    .foregroundColor(.white)
                    .onReceive(resetTimer(), perform: { _ in self.flash = false })
            }
        }
    }
    
    func resetTimer() -> AnyPublisher<Date, Never> {
        guard flash else {
            return Empty<Date, Never>().eraseToAnyPublisher()
        }
        return Timer.TimerPublisher(interval: 0.6, runLoop: .main, mode: .default)
            .autoconnect()
            .eraseToAnyPublisher()
    }
}

struct TextFlashView_Previews: PreviewProvider {
    @State static var flash:Bool = false
    static var previews: some View {
        TextFlashView(flash: $flash, textToFlash: "Hello")
    }
}
