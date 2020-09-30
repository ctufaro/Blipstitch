//
//  TextGestureView.swift
//  Blipstitch
//
//  Created by Christopher Tufaro on 9/29/20.
//  Copyright © 2020 Christopher Tufaro. All rights reserved.
//

import SwiftUI
import UIKit

struct TextGestureView: UIViewControllerRepresentable {
    @Binding var text: String
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> TextGestureController {
        let textGestureController = TextGestureController($text)
        return textGestureController
    }
    
    func updateUIViewController(_ textGestureController: TextGestureController, context: Context) {
        textGestureController.text = $text
    }
    
    class Coordinator: NSObject {
        var parent: TextGestureView
        
        init(_ textGestureView: TextGestureView) {
            self.parent = textGestureView
        }
    }
}

struct TextGestureView_Previews: PreviewProvider {
    @State static var text = "Hi!"
    static var previews: some View {
        TextGestureView(text: $text)
    }
}

class TextGestureController: UIViewController, UITextViewDelegate {
    var text: Binding<String>
    var textView: UITextView!
    var snapGesture: SnapGesture?
    
    init(_ text: Binding<String>) {
        self.text = text
        self.textView = UITextView(frame: CGRect(x: 20.0, y: 90.0, width: UIScreen.screenSize.width, height: 100.0))
        self.textView.layer.borderWidth = 1
        self.textView.layer.borderColor = UIColor.red.cgColor
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        print("View did load")
        super.viewDidLoad()
        textView.delegate = self
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.textAlignment = .center
        textView.font = UIFont(name: "Arial-BoldMT", size: 40)
        textView.textColor = UIColor.white
        textView.layer.shadowColor = UIColor.black.cgColor
        textView.layer.shadowOffset = CGSize(width: 1.0, height: 0.0)
        textView.layer.shadowOpacity = 0.2
        textView.layer.shadowRadius = 1.0
        textView.layer.backgroundColor = UIColor.clear.cgColor
        textView.autocorrectionType = .no
        textView.isScrollEnabled = false
        view.addSubview(textView)
        textView.becomeFirstResponder()
        snapGesture = SnapGesture(view: textView)
    }
    
    func textViewDidChange(_ textView: UITextView) {
        self.text.wrappedValue = textView.text
        let fixedWidth = textView.frame.size.width
        let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        textView.frame.size = CGSize(width: max(newSize.width, fixedWidth), height: newSize.height)
    }
}

/*
 usage:
 
 add gesture:
 yourObjToStoreMe.snapGesture = SnapGesture(view: your_view)
 remove gesture:
 yourObjToStoreMe.snapGesture = nil
 disable gesture:
 yourObjToStoreMe.snapGesture.isGestureEnabled = false
 advanced usage:
 view to receive gesture(usually superview) is different from view to be transformed,
 thus you can zoom the view even if it is too small to be touched.
 yourObjToStoreMe.snapGesture = SnapGesture(transformView: your_view_to_transform, gestureView: your_view_to_recieve_gesture)
 
 */

class SnapGesture: NSObject, UIGestureRecognizerDelegate {
    
    // MARK: - init and deinit
    convenience init(view: UIView) {
        self.init(transformView: view, gestureView: view)
    }
    
    init(transformView: UIView, gestureView: UIView) {
        super.init()
        
        self.addGestures(v: gestureView)
        self.weakTransformView = transformView
        
        guard let transformView = self.weakTransformView, let superview = transformView.superview else {
            return
        }
        
        // This is required in order to be able to snap the view to center later on,
        // using the tx property of its transform.
        transformView.center = superview.center
    }
    deinit {
        self.cleanGesture()
    }
    
    // MARK: - private method
    private weak var weakGestureView: UIView?
    private weak var weakTransformView: UIView?
    
    private var panGesture: UIPanGestureRecognizer?
    private var pinchGesture: UIPinchGestureRecognizer?
    private var rotationGesture: UIRotationGestureRecognizer?
    private var tapGesture: UITapGestureRecognizer?
    
    private func addGestures(v: UIView) {
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(panProcess(_:)))
        v.isUserInteractionEnabled = true
        panGesture?.delegate = self     // for simultaneous recog
        v.addGestureRecognizer(panGesture!)
        
        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinchProcess(_:)))
        pinchGesture?.delegate = self   // for simultaneous recog
        v.addGestureRecognizer(pinchGesture!)
        
        rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(rotationProcess(_:)))
        rotationGesture?.delegate = self
        v.addGestureRecognizer(rotationGesture!)
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapProcess(_:)))
        tapGesture?.delegate = self
        v.addGestureRecognizer(tapGesture!)
        
        self.weakGestureView = v
    }
    
    private func cleanGesture() {
        if let view = self.weakGestureView {
            //for recognizer in view.gestureRecognizers ?? [] {
            //    view.removeGestureRecognizer(recognizer)
            //}
            if panGesture != nil {
                view.removeGestureRecognizer(panGesture!)
                panGesture = nil
            }
            if pinchGesture != nil {
                view.removeGestureRecognizer(pinchGesture!)
                pinchGesture = nil
            }
            if rotationGesture != nil {
                view.removeGestureRecognizer(rotationGesture!)
                rotationGesture = nil
            }
        }
        self.weakGestureView = nil
        self.weakTransformView = nil
    }
    
    // MARK: - API
    
    private func setView(view:UIView?) {
        self.setTransformView(view, gestgureView: view)
    }
    
    private func setTransformView(_ transformView: UIView?, gestgureView:UIView?) {
        self.cleanGesture()
        
        if let v = gestgureView  {
            self.addGestures(v: v)
        }
        self.weakTransformView = transformView
    }
    
    open func resetViewPosition() {
        UIView.animate(withDuration: 0.4) {
            self.weakTransformView?.transform = CGAffineTransform.identity
        }
    }
    
    open var isGestureEnabled = true
    
    // MARK: - gesture handle
    
    // location will jump when finger number change
    private var initPanFingerNumber:Int = 1
    private var isPanFingerNumberChangedInThisSession = false
    private var lastPanPoint:CGPoint = CGPoint(x: 0, y: 0)
    @objc func panProcess(_ recognizer:UIPanGestureRecognizer) {
        guard isGestureEnabled, let view = self.weakTransformView else { return }
        
        // init
        if recognizer.state == .began {
            lastPanPoint = recognizer.location(in: view)
            initPanFingerNumber = recognizer.numberOfTouches
            isPanFingerNumberChangedInThisSession = false
        }
        
        // judge valid
        if recognizer.numberOfTouches != initPanFingerNumber {
            isPanFingerNumberChangedInThisSession = true
        }
        
        if isPanFingerNumberChangedInThisSession {
            hideGuidesOnGestureEnd(recognizer)
            return
        }
        
        // perform change
        let point = recognizer.location(in: view)
        view.transform = view.transform.translatedBy(x: point.x - lastPanPoint.x, y: point.y - lastPanPoint.y)
        lastPanPoint = recognizer.location(in: view)
        
        updateMovementGuide()
        hideGuidesOnGestureEnd(recognizer)
    }
    
    private var lastScale:CGFloat = 1.0
    private var lastPinchPoint:CGPoint = CGPoint(x: 0, y: 0)
    @objc func pinchProcess(_ recognizer:UIPinchGestureRecognizer) {
        guard isGestureEnabled, let view = self.weakTransformView else { return }
            
        // init
        if recognizer.state == .began {
            lastScale = 1.0;
            lastPinchPoint = recognizer.location(in: view)
        }
        
        // judge valid
        if recognizer.numberOfTouches < 2 {
            lastPinchPoint = recognizer.location(in: view)
            hideGuidesOnGestureEnd(recognizer)
            return
        }
        
        // Scale
        if view is UITextView {
            let textView = view as! UITextView
            let font = UIFont(name: textView.font!.fontName, size: textView.font!.pointSize * recognizer.scale)
            textView.font = font
            let sizeToFit = textView.sizeThatFits(CGSize(width: UIScreen.main.bounds.size.width,height:CGFloat.greatestFiniteMagnitude))
            textView.bounds.size = CGSize(width: UIScreen.main.bounds.size.width,height: sizeToFit.height)
            //self.fontSize.wrappedValue = textView.font!.pointSize
            textView.setNeedsDisplay()
            recognizer.scale = 1
            lastScale = recognizer.scale;
        } else {
            let scale = 1.0 - (lastScale - recognizer.scale);
            view.transform = view.transform.scaledBy(x: scale, y: scale)
            lastScale = recognizer.scale;
        }
        
        // Translate
        let point = recognizer.location(in: view)
        view.transform = view.transform.translatedBy(x: point.x - lastPinchPoint.x, y: point.y - lastPinchPoint.y)
        lastPinchPoint = recognizer.location(in: view)
        
        updateMovementGuide()
        hideGuidesOnGestureEnd(recognizer)
    }
    
    
    @objc func rotationProcess(_ recognizer: UIRotationGestureRecognizer) {
        guard isGestureEnabled, let view = self.weakTransformView else { return }
        
        view.transform = view.transform.rotated(by: recognizer.rotation)
        recognizer.rotation = 0
        updateRotationGuide()
        hideGuidesOnGestureEnd(recognizer)
    }
    
    @objc func tapProcess(_ recognizer: UITapGestureRecognizer) {
        guard isGestureEnabled, let view = self.weakTransformView else { return }
        
        if view is UITextView {
            print("UITextView")
        } else {
            print("Nope")
        }
    }
    
    func hideGuidesOnGestureEnd(_ recognizer: UIGestureRecognizer) {
        if recognizer.state == .ended {
            showMovementGuide(false)
            showRotationGuide(false)
        }
    }
    
    // MARK:- UIGestureRecognizerDelegate Methods
    func gestureRecognizer(_: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith shouldRecognizeSimultaneouslyWithGestureRecognizer:UIGestureRecognizer) -> Bool {
        return true
    }
    
    // MARK:- Guides
    
    var animateGuides = true
    var guideAnimationDuration: TimeInterval = 0.3
    
    var snapToleranceDistance: CGFloat = 5 // pts
    var snapToleranceAngle: CGFloat = 1    // degrees
                        * CGFloat.pi / 180 // (converted to radians)
    
    var movementGuideView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.blue
        return view
    } ()
    
    var rotationGuideView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.red
        return view
    } ()
    
    // MARK: Movement guide and snap
    
    func updateMovementGuide() {
        guard let transformView = weakTransformView, let superview = transformView.superview else {
            return
        }
        
        let transformX = transformView.frame.midX
        let superX = superview.bounds.midX
        
        if transformX - snapToleranceDistance < superX && transformX + snapToleranceDistance > superX {
            transformView.transform.tx = 0
            showMovementGuide(true)
        } else {
            showMovementGuide(false)
        }
        
        updateGuideFrames()
    }
    
    var isShowingMovementGuide = false
    
    func showMovementGuide(_ shouldShow: Bool) {
        guard isShowingMovementGuide != shouldShow,
            let transformView = weakTransformView,
            let superview = transformView.superview
            else { return }
        
        superview.insertSubview(movementGuideView, belowSubview: transformView)
        movementGuideView.frame = CGRect(
            x: superview.frame.midX,
            y: 0,
            width: 1,
            height: superview.frame.size.height
        )
        
        let duration = animateGuides ? guideAnimationDuration : 0
        isShowingMovementGuide = shouldShow
        UIView.animate(withDuration: duration) { [weak self] in
            self?.movementGuideView.alpha = shouldShow ? 1 : 0
        }
    }
    
    // MARK: Rotation guide and snap
    
    func updateRotationGuide() {
        guard let transformView = weakTransformView else {
            return
        }
        
        let angle = atan2(transformView.transform.b, transformView.transform.a)
        if angle > -snapToleranceAngle && angle < snapToleranceAngle {
            transformView.transform = transformView.transform.rotated(by: angle * -1)
            showRotationGuide(true)
        } else {
            showRotationGuide(false)
        }
    }
    
    var isShowingRotationGuide = false
    
    func showRotationGuide(_ shouldShow: Bool) {
        guard isShowingRotationGuide != shouldShow,
            let transformView = weakTransformView,
            let superview = transformView.superview
            else { return }
        
        superview.insertSubview(rotationGuideView, belowSubview: transformView)
        
        let duration = animateGuides ? guideAnimationDuration : 0
        isShowingRotationGuide = shouldShow
        UIView.animate(withDuration: duration) { [weak self] in
            self?.rotationGuideView.alpha = shouldShow ? 1 : 0
        }
    }
    
    func updateGuideFrames() {
        guard let transformView = weakTransformView,
            let superview = transformView.superview
            else { return }
        
        rotationGuideView.frame = CGRect(
            x: 0,
            y: transformView.frame.midY,
            width: superview.frame.size.width,
            height: 1
        )
    }
}
