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
    var textViewArray:[UITextView]
    
    init(){
        textViewArray = []
    }
    
    func createText(){
        delegate!.createText()
    }
    
    func addTextViewToArray(_ textView:UITextView){
        textViewArray.append(textView)
    }
    
    func printTextViewValues(){
        for tv in textViewArray{
            let radians = atan2f(Float(tv.transform.b), Float(tv.transform.a))
            let degrees = radians * Float((180 / Double.pi))
            print("value:\(tv.text!) font:\(String(describing: tv.font?.fontName)) fontSize:\(String(describing: tv.font?.pointSize)) location:\(tv.frame.origin) rotation:\(degrees), frame:\(tv.frame)")
        }
    }
}

protocol GestureDelegate {
    func createText()
}


