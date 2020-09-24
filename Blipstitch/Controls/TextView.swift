//
//  TextView.swift
//  Blipstitch
//
//  Created by Christopher Tufaro on 9/22/20.
//  Copyright © 2020 Christopher Tufaro. All rights reserved.
//

import SwiftUI

struct TextWrapper: UIViewRepresentable {
    
    @Binding var text: String
    @Binding var textStyle: UIFont.TextStyle
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView(frame: .zero)
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        //textView.text = "Initialized"
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
        //self.tempImageView.addSubview(textView)
        textView.becomeFirstResponder()
        
        return textView
    }
    
    func addGestures(view: UIView, context: Context) {
        view.isUserInteractionEnabled = true
        let panGesture = UIPanGestureRecognizer(target: context.coordinator,
                                                action: #selector(Coordinator.panGesture(sender:)))
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 1
        //view.addGestureRecognizer(panGesture)
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(sender:)))
        view.addGestureRecognizer(pinchGesture)
        
        //let rotationGesture = UIRotationGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.rotationGesture(sender:)))
        //view.addGestureRecognizer(rotationGesture)
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
        //uiView.font = UIFont.preferredFont(forTextStyle: textStyle)
        //uiView.layer.borderColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0).cgColor
        //uiView.layer.borderWidth = 2.0
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator($text)
    }
    
    class Coordinator: NSObject, UITextViewDelegate, UIGestureRecognizerDelegate {
        //var text: Binding<String>
        var parent: 
        
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
        
        @objc func rotationGesture(sender: UIRotationGestureRecognizer) {
            if let view = sender.view {
                if view is UITextView {
                    view.transform = view.transform.rotated(by: sender.rotation)
                    sender.rotation = 0
                }
            }
        }
        
        @objc func panGesture(sender: UIPanGestureRecognizer) {
            if let view = sender.view {
                if view is UITextView {
                    view.center = CGPoint(x: view.center.x + sender.translation(in: view).x,
                                          y: view.center.y + sender.translation(in: view).y)
                    sender.setTranslation(CGPoint.zero, in: view)
                }
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
    
    var body: some View {
        TextWrapper(text:$text, textStyle: $textStyle)
            .border(Color.red, width: 4)
            //.fixedSize()
            .offset(x: position.width + dragOffset.width, y: position.height + dragOffset.height)
            .scaleEffect(finalAmount + currentAmount)
            .simultaneousGesture(DragGesture()
                .updating($dragOffset, body: { (value, state, transaction) in
                    
                    state = value.translation
                })
                .onEnded({ (value) in
                    self.position.height += value.translation.height
                    self.position.width += value.translation.width
                })
            )

    }
}

struct TextView_Previews: PreviewProvider {
    static var previews: some View {
        TextView()
    }
}
