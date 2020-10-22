//
//  File.swift
//  Blipstitch
//
//  Created by Christopher Tufaro on 9/29/20.
//  Copyright © 2020 Christopher Tufaro. All rights reserved.
//

import Foundation
import UIKit

/*class TextField:ObservableObject {
    var id = UUID()
    @Published var textValue = ""
    @Published var fontName = ""
    @Published var fontSize: Float = 40.0
}*/

class TextField: Identifiable, ObservableObject{
    var id: UUID
    @Published var textValue: String
    @Published var fontName: String
    @Published var fontSize: CGFloat

    init(){
        self.id = UUID()
        self.textValue = ""
        self.fontName = "Arial-BoldMT"
        self.fontSize = 40.0
    }
    
    init(textValue: String, fontName: String, fontSize: CGFloat){
        self.id = UUID()
        self.textValue = textValue
        self.fontName = fontName
        self.fontSize = fontSize
    }

}

class TextFields: ObservableObject{
    @Published var textFields: [TextField]

    init(){
        self.textFields = []
    }
    
    func add(textValue: String, fontName: String, fontSize: CGFloat){
        self.textFields.append(TextField(textValue: textValue, fontName: fontName, fontSize: fontSize))
    }
}

