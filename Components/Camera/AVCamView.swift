//
//  AVCam.swift
//  Blipstitch
//
//  Created by Christopher Tufaro on 9/14/20.
//  Copyright © 2020 Christopher Tufaro. All rights reserved.
//

import SwiftUI

struct AVCamView: UIViewControllerRepresentable {
    var metalHelper:MetalHelper
    func makeUIViewController(context: UIViewControllerRepresentableContext<AVCamView>) -> CameraViewController {
        return CameraViewController(metalHelper:metalHelper)
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: UIViewControllerRepresentableContext<AVCamView>) {
        
    }
}
