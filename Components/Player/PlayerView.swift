//
//  PlayerView.swift
//  blipcam
//
//  Created by Christopher Tufaro on 9/7/20.
//  Copyright © 2020 Christopher Tufaro. All rights reserved.
//

import SwiftUI
import UIKit

struct PlayerView: UIViewRepresentable {
    let images: [UIImage]
    @Binding var duration: Double
    
    func makeUIView(context: Self.Context) -> ImageView {
        let animationImageView = ImageView()
        animationImageView.imageView.clipsToBounds = true
        animationImageView.imageView.autoresizesSubviews = true
        animationImageView.imageView.contentMode = UIView.ContentMode.scaleAspectFill
        animationImageView.imageView.image = UIImage.animatedImage(with: images, duration: duration)
        return animationImageView
    }
    
    func updateUIView(_ uiView: ImageView, context: UIViewRepresentableContext<PlayerView>) {
        uiView.imageView.image = UIImage.animatedImage(with: images, duration: duration)
    }
    
}

class ImageView: UIView {
    let imageView = UIImageView()

    init() {
        super.init(frame: .zero)
        addSubview(imageView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

