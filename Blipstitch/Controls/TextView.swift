//
//  TextView.swift
//  Blipstitch
//
//  Created by Christopher Tufaro on 9/22/20.
//  Copyright © 2020 Christopher Tufaro. All rights reserved.
//  https://stackoverflow.com/questions/56471973/how-do-i-create-a-multiline-textfield-in-swiftui/58639072#58639072

import SwiftUI

struct TextWrapper: UIViewRepresentable {
    
    @Binding var text: String
    @Binding var textStyle: UIFont.TextStyle
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView(frame: .zero)
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.delegate = context.coordinator
        textView.textAlignment = .center
        textView.font = UIFont(name: "Helvetica", size: 40)
        textView.textColor = UIColor.white
        textView.layer.shadowColor = UIColor.black.cgColor
        textView.layer.shadowOffset = CGSize(width: 1.0, height: 0.0)
        textView.layer.shadowOpacity = 0.2
        textView.layer.shadowRadius = 1.0
        textView.layer.backgroundColor = UIColor.clear.cgColor
        textView.autocorrectionType = .no
        textView.isScrollEnabled = false
        addGestures(view: textView, context: context)
        textView.becomeFirstResponder()
        return textView
    }
    
    func addGestures(view: UIView, context: Context) {
        view.isUserInteractionEnabled = true
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(sender:)))
        view.addGestureRecognizer(pinchGesture)
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator($text)
    }
    
    class Coordinator: NSObject, UITextViewDelegate, UIGestureRecognizerDelegate {
        var text: Binding<String>
        
        init(_ text: Binding<String>) {
            self.text = text
        }
        
        func textViewDidChange(_ textView: UITextView) {
            self.text.wrappedValue = textView.text
        }
        
        public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
        
        public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return false
        }
        
        public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return false
        }
        
        @objc func handlePinch(sender: UIPinchGestureRecognizer) {
            if let view = sender.view {
                if view is UITextView {
                    let textView = view as! UITextView
                    let font = UIFont(name: textView.font!.fontName, size: textView.font!.pointSize * sender.scale)
                    textView.font = font
                    
                    let sizeToFit = textView.sizeThatFits(CGSize(width: UIScreen.main.bounds.size.width,
                                                                 height:CGFloat.greatestFiniteMagnitude))
                    
                    textView.bounds.size = CGSize(width: textView.intrinsicContentSize.width,
                                                  height: sizeToFit.height)
                    
                    textView.setNeedsDisplay()
                } else {
                    view.transform = view.transform.scaledBy(x: sender.scale, y: sender.scale)
                }
                sender.scale = 1
            }
        }
    }
}

struct TextView: View {
    @State var text:String = ""
    @State var textStyle:UIFont.TextStyle = .headline
    //gestures
    @GestureState private var dragOffset = CGSize.zero
    @State private var position = CGSize.zero
    @State private var currentAmount: CGFloat = 0
    @State private var finalAmount: CGFloat = 1
    @State private var rotateState: Double = 0
    
    var body: some View {
        TextWrapper(text:$text, textStyle: $textStyle)
            //.border(Color.red, width: 2)
            //.fixedSize()
            .offset(x: position.width + dragOffset.width, y: position.height + dragOffset.height)
            .scaleEffect(finalAmount + currentAmount)
            .rotationEffect(Angle(degrees: self.rotateState))
            .simultaneousGesture(DragGesture()
                .updating($dragOffset, body: { (value, state, transaction) in
                    state = value.translation
                })
                .onEnded({ (value) in
                    self.position.height += value.translation.height
                    self.position.width += value.translation.width
                }))
            .simultaneousGesture(RotationGesture()
                .onChanged { value in
                    self.rotateState = value.degrees
                })
    }
}

struct TextView_Previews: PreviewProvider {
    static var previews: some View {
        TextView()
    }
}



