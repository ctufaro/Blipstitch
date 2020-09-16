//
//  PopOver.swift
//  blipcam
//
//  Created by Christopher Tufaro on 9/11/20.
//  Copyright © 2020 Christopher Tufaro. All rights reserved.
//

import SwiftUI

struct PopOverView: View{
    var metalHelper: MetalHelper
    @Binding var show : Bool
    var body: some View{
        HStack() {
            HStack {
                TimerView(timeRemaining: 30, method: self.metalHelper.captureShot, interval: 0.05, show:self.$show)
                Text("30")
            }
            HStack {
                TimerView(timeRemaining: 60, method: self.metalHelper.captureShot, interval: 0.05, show:self.$show)
                Text("60")
            }
            HStack {
                TimerView(timeRemaining: 90, method: self.metalHelper.captureShot, interval: 0.05, show:self.$show)
                Text("90")
            }
        }
        .foregroundColor(.black)
        .padding(10)
    }
}

struct PopOverView_Previews: PreviewProvider {
    static var metalHelper:MetalHelper! = MetalHelper()
    @State static var show:Bool = false
    static var previews: some View {
        PopOverView(metalHelper: metalHelper, show:$show)
    }
}
