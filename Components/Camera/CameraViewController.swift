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
class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureDepthDataOutputDelegate, AVCaptureDataOutputSynchronizerDelegate, AVCaptureAudioDataOutputSampleBufferDelegate, CameraDelegate {

    // MARK: - Properties
    var metalHelper:MetalHelper!
    
    @IBOutlet weak private var cameraButton: UIButton!
    
    @IBOutlet weak private var photoButton: UIButton!
    
    @IBOutlet weak private var resumeButton: UIButton!
    
    @IBOutlet weak private var cameraUnavailableLabel: UILabel!
    
    @IBOutlet weak private var filterLabel: UILabel!
    
    let mtkView = PreviewMetalView()
    
    @IBOutlet weak private var videoFilterButton: UIButton!
    
    private var videoFilterOn: Bool = false
    
    @IBOutlet weak private var depthVisualizationButton: UIButton!
    
    private var depthVisualizationOn: Bool = false
    
    @IBOutlet weak private var depthSmoothingButton: UIButton!
    
    private var depthSmoothingOn: Bool = false
    
    @IBOutlet weak private var mixFactorNameLabel: UILabel!
    
    @IBOutlet weak private var mixFactorValueLabel: UILabel!
    
    @IBOutlet weak private var mixFactorSlider: UISlider!
    
    @IBOutlet weak private var depthDataMaxFrameRateNameLabel: UILabel!
    
    @IBOutlet weak private var depthDataMaxFrameRateValueLabel: UILabel!
    
    @IBOutlet weak private var depthDataMaxFrameRateSlider: UISlider!
    
    private enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }
    
    private var setupResult: SessionSetupResult = .success
    
    private let session = AVCaptureSession()
    
    private var isSessionRunning = false
    
    // Communicate with the session and other session objects on this queue.
    private let sessionQueue = DispatchQueue(label: "SessionQueue", attributes: [], autoreleaseFrequency: .workItem)
    
    private var videoInput: AVCaptureDeviceInput!
    
    private var audioDataOutput:AVCaptureAudioDataOutput = AVCaptureAudioDataOutput()
    
    private let dataOutputQueue = DispatchQueue(label: "VideoDataQueue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    
    private let videoDataOutput = AVCaptureVideoDataOutput()
    
    private let depthDataOutput = AVCaptureDepthDataOutput()
    
    private var outputSynchronizer: AVCaptureDataOutputSynchronizer?
    
    private let photoOutput = AVCapturePhotoOutput()
    
    private let filterRenderers: [FilterRenderer] = [EmptyRenderer(), InstaRenderer(filterName: "CIPhotoEffectChrome"), InstaRenderer(filterName: "CIPhotoEffectFade"), InstaRenderer(filterName: "CIPhotoEffectInstant"),InstaRenderer(filterName: "CIPhotoEffectMono"), InstaRenderer(filterName: "CIPhotoEffectNoir"), InstaRenderer(filterName: "CIPhotoEffectProcess"),InstaRenderer(filterName: "CIPhotoEffectTonal"), InstaRenderer(filterName: "CIPhotoEffectTransfer"), InstaRenderer(filterName: "CILinearToSRGBToneCurve"), InstaRenderer(filterName: "CISRGBToneCurveToLinear")]
    
    private let photoRenderers: [FilterRenderer] = [EmptyRenderer(), InstaRenderer(filterName: "CIPhotoEffectChrome"), InstaRenderer(filterName: "CIPhotoEffectFade"), InstaRenderer(filterName: "CIPhotoEffectInstant"),InstaRenderer(filterName: "CIPhotoEffectMono"), InstaRenderer(filterName: "CIPhotoEffectNoir"), InstaRenderer(filterName: "CIPhotoEffectProcess"),InstaRenderer(filterName: "CIPhotoEffectTonal"), InstaRenderer(filterName: "CIPhotoEffectTransfer"), InstaRenderer(filterName: "CILinearToSRGBToneCurve"), InstaRenderer(filterName: "CISRGBToneCurveToLinear")]
    
    // FOR RECORDING
    fileprivate(set) lazy var isRecording = false
    fileprivate var videoWriter: AVAssetWriter!
    fileprivate var videoWriterInput: AVAssetWriterInput!
    fileprivate var videoWriterInputPixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor!
    fileprivate var audioWriterInput: AVAssetWriterInput!
    fileprivate var sessionAtSourceTime: CMTime?
    fileprivate let writingQueue = DispatchQueue(label: "com.hilaoinc.hilao.queue.recorder.start-writing")
    public var videoSize = CGSize(width: 720, height: 1280)
    public var exportPreset = AVAssetExportPreset1280x720
    
    // NOT USING THIS
    private let videoDepthMixer = VideoMixer()
    
    // NOT USING THIS
    private let photoDepthMixer = VideoMixer()
    
    private var filterIndex: Int = 0
    
    private var videoFilter: FilterRenderer?
    
    private var photoFilter: FilterRenderer?
    
    // NOT USING THIS
    private let videoDepthConverter = DepthToGrayscaleConverter()
    
    // NOT USING THIS
    private let photoDepthConverter = DepthToGrayscaleConverter()
    
    private var currentDepthPixelBuffer: CVPixelBuffer?
    
    private var renderingEnabled = true
    
    private var depthVisualizationEnabled = false
    
    private let processingQueue = DispatchQueue(label: "photo processing queue", attributes: [], autoreleaseFrequency: .workItem)
    
    private let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera,
                                                                                             .builtInWideAngleCamera],
                                                                               mediaType: .video,
                                                                               position: .unspecified)
    
    private var statusBarOrientation: UIInterfaceOrientation = .portrait
    
    // MARK: - View Controller Life Cycle
    convenience init(metalHelper:MetalHelper) {
        self.init(nibName:nil, bundle:nil)
        self.metalHelper = metalHelper
        self.metalHelper.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mtkView.translatesAutoresizingMaskIntoConstraints = false
        mtkView.preferredFramesPerSecond = 30
        view.addSubview(mtkView)
        NSLayoutConstraint.activate([
            /*switchCameraButton.widthAnchor.constraint(equalToConstant: 30),
            switchCameraButton.heightAnchor.constraint(equalToConstant: 30),
            switchCameraButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            switchCameraButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),

            captureImageButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            captureImageButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            captureImageButton.widthAnchor.constraint(equalToConstant: 50),
            captureImageButton.heightAnchor.constraint(equalToConstant: 50),*/
           
            mtkView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            mtkView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mtkView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mtkView.topAnchor.constraint(equalTo: view.topAnchor),
            
        ])
        
        mtkView.setupView()
        // Disable UI. The UI is enabled if and only if the session starts running.
        //cameraButton.isEnabled = false
        //photoButton.isEnabled = false
        videoFilterOn = true
        //videoFilterButton.setImage(#imageLiteral(resourceName: "ColorFilterOff"), for: .normal)
        depthVisualizationOn = false
        //depthVisualizationButton.setImage(#imageLiteral(resourceName: "DepthVisualOff"), for: .normal)
        //depthVisualizationButton.isHidden = true
        depthSmoothingOn = false
        //depthSmoothingButton.setImage(#imageLiteral(resourceName: "DepthSmoothOff"), for: .normal)
        //depthSmoothingButton.isHidden = true
        //mixFactorNameLabel.isHidden = true
        //mixFactorValueLabel.isHidden = true
        //mixFactorSlider.isHidden = true
        //depthDataMaxFrameRateValueLabel.isHidden = true
        //depthDataMaxFrameRateNameLabel.isHidden = true
        //depthDataMaxFrameRateSlider.isHidden = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(focusAndExposeTap))
        mtkView.addGestureRecognizer(tapGesture)
        
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
                
                DispatchQueue.main.async {
                    self.updateDepthUIHidden()
                }
                
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
    
    @objc
    func didEnterBackground(notification: NSNotification) {
        // Free up resources.
        dataOutputQueue.async {
            self.renderingEnabled = false
            if let videoFilter = self.videoFilter {
                videoFilter.reset()
            }
            self.videoDepthMixer.reset()
            self.currentDepthPixelBuffer = nil
            self.videoDepthConverter.reset()
            self.mtkView.pixelBuffer = nil
            self.mtkView.flushTextureCache()
        }
        processingQueue.async {
            if let photoFilter = self.photoFilter {
                photoFilter.reset()
            }
            self.photoDepthMixer.reset()
            self.photoDepthConverter.reset()
        }
    }
    
    @objc
    func willEnterForground(notification: NSNotification) {
        dataOutputQueue.async {
            self.renderingEnabled = true
        }
    }
    
    // Use this opportunity to take corrective action to help cool the system down.
    @objc
    func thermalStateChanged(notification: NSNotification) {
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
                        DispatchQueue.main.async {
                            self.updateDepthUIHidden()
                        }
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
    
    // MARK: - KVO and Notifications
    
    private var sessionRunningContext = 0
    
    private func addObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(willEnterForground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(thermalStateChanged),
                                               name: ProcessInfo.thermalStateDidChangeNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sessionRuntimeError),
                                               name: NSNotification.Name.AVCaptureSessionRuntimeError,
                                               object: session)
        
        session.addObserver(self, forKeyPath: "running", options: NSKeyValueObservingOptions.new, context: &sessionRunningContext)
        
        // A session can run only when the app is full screen. It will be interrupted in a multi-app layout.
        // Add observers to handle these session interruptions and inform the user.
        // See AVCaptureSessionWasInterruptedNotification for other interruption reasons.
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sessionWasInterrupted),
                                               name: NSNotification.Name.AVCaptureSessionWasInterrupted,
                                               object: session)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sessionInterruptionEnded),
                                               name: NSNotification.Name.AVCaptureSessionInterruptionEnded,
                                               object: session)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(subjectAreaDidChange),
                                               name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange,
                                               object: videoInput.device)
    }
    
    private func removeObservers() {
        NotificationCenter.default.removeObserver(self)
        session.removeObserver(self, forKeyPath: "running", context: &sessionRunningContext)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if context == &sessionRunningContext {
            let newValue = change?[.newKey] as AnyObject?
            guard let isSessionRunning = newValue?.boolValue else { return }
            DispatchQueue.main.async {
                //self.cameraButton.isEnabled = (isSessionRunning && self.videoDeviceDiscoverySession.devices.count > 1)
                //self.photoButton.isEnabled = isSessionRunning
                //self.videoFilterButton.isEnabled = isSessionRunning
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    // MARK: - Session Management
    
    // Call this on the SessionQueue
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
        
        // Add a video input.
        guard session.canAddInput(videoInput) else {
            print("Could not add video device input to the session")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        session.addInput(videoInput)
        
        // Add microphone to your session
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
        
        // Add a video data output
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
            
            if depthVisualizationEnabled {
                if photoOutput.isDepthDataDeliverySupported {
                    photoOutput.isDepthDataDeliveryEnabled = true
                } else {
                    depthVisualizationEnabled = false
                }
            }
            
        } else {
            print("Could not add photo output to the session")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        // Add a depth data output
        if session.canAddOutput(depthDataOutput) {
            session.addOutput(depthDataOutput)
            depthDataOutput.setDelegate(self, callbackQueue: dataOutputQueue)
            depthDataOutput.isFilteringEnabled = false
            if let connection = depthDataOutput.connection(with: .depthData) {
                connection.isEnabled = depthVisualizationEnabled
            } else {
                print("No AVCaptureConnection")
            }
        } else {
            print("Could not add depth data output to the session")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        if depthVisualizationEnabled {
            // Use an AVCaptureDataOutputSynchronizer to synchronize the video data and depth data outputs.
            // The first output in the dataOutputs array, in this case the AVCaptureVideoDataOutput, is the "master" output.
            outputSynchronizer = AVCaptureDataOutputSynchronizer(dataOutputs: [videoDataOutput, depthDataOutput])
            if let unwrappedOutputSynchronizer = outputSynchronizer {
                unwrappedOutputSynchronizer.setDelegate(self, queue: dataOutputQueue)
            }
        } else {
            outputSynchronizer = nil
        }
        
        capFrameRate(videoDevice: videoDevice)
        
        //Recording AssetWriter
        self.setupWriter()
        
        session.commitConfiguration()
        
        DispatchQueue.main.async {
            /*self.depthDataMaxFrameRateValueLabel.text = String(format: "%.1f", self.depthDataMaxFrameRateSlider.value)
            self.mixFactorValueLabel.text = String(format: "%.1f", self.mixFactorSlider.value)
            self.depthDataMaxFrameRateSlider.minimumValue = Float(1) / Float(CMTimeGetSeconds(videoDevice.activeVideoMaxFrameDuration))
            self.depthDataMaxFrameRateSlider.maximumValue = Float(1) / Float(CMTimeGetSeconds(videoDevice.activeVideoMinFrameDuration))
            self.depthDataMaxFrameRateSlider.value = (self.depthDataMaxFrameRateSlider.minimumValue
                + self.depthDataMaxFrameRateSlider.maximumValue) / 2*/
        }
    }
    
    //MARK Recording Functions
    
    fileprivate func setupWriter() {
        do {
            let url = videoFileLocation()
            videoWriter = try? AVAssetWriter(url: url, fileType: AVFileType.mp4)
            
            //Add video input
            videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: videoSize.width,
                AVVideoHeightKey: videoSize.height,
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: 6000000,
                    AVVideoProfileLevelKey: AVVideoProfileLevelH264High40,
                    AVVideoExpectedSourceFrameRateKey: 60,
                    AVVideoAverageNonDroppableFrameRateKey: 30,
                ],
            ])
            
            videoWriterInputPixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput, sourcePixelBufferAttributes: [
                            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                            kCVPixelBufferWidthKey as String: videoSize.width,
                            kCVPixelBufferHeightKey as String: videoSize.height,
                            kCVPixelFormatOpenGLESCompatibility as String: true,
                            ])
            
            videoWriterInput.expectsMediaDataInRealTime = true //Make sure we are exporting data at realtime
            videoWriterInput.transform = .identity
            
            if videoWriter.canAdd(videoWriterInput) {
                videoWriter.add(videoWriterInput)
            }
            
            //Add audio input
            audioWriterInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVNumberOfChannelsKey: 1,
                AVSampleRateKey: 44100,
                AVEncoderBitRateKey: 64000,
            ])
            audioWriterInput.expectsMediaDataInRealTime = true
            if videoWriter.canAdd(audioWriterInput) {
                videoWriter.add(audioWriterInput)
                print("Audio Added To AVAssetWriter")
            } else {
                print("Audio NOT Added to AVAssetWriter")
            }
            
            //videoWriter.startWriting() //Means ready to write down the file
        }
        catch let error {
            debugPrint(error.localizedDescription)
        }
    }
    
    func videoFileLocation() -> URL {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let videoOutputUrl = URL(fileURLWithPath: documentsPath.appendingPathComponent("\(UUID()).mov"))
        do {
        if FileManager.default.fileExists(atPath: videoOutputUrl.path) {
            try FileManager.default.removeItem(at: videoOutputUrl)
            print("file removed")
        }
        } catch {
            print(error)
        }

        return videoOutputUrl
    }
    
    fileprivate func canWrite() -> Bool {
        return isRecording
            && videoWriter != nil
            && videoWriter.status == .writing
    }
    
    func startRecording() {
        print("Video Recording Started")
        guard !isRecording else { return }
        isRecording = true
        sessionAtSourceTime = nil
        videoWriter.startWriting()
    }
    
    func stopRecording() {
        guard isRecording else { return }
        isRecording = false
        writingQueue.sync { [weak self] in
            videoWriter.finishWriting { [weak self] in
                print("Video Recording Stopped")
                self?.sessionAtSourceTime = nil
                guard let url = self?.videoWriter.outputURL else { return }
                //let videoAsset = AVURLAsset(url: url)
                //var info = videoAsset.videoOrientation()
                
                /*let textViewArrayDummy:[UITextView] = []
                OverlayExport.exportLayersToVideo(url.path, textViewArrayDummy, completion:{ destination in
                    print("Process Video Completed???")
                })*/
                
                //Do whatever you want with your asset here
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                }) { saved, error in
                    if saved {
                        print("Video Saved To Camera Roll")
                    }
                }
                print("exported?")
            }
        }
    }
    
    func pauseRecording() {
        isRecording = false
    }
    
    func resumeRecording() {
        isRecording = true
    }
    
    @objc
    func sessionWasInterrupted(notification: NSNotification) {
        // In iOS 9 and later, the userInfo dictionary contains information on why the session was interrupted.
        if let userInfoValue = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as AnyObject?,
            let reasonIntegerValue = userInfoValue.integerValue,
            let reason = AVCaptureSession.InterruptionReason(rawValue: reasonIntegerValue) {
            print("Capture session was interrupted with reason \(reason)")
            
            if reason == .videoDeviceInUseByAnotherClient {
                // Simply fade-in a button to enable the user to try to resume the session running.
                resumeButton.isHidden = false
                resumeButton.alpha = 0.0
                UIView.animate(withDuration: 0.25) {
                    self.resumeButton.alpha = 1.0
                }
            } else if reason == .videoDeviceNotAvailableWithMultipleForegroundApps {
                // Simply fade-in a label to inform the user that the camera is unavailable.
                cameraUnavailableLabel.isHidden = false
                cameraUnavailableLabel.alpha = 0.0
                UIView.animate(withDuration: 0.25) {
                    self.cameraUnavailableLabel.alpha = 1.0
                }
            }
        }
    }
    
    @objc
    func sessionInterruptionEnded(notification: NSNotification) {
        /*if !resumeButton.isHidden {
            UIView.animate(withDuration: 0.25,
                           animations: {
                            self.resumeButton.alpha = 0
            }, completion: { _ in
                self.resumeButton.isHidden = true
            }
            )
        }
        if !cameraUnavailableLabel.isHidden {
            UIView.animate(withDuration: 0.25,
                           animations: {
                            self.cameraUnavailableLabel.alpha = 0
            }, completion: { _ in
                self.cameraUnavailableLabel.isHidden = true
            }
            )
        }*/
    }
    
    @objc
    func sessionRuntimeError(notification: NSNotification) {
        guard let errorValue = notification.userInfo?[AVCaptureSessionErrorKey] as? NSError else {
            return
        }
        
        let error = AVError(_nsError: errorValue)
        print("Capture session runtime error: \(error)")
        
        /*
         Automatically try to restart the session running if media services were
         reset and the last start running succeeded. Otherwise, enable the user
         to try to resume the session running.
         */
        if error.code == .mediaServicesWereReset {
            sessionQueue.async {
                if self.isSessionRunning {
                    self.session.startRunning()
                    self.isSessionRunning = self.session.isRunning
                } else {
                    DispatchQueue.main.async {
                        self.resumeButton.isHidden = false
                    }
                }
            }
        } else {
            resumeButton.isHidden = false
        }
    }
    
    @IBAction private func resumeInterruptedSession(_ sender: UIButton) {
        sessionQueue.async {
            /*
             The session might fail to start running. A failure to start the session running will be communicated via
             a session runtime error notification. To avoid repeatedly failing to start the session
             running, we only try to restart the session running in the session runtime error handler
             if we aren't trying to resume the session running.
             */
            self.session.startRunning()
            self.isSessionRunning = self.session.isRunning
            if !self.session.isRunning {
                DispatchQueue.main.async {
                    let message = NSLocalizedString("Unable to resume", comment: "Alert message when unable to resume the session running")
                    let actions = [
                        UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                      style: .cancel,
                                      handler: nil)]
                    self.alert(title: "AVCamFilter", message: message, actions: actions)
                }
            } else {
                DispatchQueue.main.async {
                    self.resumeButton.isHidden = true
                }
            }
        }
    }
    
    // MARK: - IBAction Functions
    
    /// - Tag: VaryFrameRate
    @IBAction private func changeDepthDataMaxFrameRate(_ sender: UISlider) {
        let depthDataMaxFrameRate = sender.value
        let newMinDuration = Double(1) / Double(depthDataMaxFrameRate)
        let duration = CMTimeMaximum(videoInput.device.activeVideoMinFrameDuration, CMTimeMakeWithSeconds(newMinDuration, preferredTimescale: 1000))
        
        self.depthDataMaxFrameRateValueLabel.text = String(format: "%.1f", depthDataMaxFrameRate)
        
        do {
            try self.videoInput.device.lockForConfiguration()
            self.videoInput.device.activeDepthDataMinFrameDuration = duration
            self.videoInput.device.unlockForConfiguration()
        } catch {
            print("Could not lock device for configuration: \(error)")
        }
    }
    
    /// - Tag: VaryMixFactor
    @IBAction private func changeMixFactor(_ sender: UISlider) {
        let mixFactor = sender.value
        self.mixFactorValueLabel.text = String(format: "%.1f", mixFactor)
        dataOutputQueue.async {
            self.videoDepthMixer.mixFactor = mixFactor
        }
        processingQueue.async {
            self.photoDepthMixer.mixFactor = mixFactor
        }
    }
    
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
            
            let filterDescription = filterRenderers[newIndex].description
            updateFilterLabel(description: filterDescription)
            
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
            
            self.metalHelper.swipedFilter(filterName: "F\(newIndex)")
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
    
    @objc
    func subjectAreaDidChange(notification: NSNotification) {
        let devicePoint = CGPoint(x: 0.5, y: 0.5)
        focus(with: .continuousAutoFocus, exposureMode: .continuousAutoExposure, at: devicePoint, monitorSubjectAreaChange: false)
    }
    
    func changeCamera() {
        //cameraButton.isEnabled = false
        //photoButton.isEnabled = false
        
        dataOutputQueue.sync {
            renderingEnabled = false
            if let filter = videoFilter {
                filter.reset()
            }
            videoDepthMixer.reset()
            currentDepthPixelBuffer = nil
            videoDepthConverter.reset()
            mtkView.pixelBuffer = nil
        }
        
        processingQueue.async {
            if let filter = self.photoFilter {
                filter.reset()
            }
            self.photoDepthMixer.reset()
            self.photoDepthConverter.reset()
        }
        
        let interfaceOrientation = statusBarOrientation
        var depthEnabled = depthVisualizationOn
        
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
                
                if self.photoOutput.isDepthDataDeliverySupported {
                    self.photoOutput.isDepthDataDeliveryEnabled = depthEnabled
                    if let unwrappedDepthDataOutputConnection = self.depthDataOutput.connection(with: .depthData) {
                        unwrappedDepthDataOutputConnection.isEnabled = depthEnabled
                    }
                    if depthEnabled && self.outputSynchronizer == nil {
                        self.outputSynchronizer = AVCaptureDataOutputSynchronizer(dataOutputs: [self.videoDataOutput, self.depthDataOutput])
                        if let unwrappedOutputSynchronizer = self.outputSynchronizer {
                            unwrappedOutputSynchronizer.setDelegate(self, queue: self.dataOutputQueue)
                        }
                    }
                    
                    // Cap the video framerate at the max depth framerate
                    if let frameDuration = videoDevice.activeDepthDataFormat?.videoSupportedFrameRateRanges.first?.minFrameDuration {
                        do {
                            try videoDevice.lockForConfiguration()
                            videoDevice.activeVideoMinFrameDuration = frameDuration
                            videoDevice.unlockForConfiguration()
                        } catch {
                            print("Could not lock device for configuration: \(error)")
                        }
                    }
                } else {
                    self.outputSynchronizer = nil
                    depthEnabled = false
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
                self.depthVisualizationEnabled = depthEnabled
            }
            
            DispatchQueue.main.async {
                self.updateDepthUIHidden()
                //self.cameraButton.isEnabled = true
                //self.photoButton.isEnabled = true
            }
        }
    }
    
    @IBAction private func toggleDepthVisualization() {
        depthVisualizationOn = !depthVisualizationOn
        var depthEnabled = depthVisualizationOn
        
        sessionQueue.async {
            self.session.beginConfiguration()
            
            if self.photoOutput.isDepthDataDeliverySupported {
                self.photoOutput.isDepthDataDeliveryEnabled = depthEnabled
            } else {
                depthEnabled = false
            }
            
            if let unwrappedDepthConnection = self.depthDataOutput.connection(with: .depthData) {
                unwrappedDepthConnection.isEnabled = depthEnabled
            }
            
            if depthEnabled {
                // Use an AVCaptureDataOutputSynchronizer to synchronize the video data and depth data outputs.
                // The first output in the dataOutputs array, in this case the AVCaptureVideoDataOutput, is the "master" output.
                self.outputSynchronizer = AVCaptureDataOutputSynchronizer(dataOutputs: [self.videoDataOutput, self.depthDataOutput])
                
                if let unwrappedOutputSynchronizer = self.outputSynchronizer {
                    unwrappedOutputSynchronizer.setDelegate(self, queue: self.dataOutputQueue)
                }
            } else {
                self.outputSynchronizer = nil
            }
            
            self.session.commitConfiguration()
            
            DispatchQueue.main.async {
                self.updateDepthUIHidden()
            }
            
            self.dataOutputQueue.async {
                if !depthEnabled {
                    self.videoDepthConverter.reset()
                    self.videoDepthMixer.reset()
                    self.currentDepthPixelBuffer = nil
                }
                self.depthVisualizationEnabled = depthEnabled
            }
            
            self.processingQueue.async {
                if !depthEnabled {
                    self.photoDepthMixer.reset()
                    self.photoDepthConverter.reset()
                }
            }
        }
    }
    
    /// - Tag: SmoothDepthData
    @IBAction private func toggleDepthSmoothing() {
        
        depthSmoothingOn = !depthSmoothingOn
        let smoothingEnabled = depthSmoothingOn
        
        let stateImage = UIImage(named: smoothingEnabled ? "DepthSmoothOn" : "DepthSmoothOff")
        self.depthSmoothingButton.setImage(stateImage, for: .normal)
        
        sessionQueue.async {
            self.depthDataOutput.isFilteringEnabled = smoothingEnabled
        }
    }
    
    func toggleFiltering() {
        
        videoFilterOn = !videoFilterOn
        let filteringEnabled = videoFilterOn
        
        //let stateImage = UIImage(named: filteringEnabled ? "ColorFilterOn" : "ColorFilterOff")
        //self.videoFilterButton.setImage(stateImage, for: .normal)
        
        let index = filterIndex
        
        if filteringEnabled {
            let filterDescription = filterRenderers[index].description
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
    
    func capturePhoto() {
        let depthEnabled = depthVisualizationOn
        
        sessionQueue.async {
            let photoSettings = AVCapturePhotoSettings(format: [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)])
            if depthEnabled && self.photoOutput.isDepthDataDeliverySupported {
                photoSettings.isDepthDataDeliveryEnabled = true
                photoSettings.embedsDepthDataInPhoto = false
            } else {
                photoSettings.isDepthDataDeliveryEnabled = depthEnabled
            }
            self.photoOutput.capturePhoto(with: photoSettings, delegate: self)
        }
    }
    
    // MARK: - UI Utility Functions
    
    func updateDepthUIHidden() {
        /*self.depthVisualizationButton.isHidden = !self.photoOutput.isDepthDataDeliverySupported
        self.depthVisualizationButton.setImage(UIImage(named: depthVisualizationOn ? "DepthVisualOn" : "DepthVisualOff"),
                                               for: .normal)
        self.depthSmoothingOn = depthVisualizationOn
        self.depthSmoothingButton.isHidden = !self.depthSmoothingOn
        self.depthSmoothingButton.setImage(UIImage(named: depthVisualizationOn ? "DepthSmoothOn" : "DepthSmoothOff"),
                                           for: .normal)
        self.mixFactorNameLabel.isHidden = !depthVisualizationOn
        self.mixFactorValueLabel.isHidden = !depthVisualizationOn
        self.mixFactorSlider.isHidden = !depthVisualizationOn
        self.depthDataMaxFrameRateNameLabel.isHidden = !depthVisualizationOn
        self.depthDataMaxFrameRateValueLabel.isHidden = !depthVisualizationOn
        self.depthDataMaxFrameRateSlider.isHidden = !depthVisualizationOn*/
    }
    
    func updateFilterLabel(description: String) {
        /*filterLabel.text = description
        filterLabel.alpha = 0.0
        filterLabel.isHidden = false
        
        UIView.animate(withDuration: 0.25, animations: {
            self.filterLabel.alpha = 1.0
        }) { _ in
            UIView.animate(withDuration: 0.25, delay: 1.0, options: [], animations: {
                self.filterLabel.alpha = 0.0
            }, completion: { _ in })
        }*/
    }
    
    // MARK: - Video Data Output Delegate
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        processPhoto(sampleBuffer: sampleBuffer)
        processVideo(output, sampleBuffer, connection)
    }
    
    //fat
    
    func processVideo(_ captureOutput: AVCaptureOutput!, _ sampleBuffer: CMSampleBuffer!, _ connection: AVCaptureConnection!){
        guard captureOutput != nil,
              sampleBuffer != nil,
              connection != nil,
              CMSampleBufferDataIsReady(sampleBuffer) else { return }
        
        let writable = canWrite()
        
        if writable, sessionAtSourceTime == nil {
            sessionAtSourceTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            videoWriter.startSession(atSourceTime: sessionAtSourceTime!)
        }
        
        if writable, captureOutput == videoDataOutput, videoWriterInput.isReadyForMoreMediaData {
            if let pixelBuffer = mtkView.pixelBuffer{
                //videoWriterInput.append(sampleBuffer)
                videoWriterInputPixelBufferAdaptor.append(pixelBuffer, withPresentationTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
            }
        } else if writable, captureOutput == audioDataOutput, (audioWriterInput.isReadyForMoreMediaData) {
            audioWriterInput?.append(sampleBuffer)
        }
    }
    
    func processPhoto(sampleBuffer: CMSampleBuffer) {
        if !renderingEnabled {
            return
        }
        
        guard let videoPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
            let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) else {
                return
        }
        
        var finalVideoPixelBuffer = videoPixelBuffer
        if let filter = videoFilter {
            if !filter.isPrepared {
                /*
                 outputRetainedBufferCountHint is the number of pixel buffers the renderer retains. This value informs the renderer
                 how to size its buffer pool and how many pixel buffers to preallocate. Allow 3 frames of latency to cover the dispatch_async call.
                 */
                filter.prepare(with: formatDescription, outputRetainedBufferCountHint: 3)
            }
            
            // Send the pixel buffer through the filter
            guard let filteredBuffer = filter.render(pixelBuffer: finalVideoPixelBuffer) else {
                print("Unable to filter video buffer")
                return
            }
            
            finalVideoPixelBuffer = filteredBuffer
        }
        
        if depthVisualizationEnabled {
            if !videoDepthMixer.isPrepared {
                videoDepthMixer.prepare(with: formatDescription, outputRetainedBufferCountHint: 3)
            }
            
            if let depthBuffer = currentDepthPixelBuffer {
                
                // Mix the video buffer with the last depth data received.
                guard let mixedBuffer = videoDepthMixer.mix(videoPixelBuffer: finalVideoPixelBuffer, depthPixelBuffer: depthBuffer) else {
                    print("Unable to combine video and depth")
                    return
                }
                
                finalVideoPixelBuffer = mixedBuffer
            }
        }
        
        mtkView.pixelBuffer = finalVideoPixelBuffer

        DispatchQueue.main.async {
            if !self.metalHelper.takePicture {
                return //we have nothing to do with the image buffer
            } else {
                let ciImage = CIImage(cvImageBuffer: finalVideoPixelBuffer)
                let ciContext = CIContext()
                let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent)
                let uiImage = UIImage(cgImage: cgImage!).rotate(radians: .pi/2)
                self.metalHelper.saveImageToArray(uiImage: uiImage!)
                self.metalHelper.takePicture = false
            }
        }
    }
    
    func toggleRecord() {
        if !isRecording{
            startRecording()
        } else if isRecording{
            stopRecording()
        }
    }
    
    func captureShot() {
        DispatchQueue.main.async {
            self.flashScreen()
            self.metalHelper.takePicture = true
        }
    }
    
    // MARK: - Depth Data Output Delegate
    
    /// - Tag: StreamDepthData
    func depthDataOutput(_ depthDataOutput: AVCaptureDepthDataOutput, didOutput depthData: AVDepthData, timestamp: CMTime, connection: AVCaptureConnection) {
        processDepth(depthData: depthData)
    }
    
    func processDepth(depthData: AVDepthData) {
        if !renderingEnabled {
            return
        }
        
        if !depthVisualizationEnabled {
            return
        }
        
        if !videoDepthConverter.isPrepared {
            var depthFormatDescription: CMFormatDescription?
            CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                         imageBuffer: depthData.depthDataMap,
                                                         formatDescriptionOut: &depthFormatDescription)
            if let unwrappedDepthFormatDescription = depthFormatDescription {
                videoDepthConverter.prepare(with: unwrappedDepthFormatDescription, outputRetainedBufferCountHint: 2)
            }
        }
        
        guard let depthPixelBuffer = videoDepthConverter.render(pixelBuffer: depthData.depthDataMap) else {
            print("Unable to process depth")
            return
        }
        
        currentDepthPixelBuffer = depthPixelBuffer
    }
    
    // MARK: - Video + Depth Output Synchronizer Delegate
    
    func dataOutputSynchronizer(_ synchronizer: AVCaptureDataOutputSynchronizer, didOutput synchronizedDataCollection: AVCaptureSynchronizedDataCollection) {
        
        if let syncedDepthData: AVCaptureSynchronizedDepthData = synchronizedDataCollection.synchronizedData(for: depthDataOutput) as? AVCaptureSynchronizedDepthData {
            if !syncedDepthData.depthDataWasDropped {
                let depthData = syncedDepthData.depthData
                processDepth(depthData: depthData)
            }
        }
        
        if let syncedVideoData: AVCaptureSynchronizedSampleBufferData = synchronizedDataCollection.synchronizedData(for: videoDataOutput) as? AVCaptureSynchronizedSampleBufferData {
            if !syncedVideoData.sampleBufferWasDropped {
                let videoSampleBuffer = syncedVideoData.sampleBuffer
                processPhoto(sampleBuffer: videoSampleBuffer)
            }
        }
    }
    
    // MARK: - Photo Output Delegate
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        //flashScreen()
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error)")
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let photoPixelBuffer = photo.pixelBuffer else {
            print("Error occurred while capturing photo: Missing pixel buffer (\(String(describing: error)))")
            return
        }
        
        var photoFormatDescription: CMFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                     imageBuffer: photoPixelBuffer,
                                                     formatDescriptionOut: &photoFormatDescription)
        
        processingQueue.async {
            var finalPixelBuffer = photoPixelBuffer
            if let filter = self.photoFilter {
                if !filter.isPrepared {
                    if let unwrappedPhotoFormatDescription = photoFormatDescription {
                        filter.prepare(with: unwrappedPhotoFormatDescription, outputRetainedBufferCountHint: 2)
                    }
                }
                
                guard let filteredPixelBuffer = filter.render(pixelBuffer: finalPixelBuffer) else {
                    print("Unable to filter photo buffer")
                    return
                }
                finalPixelBuffer = filteredPixelBuffer
            }
            
            if let depthData = photo.depthData {
                let depthPixelBuffer = depthData.depthDataMap
                
                if !self.photoDepthConverter.isPrepared {
                    var depthFormatDescription: CMFormatDescription?
                    CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                                 imageBuffer: depthPixelBuffer,
                                                                 formatDescriptionOut: &depthFormatDescription)
                    
                    /*
                     outputRetainedBufferCountHint is the number of pixel buffers we expect to hold on to from the renderer.
                     This value informs the renderer how to size its buffer pool and how many pixel buffers to preallocate.
                     Allow 3 frames of latency to cover the dispatch_async call.
                     */
                    if let unwrappedDepthFormatDescription = depthFormatDescription {
                        self.photoDepthConverter.prepare(with: unwrappedDepthFormatDescription, outputRetainedBufferCountHint: 3)
                    }
                }
                
                guard let convertedDepthPixelBuffer = self.photoDepthConverter.render(pixelBuffer: depthPixelBuffer) else {
                    print("Unable to convert depth pixel buffer")
                    return
                }
                
                if !self.photoDepthMixer.isPrepared {
                    if let unwrappedPhotoFormatDescription = photoFormatDescription {
                        self.photoDepthMixer.prepare(with: unwrappedPhotoFormatDescription, outputRetainedBufferCountHint: 2)
                    }
                }
                
                // Combine image and depth map
                guard let mixedPixelBuffer = self.photoDepthMixer.mix(videoPixelBuffer: finalPixelBuffer,
                                                                      depthPixelBuffer: convertedDepthPixelBuffer)
                    else {
                        print("Unable to mix depth and photo buffers")
                        return
                }
                
                finalPixelBuffer = mixedPixelBuffer
            }
            
            let metadataAttachments: CFDictionary = photo.metadata as CFDictionary
            guard let jpegData = CameraViewController.jpegData(withPixelBuffer: finalPixelBuffer, attachments: metadataAttachments) else {
                print("Unable to create JPEG photo")
                return
            }
            
            // Save JPEG to photo library
            /*PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    PHPhotoLibrary.shared().performChanges({
                        let creationRequest = PHAssetCreationRequest.forAsset()
                        creationRequest.addResource(with: .photo, data: jpegData, options: nil)
                    }, completionHandler: { _, error in
                        if let error = error {
                            print("Error occurred while saving photo to photo library: \(error)")
                        }
                    })
                }
            }*/
        }
    }
    
    // MARK: - Utilities
    private func capFrameRate(videoDevice: AVCaptureDevice) {
        if self.photoOutput.isDepthDataDeliverySupported {
            // Cap the video framerate at the max depth framerate.
            if let frameDuration = videoDevice.activeDepthDataFormat?.videoSupportedFrameRateRanges.first?.minFrameDuration {
                do {
                    try videoDevice.lockForConfiguration()
                    videoDevice.activeVideoMinFrameDuration = frameDuration
                    videoDevice.unlockForConfiguration()
                } catch {
                    print("Could not lock device for configuration: \(error)")
                }
            }
        }
    }
    
    private func focus(with focusMode: AVCaptureDevice.FocusMode, exposureMode: AVCaptureDevice.ExposureMode, at devicePoint: CGPoint, monitorSubjectAreaChange: Bool) {
        
        sessionQueue.async {
            let videoDevice = self.videoInput.device
            
            do {
                try videoDevice.lockForConfiguration()
                if videoDevice.isFocusPointOfInterestSupported && videoDevice.isFocusModeSupported(focusMode) {
                    videoDevice.focusPointOfInterest = devicePoint
                    videoDevice.focusMode = focusMode
                }
                
                if videoDevice.isExposurePointOfInterestSupported && videoDevice.isExposureModeSupported(exposureMode) {
                    videoDevice.exposurePointOfInterest = devicePoint
                    videoDevice.exposureMode = exposureMode
                }
                
                videoDevice.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                videoDevice.unlockForConfiguration()
            } catch {
                print("Could not lock device for configuration: \(error)")
            }
        }
    }
    
    func alert(title: String, message: String, actions: [UIAlertAction]) {
        let alertController = UIAlertController(title: title,
                                                message: message,
                                                preferredStyle: .alert)
        
        actions.forEach {
            alertController.addAction($0)
        }
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    // Flash the screen to signal that AVCamFilter took a photo.
    func flashScreen() {
        let flashView = UIView(frame: mtkView.frame)
        self.view.addSubview(flashView)
        flashView.backgroundColor = .black
        flashView.layer.opacity = 0.2 // 1
        UIView.animate(withDuration: 0.25, animations: {
            flashView.layer.opacity = 0
        }, completion: { _ in
            flashView.removeFromSuperview()
        })
    }
    
    private class func jpegData(withPixelBuffer pixelBuffer: CVPixelBuffer, attachments: CFDictionary?) -> Data? {
        let ciContext = CIContext()
        let renderedCIImage = CIImage(cvImageBuffer: pixelBuffer)
        guard let renderedCGImage = ciContext.createCGImage(renderedCIImage, from: renderedCIImage.extent) else {
            print("Failed to create CGImage")
            return nil
        }
        
        guard let data = CFDataCreateMutable(kCFAllocatorDefault, 0) else {
            print("Create CFData error!")
            return nil
        }
        
        guard let cgImageDestination = CGImageDestinationCreateWithData(data, kUTTypeJPEG, 1, nil) else {
            print("Create CGImageDestination error!")
            return nil
        }
        
        CGImageDestinationAddImage(cgImageDestination, renderedCGImage, attachments)
        if CGImageDestinationFinalize(cgImageDestination) {
            return data as Data
        }
        print("Finalizing CGImageDestination error!")
        return nil
    }
}

extension AVCaptureVideoOrientation {
    init?(interfaceOrientation: UIInterfaceOrientation) {
        switch interfaceOrientation {
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        case .landscapeLeft: self = .landscapeLeft
        case .landscapeRight: self = .landscapeRight
        default: return nil
        }
    }
}

extension UIImage {
    func rotate(radians: Float) -> UIImage? {
        var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
        // Trim off the extremely small float value to prevent core graphics from rounding it up
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        let context = UIGraphicsGetCurrentContext()!

        // Move origin to middle
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        // Rotate around middle
        context.rotate(by: CGFloat(radians))
        // Draw the image at its center
        self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
}

extension PreviewMetalView.Rotation {
    init?(with interfaceOrientation: UIInterfaceOrientation, videoOrientation: AVCaptureVideoOrientation, cameraPosition: AVCaptureDevice.Position) {
        /*
         Calculate the rotation between the videoOrientation and the interfaceOrientation.
         The direction of the rotation depends upon the camera position.
         */
        switch videoOrientation {
        case .portrait:
            switch interfaceOrientation {
            case .landscapeRight:
                if cameraPosition == .front {
                    self = .rotate90Degrees
                } else {
                    self = .rotate270Degrees
                }
                
            case .landscapeLeft:
                if cameraPosition == .front {
                    self = .rotate270Degrees
                } else {
                    self = .rotate90Degrees
                }
                
            case .portrait:
                self = .rotate0Degrees
                
            case .portraitUpsideDown:
                self = .rotate180Degrees
                
            default: return nil
            }
        case .portraitUpsideDown:
            switch interfaceOrientation {
            case .landscapeRight:
                if cameraPosition == .front {
                    self = .rotate270Degrees
                } else {
                    self = .rotate90Degrees
                }
                
            case .landscapeLeft:
                if cameraPosition == .front {
                    self = .rotate90Degrees
                } else {
                    self = .rotate270Degrees
                }
                
            case .portrait:
                self = .rotate180Degrees
                
            case .portraitUpsideDown:
                self = .rotate0Degrees
                
            default: return nil
            }
            
        case .landscapeRight:
            switch interfaceOrientation {
            case .landscapeRight:
                self = .rotate0Degrees
                
            case .landscapeLeft:
                self = .rotate180Degrees
                
            case .portrait:
                if cameraPosition == .front {
                    self = .rotate270Degrees
                } else {
                    self = .rotate90Degrees
                }
                
            case .portraitUpsideDown:
                if cameraPosition == .front {
                    self = .rotate90Degrees
                } else {
                    self = .rotate270Degrees
                }
                
            default: return nil
            }
            
        case .landscapeLeft:
            switch interfaceOrientation {
            case .landscapeLeft:
                self = .rotate0Degrees
                
            case .landscapeRight:
                self = .rotate180Degrees
                
            case .portrait:
                if cameraPosition == .front {
                    self = .rotate90Degrees
                } else {
                    self = .rotate270Degrees
                }
                
            case .portraitUpsideDown:
                if cameraPosition == .front {
                    self = .rotate270Degrees
                } else {
                    self = .rotate90Degrees
                }
                
            default: return nil
            }
        @unknown default:
            fatalError("Unknown orientation.")
        }
    }
}

