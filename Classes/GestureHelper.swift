//
//  GestureHelper.swift
//  Blipstitch
//
//  Created by Christopher Tufaro on 10/1/20.
//  Copyright © 2020 Christopher Tufaro. All rights reserved.
//

import Foundation
import UIKit

class GestureHelper : ObservableObject {
    var delegate:GestureDelegate?
    
    init(){

    }
    
    func createText(){
        delegate!.createText()
    }
}

protocol GestureDelegate {
    func createText()
}


