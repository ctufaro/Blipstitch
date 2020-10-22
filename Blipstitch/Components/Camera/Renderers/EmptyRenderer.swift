//
//  EmptyRenderer.swift
//  blipcam
//
//  Created by Christopher Tufaro on 9/3/20.
//  Copyright © 2020 Christopher Tufaro. All rights reserved.
//

import CoreMedia

class EmptyRenderer:FilterRenderer {
    var description: String = "Empty"
    
    var isPrepared = false

    func prepare(with inputFormatDescription: CMFormatDescription, outputRetainedBufferCountHint: Int) {
    }
    
    func reset() {
    }
    
    var outputFormatDescription: CMFormatDescription?
    
    var inputFormatDescription: CMFormatDescription?
    
    func render(pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        return nil
    }
}
