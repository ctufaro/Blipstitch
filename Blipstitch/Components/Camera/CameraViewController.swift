//  Created by Christopher Tufaro on 9/3/20.
//  Copyright © 2020 Christopher Tufaro. All rights reserved.

//  https://stackoverflow.com/questions/27092354/rotating-uiimage-in-swift/29753437
//  https://gist.github.com/levantAJ/10a1b73b2f50eaa0443b9fa21e704687

import UIKit
import AVFoundation
import CoreVideo
import Photos
import MobileCoreServices
import MetalKit
class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureDepthDataOutputDelegate, AVCaptureAudioDataOutputSampleBufferDelegate, CameraDelegate {

    // MARK: - Properties
    
    // MARK: - Camera Heleper
    public var cameraHelper:CameraHelper!
    
    // MARK: - Metal View
    public let mtkView = PreviewMetalView()
    
    // MARK: - AV Cam Properties
    private var filterIndex: Int = 0
    public var videoFilter: FilterRenderer?
    public var photoFilter: FilterRenderer?
    public var renderingEnabled = true
    public let processingQueue = DispatchQueue(label: "photo processing queue", attributes: [], autoreleaseFrequency: .workItem)
    private let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera,.builtInWideAngleCamera],mediaType: .video,position: .unspecified)
    private var statusBarOrientation: UIInterfaceOrientation = .portrait
    private var videoFilterOn: Bool = false
    private enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }
    private var setupResult: SessionSetupResult = .success
    public let session = AVCaptureSession()
    public var isSessionRunning = false
    public let sessionQueue = DispatchQueue(label: "SessionQueue", attributes: [], autoreleaseFrequency: .workItem)
    public var videoInput: AVCaptureDeviceInput!
    public var audioDataOutput:AVCaptureAudioDataOutput = AVCaptureAudioDataOutput()
    private let dataOutputQueue = DispatchQueue(label: "VideoDataQueue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    public let videoDataOutput = AVCaptureVideoDataOutput()
    public let photoOutput = AVCapturePhotoOutput()
    
    // MARK: - Filter Types
    private let filterRenderers: [FilterRenderer] = [EmptyRenderer(), InstaRenderer(filterName: "CIPhotoEffectChrome"), InstaRenderer(filterName: "CIPhotoEffectFade"), InstaRenderer(filterName: "CIPhotoEffectInstant"),InstaRenderer(filterName: "CIPhotoEffectMono"), InstaRenderer(filterName: "CIPhotoEffectNoir"), InstaRenderer(filterName: "CIPhotoEffectProcess"),InstaRenderer(filterName: "CIPhotoEffectTonal"), InstaRenderer(filterName: "CIPhotoEffectTransfer"), InstaRenderer(filterName: "CILinearToSRGBToneCurve"), InstaRenderer(filterName: "CISRGBToneCurveToLinear")]
    private let photoRenderers: [FilterRenderer] = [EmptyRenderer(), InstaRenderer(filterName: "CIPhotoEffectChrome"), InstaRenderer(filterName: "CIPhotoEffectFade"), InstaRenderer(filterName: "CIPhotoEffectInstant"),InstaRenderer(filterName: "CIPhotoEffectMono"), InstaRenderer(filterName: "CIPhotoEffectNoir"), InstaRenderer(filterName: "CIPhotoEffectProcess"),InstaRenderer(filterName: "CIPhotoEffectTonal"), InstaRenderer(filterName: "CIPhotoEffectTransfer"), InstaRenderer(filterName: "CILinearToSRGBToneCurve"), InstaRenderer(filterName: "CISRGBToneCurveToLinear")]
    
    // MARK: - Recording Video Properties
    public lazy var isRecording = false
    public var videoWriter: AVAssetWriter!
    public var videoWriterInput: AVAssetWriterInput!
    public var videoWriterInputPixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor!
    public var audioWriterInput: AVAssetWriterInput!
    public var sessionAtSourceTime: CMTime?
    public let writingQueue = DispatchQueue(label: "com.hilaoinc.hilao.queue.recorder.start-writing")
    public var videoSize = CGSize(width: 1280, height: 720) //HACK!
    public var exportPreset = AVAssetExportPreset1280x720
    public var sessionRunningContext = 0
    internal var recordButton: UIImageView?
    
    // MARK: - View Controller Life Cycle
    // ConfigureSession() sets all inputs and outputs
    convenience init(cameraHelper:CameraHelper) {
        self.init(nibName:nil, bundle:nil)
        self.cameraHelper = cameraHelper
        self.cameraHelper.delegate = self
    }
    
    //winky
    internal var longPressGestureRecognizer: UILongPressGestureRecognizer?
    @objc internal func handleLongPressGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            print("began")
            break
        case .changed:
            print("changed")
            break
        case .ended:
            print("ended")
            break
        case .cancelled:
            print("cancelled")
            break
        case .failed:
            print("failed")
            break
        default:
            break
        }
        
    }
    //winky
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mtkView.translatesAutoresizingMaskIntoConstraints = false
        mtkView.preferredFramesPerSecond = 30
        view.addSubview(mtkView)
        NSLayoutConstraint.activate([
            mtkView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            mtkView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mtkView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mtkView.topAnchor.constraint(equalTo: view.topAnchor),
        ])
        
        mtkView.setupView()
        
        //winky
        self.recordButton = UIImageView(image: UIImage(named: "Record"))
        self.view.addSubview(recordButton!)
        self.recordButton!.isUserInteractionEnabled = true
        self.recordButton!.sizeToFit()
        self.recordButton!.translatesAutoresizingMaskIntoConstraints = false
        self.recordButton!.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.recordButton!.widthAnchor.constraint(equalToConstant: 50).isActive = true
        self.recordButton!.heightAnchor.constraint(equalToConstant: 50).isActive = true
        self.recordButton!.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -150).isActive = true
        self.longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressGestureRecognizer(_:)))
        if let recordButton = self.recordButton,
            let longPressGestureRecognizer = self.longPressGestureRecognizer {
            recordButton.isUserInteractionEnabled = true
            recordButton.sizeToFit()
            longPressGestureRecognizer.minimumPressDuration = 0.05
            longPressGestureRecognizer.allowableMovement = 10.0
            recordButton.addGestureRecognizer(longPressGestureRecognizer)
        }
        //winky
        
        videoFilterOn = true

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(focusAndExposeTap))
        mtkView.addGestureRecognizer(tapGesture)
        
        //let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGesture))
        //mtkView.addGestureRecognizer(panGestureRecognizer)
        
        let leftSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(changeFilterSwipe))
        leftSwipeGesture.direction = .left
        mtkView.addGestureRecognizer(leftSwipeGesture)
        
        let rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(changeFilterSwipe))
        rightSwipeGesture.direction = .right
        mtkView.addGestureRecognizer(rightSwipeGesture)
        
        // Check video authorization status, video access is required
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // The user has previously granted access to the camera
            break
            
        case .notDetermined:
            /*
             The user has not yet been presented with the option to grant video access
             Suspend the SessionQueue to delay session setup until the access request has completed
             */
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                if !granted {
                    self.setupResult = .notAuthorized
                }
                self.sessionQueue.resume()
            })
            
        default:
            // The user has previously denied access
            setupResult = .notAuthorized
        }
        
        /*
         Setup the capture session.
         In general it is not safe to mutate an AVCaptureSession or any of its
         inputs, outputs, or connections from multiple threads at the same time.
         
         Don't do this on the main queue, because AVCaptureSession.startRunning()
         is a blocking call, which can take a long time. Dispatch session setup
         to the sessionQueue so as not to block the main queue, which keeps the UI responsive.
         */
        sessionQueue.async {
            self.configureSession()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let interfaceOrientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation else {
            #if DEBUG
            fatalError("Could not obtain UIInterfaceOrientation from a valid windowScene")
            #else
            return nil
            #endif
        }
        
        //let interfaceOrientation = UIApplication.shared.statusBarOrientation
        statusBarOrientation = interfaceOrientation
        
        let initialThermalState = ProcessInfo.processInfo.thermalState
        if initialThermalState == .serious || initialThermalState == .critical {
            showThermalState(state: initialThermalState)
        }
        
        sessionQueue.async {
            switch self.setupResult {
            case .success:
                self.addObservers()
                
                if let photoOrientation = AVCaptureVideoOrientation(interfaceOrientation: interfaceOrientation) {
                    if let unwrappedPhotoOutputConnection = self.photoOutput.connection(with: .video) {
                        unwrappedPhotoOutputConnection.videoOrientation = photoOrientation
                    }
                }
                
                if let unwrappedVideoDataOutputConnection = self.videoDataOutput.connection(with: .video) {
                    let videoDevicePosition = self.videoInput.device.position
                    let rotation = PreviewMetalView.Rotation(with: interfaceOrientation,
                                                             videoOrientation: unwrappedVideoDataOutputConnection.videoOrientation,
                                                             cameraPosition: videoDevicePosition)
                    self.mtkView.mirroring = (videoDevicePosition == .front)
                    if let rotation = rotation {
                        self.mtkView.rotation = rotation
                    }
                }
                self.dataOutputQueue.async {
                    self.renderingEnabled = true
                }
                
                self.session.startRunning()
                self.isSessionRunning = self.session.isRunning
                
            case .notAuthorized:
                DispatchQueue.main.async {
                    let message = NSLocalizedString("AVCamFilter doesn't have permission to use the camera, please change privacy settings",
                                                    comment: "Alert message when the user has denied access to the camera")
                    let actions = [
                        UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                      style: .cancel,
                                      handler: nil),
                        UIAlertAction(title: NSLocalizedString("Settings", comment: "Alert button to open Settings"),
                                      style: .`default`,
                                      handler: { _ in
                                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!,
                                                                  options: [:],
                                                                  completionHandler: nil)
                        })
                    ]
                    
                    self.alert(title: "AVCamFilter", message: message, actions: actions)
                }
                
            case .configurationFailed:
                DispatchQueue.main.async {
                    
                    let message = NSLocalizedString("Unable to capture media",
                                                    comment: "Alert message when something goes wrong during capture session configuration")
                    
                    self.alert(title: "AVCamFilter",
                               message: message,
                               actions: [UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                                       style: .cancel,
                                                       handler: nil)])
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        dataOutputQueue.async {
            self.renderingEnabled = false
        }
        sessionQueue.async {
            if self.setupResult == .success {
                self.session.stopRunning()
                self.isSessionRunning = self.session.isRunning
                self.removeObservers()
            }
        }
        
        super.viewWillDisappear(animated)
    }
    
    private func configureSession() {
        if setupResult != .success {
            return
        }
        
        let defaultVideoDevice: AVCaptureDevice? = videoDeviceDiscoverySession.devices.first
        
        guard let videoDevice = defaultVideoDevice else {
            print("Could not find any video device")
            setupResult = .configurationFailed
            return
        }
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoDevice)
        } catch {
            print("Could not create video device input: \(error)")
            setupResult = .configurationFailed
            return
        }

        session.beginConfiguration()
        
        session.sessionPreset = AVCaptureSession.Preset.high
        
        // Add video input.
        guard session.canAddInput(videoInput) else {
            print("Could not add video device input to the session")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        session.addInput(videoInput)
        
        // Add microphone input
        do {
            guard let audioDevice = AVCaptureDevice.default(for: .audio) else {fatalError()}
            let audioDeviceInput: AVCaptureDeviceInput
            do {
                audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice)
            }
            catch {
                fatalError("Could not create AVCaptureDeviceInput instance with error: \(error).")
            }
            guard session.canAddInput(audioDeviceInput) else {
                fatalError()
            }
            session.addInput(audioDeviceInput)
            print("Microphone Input Added")
        }
        
        // Add video data output
        if session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput)
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
            videoDataOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)
        } else {
            print("Could not add video data output to the session")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        // Add microphone output
        do {
            audioDataOutput = AVCaptureAudioDataOutput()
            let queue = DispatchQueue(label: "com.shu223.audiosamplequeue")
            audioDataOutput.setSampleBufferDelegate(self, queue: queue)
            guard session.canAddOutput(audioDataOutput) else {
                fatalError()
            }
            session.addOutput(audioDataOutput)
            print("Microphone Output Added")
        }
        
        // Add photo output
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true

        } else {
            print("Could not add photo output to the session")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }

        capFrameRate(videoDevice: videoDevice)
        
        //Recording AssetWriter
        self.setupWriter()
        
        session.commitConfiguration()
    }
    
    @objc func didEnterBackground(notification: NSNotification) {
        // Free up resources.
        dataOutputQueue.async {
            self.renderingEnabled = false
            if let videoFilter = self.videoFilter {
                videoFilter.reset()
            }
            self.mtkView.pixelBuffer = nil
            self.mtkView.flushTextureCache()
        }
        processingQueue.async {
            if let photoFilter = self.photoFilter {
                photoFilter.reset()
            }
        }
    }
    
    @objc func willEnterForground(notification: NSNotification) {
        dataOutputQueue.async {
            self.renderingEnabled = true
        }
    }
    
    @objc func thermalStateChanged(notification: NSNotification) {
        if let processInfo = notification.object as? ProcessInfo {
            showThermalState(state: processInfo.thermalState)
        }
    }
    
    func showThermalState(state: ProcessInfo.ThermalState) {
        DispatchQueue.main.async {
            var thermalStateString = "UNKNOWN"
            if state == .nominal {
                thermalStateString = "NOMINAL"
            } else if state == .fair {
                thermalStateString = "FAIR"
            } else if state == .serious {
                thermalStateString = "SERIOUS"
            } else if state == .critical {
                thermalStateString = "CRITICAL"
            }
            
            let message = NSLocalizedString("Thermal state: \(thermalStateString)", comment: "Alert message when thermal state has changed")
            let actions = [
                UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                              style: .cancel,
                              handler: nil)]
            
            self.alert(title: "AVCamFilter", message: message, actions: actions)
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(
            alongsideTransition: { _ in
                
                guard let interfaceOrientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation else {
                    #if DEBUG
                    fatalError("Could not obtain UIInterfaceOrientation from a valid windowScene")
                    #else
                    return nil
                    #endif
                }

                //let interfaceOrientation = UIApplication.shared.statusBarOrientation
                self.statusBarOrientation = interfaceOrientation
                self.sessionQueue.async {
                    /*
                     The photo orientation is based on the interface orientation. You could also set the orientation of the photo connection based
                     on the device orientation by observing UIDeviceOrientationDidChangeNotification.
                     */
                    if let photoOrientation = AVCaptureVideoOrientation(interfaceOrientation: interfaceOrientation) {
                        if let unwrappedPhotoOutputConnection = self.photoOutput.connection(with: .video) {
                            unwrappedPhotoOutputConnection.videoOrientation = photoOrientation
                        }
                    }
                    
                    if let unwrappedVideoDataOutputConnection = self.videoDataOutput.connection(with: .video) {
                        if let rotation = PreviewMetalView.Rotation(with: interfaceOrientation,
                                                                    videoOrientation: unwrappedVideoDataOutputConnection.videoOrientation,
                                                                    cameraPosition: self.videoInput.device.position) {
                            self.mtkView.rotation = rotation
                        }
                    }
                }
        }, completion: nil
        )
    }
    
    // MARK: - IBAction Functions
    @IBAction private func changeFilterSwipe(_ gesture: UISwipeGestureRecognizer) {
        let filteringEnabled = videoFilterOn
        if filteringEnabled {
            if gesture.direction == .left {
                filterIndex = (filterIndex + 1) % filterRenderers.count
            } else if gesture.direction == .right {
                filterIndex = (filterIndex + filterRenderers.count - 1) % filterRenderers.count
            }
            
            let newIndex = filterIndex
            
            if newIndex == 0 {
                toggleFiltering()
                return
            }
            
            _ = filterRenderers[newIndex].description
            
            // Switch renderers
            dataOutputQueue.async {
                if let filter = self.videoFilter {
                    filter.reset()
                }
                self.videoFilter = self.filterRenderers[newIndex]
            }
            
            processingQueue.async {
                if let filter = self.photoFilter {
                    filter.reset()
                }
                self.photoFilter = self.photoRenderers[newIndex]
            }
            
            self.cameraHelper.swipedFilter(filterName: "F\(newIndex)")
        }
    }
    
    @IBAction private func focusAndExposeTap(_ gesture: UITapGestureRecognizer) {
        print("focusAndExposeTap")
        let location = gesture.location(in: mtkView)
        guard let texturePoint = mtkView.texturePointForView(point: location) else {
            return
        }
        
        let textureRect = CGRect(origin: texturePoint, size: .zero)
        let deviceRect = videoDataOutput.metadataOutputRectConverted(fromOutputRect: textureRect)
        focus(with: .autoFocus, exposureMode: .autoExpose, at: deviceRect.origin, monitorSubjectAreaChange: true)
    }
    
    private var initialZoom: CGFloat = 1.0
    @objc func panGesture(_ sender: UIPanGestureRecognizer) {

    // note that 'view' here is the overall video preview
    let velocity = sender.velocity(in: view)

    if velocity.y > 0 || velocity.y < 0 {

        //let originalCapSession = session
        _ = session
        var devitce : AVCaptureDevice!

        let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera], mediaType: AVMediaType.video, position: .unspecified)
        let devices = videoDeviceDiscoverySession.devices
        devitce = devices.first!

        guard let device = devitce else { return }

        let minimumZoomFactor: CGFloat = 1.0
        let maximumZoomFactor: CGFloat = min(device.activeFormat.videoMaxZoomFactor, 10.0) // artificially set a max useable zoom of 10x

        // clamp a zoom factor between minimumZoom and maximumZoom
        func clampZoomFactor(_ factor: CGFloat) -> CGFloat {
            return min(max(factor, minimumZoomFactor), maximumZoomFactor)
        }

        func update(scale factor: CGFloat) {
            do {

                try device.lockForConfiguration()
                defer { device.unlockForConfiguration() }
                device.videoZoomFactor = factor
            } catch {
                print("\(error.localizedDescription)")
            }
        }

        switch sender.state {

        case .began:
            initialZoom = device.videoZoomFactor
            //startRecording() /// call to start recording your video

        case .changed:

            // distance in points for the full zoom range (e.g. min to max), could be view.frame.height
            let fullRangeDistancePoints: CGFloat = 300.0

            // extract current distance travelled, from gesture start
            let currentYTranslation: CGFloat = sender.translation(in: view).y

            // calculate a normalized zoom factor between [-1,1], where up is positive (ie zooming in)
            let normalizedZoomFactor = -1 * max(-1,min(1,currentYTranslation / fullRangeDistancePoints))

            // calculate effective zoom scale to use
            let newZoomFactor = clampZoomFactor(initialZoom + normalizedZoomFactor * (maximumZoomFactor - minimumZoomFactor))

            // update device's zoom factor'
            update(scale: newZoomFactor)

        case .ended, .cancelled:
            //stopRecording() /// call to start recording your video
            break

        default:
            break
        }
    }
    }
    
    @objc func subjectAreaDidChange(notification: NSNotification) {
        let devicePoint = CGPoint(x: 0.5, y: 0.5)
        focus(with: .continuousAutoFocus, exposureMode: .continuousAutoExposure, at: devicePoint, monitorSubjectAreaChange: false)
    }
    
    func gestureRecognizer(_: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith shouldRecognizeSimultaneouslyWithGestureRecognizer:UIGestureRecognizer) -> Bool {
        return true
    }
    
    func changeCamera() {
        //cameraButton.isEnabled = false
        //photoButton.isEnabled = false
        
        dataOutputQueue.sync {
            renderingEnabled = false
            if let filter = videoFilter {
                filter.reset()
            }
            mtkView.pixelBuffer = nil
        }
        
        processingQueue.async {
            if let filter = self.photoFilter {
                filter.reset()
            }
        }
        
        let interfaceOrientation = statusBarOrientation
        
        sessionQueue.async {
            let currentVideoDevice = self.videoInput.device
            var preferredPosition = AVCaptureDevice.Position.unspecified
            switch currentVideoDevice.position {
            case .unspecified, .front:
                preferredPosition = .back
                
            case .back:
                preferredPosition = .front
            @unknown default:
                fatalError("Unknown video device position.")
            }
            
            let devices = self.videoDeviceDiscoverySession.devices
            if let videoDevice = devices.first(where: { $0.position == preferredPosition }) {
                var videoInput: AVCaptureDeviceInput
                do {
                    videoInput = try AVCaptureDeviceInput(device: videoDevice)
                } catch {
                    print("Could not create video device input: \(error)")
                    self.dataOutputQueue.async {
                        self.renderingEnabled = true
                    }
                    return
                }
                self.session.beginConfiguration()
                
                // Remove the existing device input first, since using the front and back camera simultaneously is not supported.
                self.session.removeInput(self.videoInput)
                
                if self.session.canAddInput(videoInput) {
                    NotificationCenter.default.removeObserver(self,
                                                              name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange,
                                                              object: currentVideoDevice)
                    NotificationCenter.default.addObserver(self,
                                                           selector: #selector(self.subjectAreaDidChange),
                                                           name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange,
                                                           object: videoDevice)
                    
                    self.session.addInput(videoInput)
                    self.videoInput = videoInput
                } else {
                    print("Could not add video device input to the session")
                    self.session.addInput(self.videoInput)
                }
                
                if let unwrappedPhotoOutputConnection = self.photoOutput.connection(with: .video) {
                    self.photoOutput.connection(with: .video)!.videoOrientation = unwrappedPhotoOutputConnection.videoOrientation
                }

                self.session.commitConfiguration()
            }
            
            let videoPosition = self.videoInput.device.position
            
            if let unwrappedVideoDataOutputConnection = self.videoDataOutput.connection(with: .video) {
                let rotation = PreviewMetalView.Rotation(with: interfaceOrientation,
                                                         videoOrientation: unwrappedVideoDataOutputConnection.videoOrientation,
                                                         cameraPosition: videoPosition)
                
                self.mtkView.mirroring = (videoPosition == .front)
                if let rotation = rotation {
                    self.mtkView.rotation = rotation
                }
            }
            
            self.dataOutputQueue.async {
                self.renderingEnabled = true
            }
            
            DispatchQueue.main.async {
                //self.updateDepthUIHidden()
                //self.cameraButton.isEnabled = true
                //self.photoButton.isEnabled = true
            }
        }
    }

    func toggleFiltering() {
        
        videoFilterOn = !videoFilterOn
        let filteringEnabled = videoFilterOn
        
        //let stateImage = UIImage(named: filteringEnabled ? "ColorFilterOn" : "ColorFilterOff")
        //self.videoFilterButton.setImage(stateImage, for: .normal)
        
        let index = filterIndex
        
        if filteringEnabled {
            _ = filterRenderers[index].description
            //updateFilterLabel(description: filterDescription)
        }
        
        // Enable/disable the video filter.
        dataOutputQueue.async {
            if filteringEnabled {
                self.videoFilter = self.filterRenderers[index]
            } else {
                if let filter = self.videoFilter {
                    filter.reset()
                }
                self.videoFilter = nil
            }
        }
        
        // Enable/disable the photo filter.
        processingQueue.async {
            if filteringEnabled {
                self.photoFilter = self.photoRenderers[index]
            } else {
                if let filter = self.photoFilter {
                    filter.reset()
                }
                self.photoFilter = nil
            }
        }
        videoFilterOn = true
    }

}


