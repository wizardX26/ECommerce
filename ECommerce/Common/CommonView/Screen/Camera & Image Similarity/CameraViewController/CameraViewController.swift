//
//  CameraViewController.swift
//  ECommerce
//
//  Created by wizard.os25 on 13/1/26.
//  Revised by AI Assistant on 26/1/26 - Refactored to use CameraObservable
//  Updated: Support for Normal and AI Search modes

import UIKit
import AVFoundation
import CoreMotion
import PhotosUI

class CameraViewController: UIViewController, UIImagePickerControllerDelegate,
                            UINavigationControllerDelegate {

    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var rotateButton: UIButton!
    
    @IBOutlet weak var openLibrary: UIButton!
    // MARK: - Camera Mode
    private var _cameraMode: CameraMode = .normal
    
    /// Current camera mode
    var cameraMode: CameraMode {
        get { return _cameraMode }
        set {
            _cameraMode = newValue
            // Initialize ViewModel if switching to AI Search mode
            if newValue == .aiSearch && imViewModel == nil {
                imViewModel = ImageProcessingViewModel()
            }
        }
    }
    
    // MARK: - Streams
    let showCaptureHint = CameraEventStream<Void>()
    let finalImage = CameraEventStream<UIImage>() // ảnh cuối cùng sau khi dismiss
    let capturedImage = CameraEventStream<UIImage>()
    let pixelBufferStream = CameraEventStream<CVPixelBuffer>()
    
    // MARK: - AI Search Mode Only
    var imViewModel: ImageProcessingViewModel?
    
    // MARK: - Camera Components
    private(set) var previewLayer: AVCaptureVideoPreviewLayer!
    private var captureSession: AVCaptureSession!
    private var photoOutput: AVCapturePhotoOutput!
    private var videoOutput: AVCaptureVideoDataOutput? // Only for AI Search mode
    
    // MARK: - Apple's Recommended Queue Structure
    private let sessionQueue = DispatchQueue(label: "camera.session.queue", qos: .userInitiated)
    private let frameQueue = DispatchQueue(label: "camera.frame.queue", qos: .userInitiated)
    
    // MARK: - Performance Optimization
    private var isSessionReady = false
    private let sessionReadySubject = CameraEventStream<Bool>()
    
    // MARK: - Action State Management (Mutually Exclusive)
    private enum ActionState {
        case idle
        case frameProcessing
        case manualCapture
        case librarySelection
    }
    
    private var currentActionState: ActionState = .idle
    
    // MARK: - Gesture Handler
    private var gestureHandler: CameraGestureHandler?
    
    private var didAutoCapture = false
    private var manualCaptureRequested = false
    private var lastAutoImage: UIImage?
    
    // Store original library button color
    private var originalLibraryButtonTintColor: UIColor?

    let disposalBag = CameraDisposalBag()
    
    // MARK: - Initialization
    
    /// Initialize CameraViewController with specified mode
    /// - Parameter mode: Camera mode (.normal or .aiSearch)
    init(mode: CameraMode = .normal) {
        super.init(nibName: nil, bundle: nil)
        self._cameraMode = mode
        print("📷 [CameraVC] 🎬 INIT - Mode: \(mode == .aiSearch ? "AI_SEARCH" : "NORMAL")")
        
        // Initialize ViewModel if AI Search mode
        if mode == .aiSearch {
            print("📷 [CameraVC] 🤖 Initializing ImageProcessingViewModel for AI Search mode")
            self.imViewModel = ImageProcessingViewModel()
            print("📷 [CameraVC] ✅ ImageProcessingViewModel initialized")
        } else {
            print("📷 [CameraVC] 📸 Normal mode - No ViewModel needed")
        }
    }
    
    required init?(coder: NSCoder) {
        // Default to normal mode when loaded from storyboard
        // Mode can be set via cameraMode property after initialization (before viewDidLoad)
        super.init(coder: coder)
        self._cameraMode = .normal
        print("📷 [CameraVC] 🎬 INIT from Storyboard - Default mode: NORMAL")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("📷 [CameraVC] ========================================")
        print("📷 [CameraVC] 📱 viewDidLoad - Mode: \(cameraMode == .aiSearch ? "AI_SEARCH" : "NORMAL")")
        print("📷 [CameraVC] ========================================")
        
        // Setup nút capture
        self.captureButton.setTitle("", for: .normal)
        captureButton.isEnabled = true
        captureButton.isUserInteractionEnabled = true
        captureButton.isExclusiveTouch = true // Đảm bảo button nhận touch events
        captureButton.layer.cornerRadius = captureButton.frame.height / 2
        captureButton.layer.borderWidth = 5
        captureButton.layer.borderColor = UIColor.white.cgColor
        captureButton.clipsToBounds = true
        // Đảm bảo button nằm trên cùng
        view.bringSubviewToFront(captureButton)
        print("📷 [CameraVC] ✅ Capture button setup - enabled: \(captureButton.isEnabled), userInteractionEnabled: \(captureButton.isUserInteractionEnabled)")
        
        // Setup AI Search mode bindings (only if AI Search mode)
        if cameraMode == .aiSearch {
            print("📷 [CameraVC] 🤖 Setting up AI Search mode bindings...")
            if imViewModel == nil {
                print("📷 [CameraVC] ⚠️ ViewModel is nil, creating new one")
                imViewModel = ImageProcessingViewModel()
            }
            if let viewModel = imViewModel {
                print("📷 [CameraVC] ✅ ViewModel exists, setting up bindings")
                setupAISearchMode(viewModel: viewModel)
                print("📷 [CameraVC] ✅ AI Search mode bindings setup complete")
            } else {
                print("📷 [CameraVC] ❌ ERROR: ViewModel is still nil after creation!")
            }
        } else {
            print("📷 [CameraVC] 📸 Normal mode - Skipping AI Search setup")
        }
        
        rotateButton.setTitle("", for: .normal)
        rotateButton.setImage(UIImage(systemName: "arrow.trianglehead.2.clockwise.rotate.90"), for: .normal)
        rotateButton.clipsToBounds = true
        print("📷 [CameraVC] ✅ Rotate button setup")
        
        // Store original library button color
        if let libraryButton = openLibrary {
            originalLibraryButtonTintColor = libraryButton.tintColor
            print("📷 [CameraVC] 💾 Stored original library button color: \(libraryButton.tintColor?.description ?? "nil")")
        }

        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        print("📷 [CameraVC] ✅ Capture session created")

        print("📷 [CameraVC] 🔐 Checking camera permissions...")
        checkCameraPermissions()
    }
    
    // MARK: - AI Search Mode Setup
    
    private func setupAISearchMode(viewModel: ImageProcessingViewModel) {
        print("📷 [CameraVC] 🔗 Setting up stopCameraTrigger binding...")
        let stopCameraDisposable = viewModel.stopCameraTrigger
            .observeOnMain(on: self) { [weak self] _ in
                print("📷 [CameraVC] 📢✅ RECEIVED stopCameraTrigger via BIND!")
                self?.stopCamera()
                self?.currentActionState = .idle
            }
        disposalBag.add {
            stopCameraDisposable.dispose()
        }
        print("📷 [CameraVC] ✅ stopCameraTrigger binding setup (disposable retained)")
        
        print("📷 [CameraVC] 🔗 Setting up showHintTrigger binding...")
        let showHintDisposable = viewModel.showHintTrigger
            .observeOnMain(on: self) { [weak self] _ in
                print("📷 [CameraVC] 💡 showHintTrigger received - emitting showCaptureHint")
                self?.showCaptureHint.emit(())
            }
        disposalBag.add {
            showHintDisposable.dispose()
        }
        print("📷 [CameraVC] ✅ showHintTrigger binding setup (disposable retained)")
        
        print("📷 [CameraVC] 🔗 Setting up showCaptureHint observer...")
        // Subscribe để cập nhật UI khi nhận signal
        let showCaptureHintDisposable = showCaptureHint
            .observeOnMain(on: self) { [weak self] _ in
                print("📷 [CameraVC] 💡 showCaptureHint received - animating button")
                guard let self = self else { return }
                // Reset state về idle khi show hint để cho phép manual capture
                self.currentActionState = .idle
                self.animationCaptureBtnHint()
            }
        disposalBag.add {
            showCaptureHintDisposable.dispose()
        }
        print("📷 [CameraVC] ✅ showCaptureHint observer setup (disposable retained)")
    
        print("📷 [CameraVC] 🔗 Setting up pixelBufferStream forwarding...")
        let disposable = pixelBufferStream
            .observe(on: self) { [weak self] buffer in
                let width = CVPixelBufferGetWidth(buffer)
                let height = CVPixelBufferGetHeight(buffer)
                print("📷 [CameraVC] 📹 Frame received in observer: \(width)x\(height) - forwarding to ViewModel")
                self?.imViewModel?.pixelBufferStream.emit(buffer)
                print("📷 [CameraVC] ✅ Frame forwarded to ViewModel.pixelBufferStream")
            }
        // Keep disposable alive
        disposalBag.add {
            disposable.dispose()
        }
        print("📷 [CameraVC] ✅ pixelBufferStream forwarding setup (disposable retained)")

        print("📷 [CameraVC] 🔗 Setting up searchTrigger observer...")
        // Forward auto-selected frame and remember last frame for final oriented display
        let searchTriggerDisposable = viewModel.searchTrigger
            .observeOnMain(on: self) { [weak self] image in
                guard let self = self else { return }
                print("📷 [CameraVC] 🎯 searchTrigger received - Image size: \(image.size)")
                self.currentActionState = .frameProcessing
                print("📷 [CameraVC] 📤 Emitting capturedImage")
                self.capturedImage.emit(image)
                
                // Change library button color to indicate AI result found
                self.updateLibraryButtonColorForAIResult()
            }
        // Keep disposable alive
        disposalBag.add {
            searchTriggerDisposable.dispose()
        }
        print("📷 [CameraVC] ✅ searchTrigger observer setup (disposable retained)")
        print("📷 [CameraVC] ✅ All AI Search mode bindings complete!")
    }
    
    deinit {
        print("[Camera] 🧹 Deinit - cleaning up")
        captureSession?.stopRunning()
        MotionManager.share.stopDeviceMotionUpdates()
        
        // Cleanup gesture handler
        gestureHandler?.cleanup()
        gestureHandler = nil
        
        // Cleanup observables
        showCaptureHint.remove(observer: self)
        finalImage.remove(observer: self)
        capturedImage.remove(observer: self)
        pixelBufferStream.remove(observer: self)
    }
    
    private func stopCameraSession() {
        /// Chỉ dừng capture session, không dismiss view controller
        if captureSession != nil && captureSession.isRunning {
            captureSession.stopRunning()
            print("[Camera VC] 🛑 Camera session stopped by ViewModel request")
        }
        
        // Dừng motion updates
        MotionManager.share.stopDeviceMotionUpdates()
    }
    
    func stopCamera() {
        print("📷 [CameraVC] ========================================")
        print("📷 [CameraVC] 🛑 stopCamera() called")
        print("📷 [CameraVC] ========================================")
        
        /// Dừng session ngay lập tức
        if captureSession != nil && captureSession.isRunning {
            captureSession.stopRunning()
            print("📷 [CameraVC] ✅ Camera session stopped")
        } else {
            print("📷 [CameraVC] ⚠️ Camera session already stopped or nil")
        }
        
        // Dừng motion updates
        print("📷 [CameraVC] 🧭 Stopping MotionManager...")
        MotionManager.share.stopDeviceMotionUpdates()
        print("📷 [CameraVC] ✅ MotionManager stopped")
        
        // Dismiss nhẹ nhàng sau 0.66s
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            print("📷 [CameraVC] 🎬 Starting fade out animation (0.66s)...")
            // Animation fade out trong 0.66s
            UIView.animate(withDuration: 0.66, animations: {
                self.view.alpha = 0
                self.view.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            }) { _ in
                // Emit final image (display-only) before dismiss
                if let image = self.lastAutoImage {
                    print("📷 [CameraVC] 📤 Emitting finalImage: \(image.size)")
                    self.finalImage.emit(image)
                } else {
                    print("📷 [CameraVC] ⚠️ No lastAutoImage to emit")
                }
                // Dismiss ngay lập tức sau animation
                print("📷 [CameraVC] 🚪 Dismissing camera view controller...")
                self.dismiss(animated: false) {
                    print("📷 [CameraVC] ✅ Camera dismissed successfully")
                }
            }
        }
    }

    func animationCaptureBtnHint(repeatCount: Int = 3) {
        captureButton.isHidden = false
        captureButton.isEnabled = true // Đảm bảo button được enable
        captureButton.isUserInteractionEnabled = true // Đảm bảo button có thể nhận touch
        captureButton.layer.borderColor = UIColor.white.cgColor
        captureButton.transform = .identity
        
        let pulseAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
        pulseAnimation.values = [1.0, 1.3, 0.9, 1.05, 1.0]
        pulseAnimation.keyTimes = [0, 0.25, 0.5, 0.75, 1]
        pulseAnimation.duration = 0.8
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        pulseAnimation.repeatCount = Float(repeatCount)
        
        captureButton.layer.add(pulseAnimation, forKey: "pulseHint")
    }

    // MARK: - Actions
    @IBAction @objc func captureButtonTapped(_ sender: Any) {
        print("📷 [CameraVC] ========================================")
        print("📷 [CameraVC] 📸 captureButtonTapped called!")
        print("📷 [CameraVC] 📸 Current state: \(currentActionState)")
        print("📷 [CameraVC] 📸 Button enabled: \(captureButton.isEnabled)")
        print("📷 [CameraVC] 📸 Button userInteractionEnabled: \(captureButton.isUserInteractionEnabled)")
        print("📷 [CameraVC] 📸 Manual capture requested: \(manualCaptureRequested)")
        print("📷 [CameraVC] ========================================")
        
        // Prevent multiple taps - disable button temporarily
        guard !manualCaptureRequested else {
            print("📷 [CameraVC] ⚠️ Manual capture already in progress, ignoring tap")
            return
        }
        
        // Cho phép chụp thủ công ngay cả khi đang ở frameProcessing (sau auto detection)
        // Reset state về idle nếu đang ở frameProcessing để cho phép manual capture
        if currentActionState == .frameProcessing {
            print("📷 [CameraVC] ⚠️ State is frameProcessing, resetting to idle to allow manual capture")
            currentActionState = .idle
        }
        
        // Kiểm tra state - chỉ cho phép chụp khi idle hoặc manualCapture (nếu đang retry)
        // Nếu state không đúng, force reset về idle để cho phép capture
        if currentActionState != .idle && currentActionState != .manualCapture {
            print("📷 [CameraVC] 🚫 Cannot capture - action in progress: \(currentActionState)")
            // Force reset state để cho phép capture
            print("📷 [CameraVC] ⚠️ Force resetting state to idle")
            currentActionState = .idle
        }
        
        print("📷 [CameraVC] ✅ Allowing manual capture")
        currentActionState = .manualCapture
        
        // Disable button temporarily to prevent multiple taps
        captureButton.isEnabled = false
        
        capturePhoto(manual: true)
        
        // Re-enable button after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.captureButton.isEnabled = true
        }
    }

    @IBAction func libraryBtnTapped(_ sender: Any) {
        openPhotoLibrary()
    }
    
    @IBAction func rotateBtnTapped(_ sender: Any) {
        switchCamera()
    }
    
    // MARK: - Camera lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        print("📷 [CameraVC] ========================================")
        print("📷 [CameraVC] 👁️ viewWillAppear - Mode: \(cameraMode == .aiSearch ? "AI_SEARCH" : "NORMAL")")
        print("📷 [CameraVC] ========================================")
        
        didAutoCapture = false
        manualCaptureRequested = false
        // Reset action state về idle khi view appear để đảm bảo button có thể tap
        currentActionState = .idle
        // Đảm bảo capture button luôn enabled và có thể tương tác
        captureButton.isEnabled = true
        captureButton.isUserInteractionEnabled = true

        print("📷 [CameraVC] 🧭 Starting MotionManager for orientation tracking...")
        MotionManager.share.startMonitoringOrientation()
        print("📷 [CameraVC] ✅ MotionManager started")
        
        // Only set cameraStartTime for AI Search mode
        if cameraMode == .aiSearch {
            let startTime = Date()
            imViewModel?.cameraStartTime = startTime
            print("📷 [CameraVC] ⏰ Set cameraStartTime for AI Search: \(startTime)")
        }
        
        // Apple's recommended approach: Use dedicated session queue
        if self.captureSession?.isRunning == false {
            print("📷 [CameraVC] 📹 Camera session not running, starting...")
            // Setup preview layer trước khi start session để tránh màn hình trắng
            setupPreviewLayer()
            
            sessionQueue.async { [weak self] in
                guard let self = self else { return }
                print("📷 [CameraVC] 🎬 Starting capture session on background queue...")
                self.captureSession.startRunning()
                
                // Wait for session to be ready
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                    self?.isSessionReady = true
                    self?.sessionReadySubject.emit(true)
                    print("📷 [CameraVC] ✅ Session ready after 0.05s")
                }
                
                DispatchQueue.main.async {
                    print("📷 [CameraVC] ✅ Started capture session on dedicated queue")
                    print("📷 [CameraVC] 📹 Camera is now RUNNING and ready to receive frames")
                }
            }
        } else {
            print("📷 [CameraVC] ⚠️ Camera session already running")
        }
        
        if gestureHandler == nil {
            print("📷 [CameraVC] 👆 Creating gesture handler...")
            gestureHandler = CameraGestureHandler(cameraViewController: self)
            print("📷 [CameraVC] ✅ Gesture handler created")
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        print("📷 [CameraVC] ========================================")
        print("📷 [CameraVC] 👁️ viewDidAppear - Ensuring button is setup correctly")
        print("📷 [CameraVC] ========================================")
        
        // Đảm bảo button được setup đúng sau khi view đã layout
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Đảm bảo button nằm trên cùng
            self.view.bringSubviewToFront(self.captureButton)
            
            // Đảm bảo button có thể nhận touch events
            self.captureButton.isEnabled = true
            self.captureButton.isUserInteractionEnabled = true
            self.captureButton.isExclusiveTouch = true
            
            // Thêm programmatic action như backup
            self.captureButton.removeTarget(nil, action: nil, for: .touchUpInside)
            self.captureButton.addTarget(self, action: #selector(self.captureButtonTapped(_:)), for: .touchUpInside)
            
            // Log button state
            print("📷 [CameraVC] 📱 Capture button frame: \(self.captureButton.frame)")
            print("📷 [CameraVC] 📱 Capture button bounds: \(self.captureButton.bounds)")
            print("📷 [CameraVC] 📱 Capture button enabled: \(self.captureButton.isEnabled)")
            print("📷 [CameraVC] 📱 Capture button userInteractionEnabled: \(self.captureButton.isUserInteractionEnabled)")
            print("📷 [CameraVC] 📱 Capture button alpha: \(self.captureButton.alpha)")
            print("📷 [CameraVC] 📱 Capture button hidden: \(self.captureButton.isHidden)")
            
            // Test touch bằng cách thêm tap gesture recognizer như backup
            // Remove existing gesture recognizers first
            if let gestures = self.captureButton.gestureRecognizers {
                for gesture in gestures {
                    if gesture is UITapGestureRecognizer {
                        self.captureButton.removeGestureRecognizer(gesture)
                    }
                }
            }
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleCaptureButtonTap(_:)))
            tapGesture.numberOfTapsRequired = 1
            self.captureButton.addGestureRecognizer(tapGesture)
            print("📷 [CameraVC] ✅ Added tap gesture recognizer as backup")
        }
    }
    
    @objc private func handleCaptureButtonTap(_ gesture: UITapGestureRecognizer) {
        print("📷 [CameraVC] 🎯 Tap gesture recognized on capture button!")
        captureButtonTapped(captureButton)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // CHỈ stop session và motion, KHÔNG reset ViewModel state
        MotionManager.share.stopDeviceMotionUpdates()

        // Apple's recommended approach: Stop session on dedicated queue
        sessionQueue.async { [weak self] in
            guard let self = self, self.captureSession?.isRunning == true else { return }
            self.captureSession.stopRunning()
            DispatchQueue.main.async {
                print("[Camera] 📷 Stopped capture session on dedicated queue")
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = previewView.bounds
    }

    // MARK: - Permissions & Setup
    private func checkCameraPermissions() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        print("📷 [CameraVC] 🔐 Camera permission status: \(status.rawValue)")
        
        switch status {
        case .notDetermined:
            print("📷 [CameraVC] ⏳ Permission not determined - requesting...")
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                print("📷 [CameraVC] 🔐 Permission request result: \(granted ? "GRANTED" : "DENIED")")
                guard granted else {
                    print("📷 [CameraVC] ❌ Camera permission DENIED")
                    return
                }
                DispatchQueue.main.async {
                    print("📷 [CameraVC] ✅ Permission granted - setting up camera...")
                    self?.setUpCamera()
                }
            }
        case .authorized:
            print("📷 [CameraVC] ✅ Camera permission already authorized")
            setUpCamera()
        case .denied:
            print("📷 [CameraVC] ❌ Camera permission DENIED")
        case .restricted:
            print("📷 [CameraVC] ⚠️ Camera permission RESTRICTED")
        @unknown default:
            print("📷 [CameraVC] ⚠️ Unknown camera permission status")
        }
    }

    private func setUpCamera() {
        guard photoOutput == nil else {
            print("📷 [CameraVC] ⚠️ Camera already setup, skipping...")
            return
        }

        print("📷 [CameraVC] ========================================")
        print("📷 [CameraVC] 🔧 Setting up camera...")
        print("📷 [CameraVC] ========================================")

        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }

        // Input
        print("📷 [CameraVC] 📹 Getting default video device...")
        guard let device = AVCaptureDevice.default(for: .video) else {
            print("📷 [CameraVC] ❌ ERROR: Cannot get default video device")
            return
        }
        print("📷 [CameraVC] ✅ Got video device: \(device.localizedName)")
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                print("📷 [CameraVC] ✅ Added camera input")
            } else {
                print("📷 [CameraVC] ❌ Cannot add camera input")
            }
        } catch {
            print("📷 [CameraVC] ❌ Camera input error: \(error)")
            return
        }

        // Photo output (always needed)
        print("📷 [CameraVC] 📸 Setting up photo output...")
        let photo = AVCapturePhotoOutput()
        photo.isHighResolutionCaptureEnabled = true
        if captureSession.canAddOutput(photo) {
            captureSession.addOutput(photo)
            photoOutput = photo
            print("📷 [CameraVC] ✅ Photo output added")
        } else {
            print("📷 [CameraVC] ❌ Cannot add photo output")
        }

        // Video data output (only for AI Search mode)
        if cameraMode == .aiSearch {
            print("📷 [CameraVC] 🤖 AI Search mode - Setting up video output for frame processing...")
            let video = AVCaptureVideoDataOutput()
            video.alwaysDiscardsLateVideoFrames = true
            video.setSampleBufferDelegate(self, queue: frameQueue)
            if captureSession.canAddOutput(video) {
                captureSession.addOutput(video)
                videoOutput = video
                print("📷 [CameraVC] ✅ Video output added for AI processing")
                print("📷 [CameraVC] 📹 Video frames will be processed on queue: \(frameQueue.label)")
            } else {
                print("📷 [CameraVC] ❌ Cannot add video output")
            }
        } else {
            print("📷 [CameraVC] 📸 Normal mode - Skipping video output setup")
        }

        print("📷 [CameraVC] ✅ Camera setup complete!")
        DispatchQueue.main.async { [weak self] in
            self?.setupPreviewLayer()
        }
    }

    private func setupPreviewLayer() {
        guard previewLayer == nil else {
            print("📷 [CameraVC] ⚠️ Preview layer already exists, updating frame")
            previewLayer.frame = previewView.bounds
            return
        }
        print("📷 [CameraVC] 📱 Setting up preview layer...")
        // Apple's recommended approach: Setup preview layer ngay lập tức
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = previewView.bounds
        previewLayer.videoGravity = .resizeAspectFill
        if let connection = previewLayer.connection {
            let orientation = MotionManager.share.getOrientation()
            connection.videoOrientation = orientation
            print("📷 [CameraVC] ✅ Preview layer orientation set: \(orientation.rawValue)")
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.previewView.layer.insertSublayer(self.previewLayer, at: 0)
            // Đảm bảo tất cả buttons nằm trên cùng
            self.view.bringSubviewToFront(self.captureButton)
            if let rotateButton = self.rotateButton {
                self.view.bringSubviewToFront(rotateButton)
            }
            if let libraryButton = self.openLibrary {
                self.view.bringSubviewToFront(libraryButton)
            }
            self.previewView.layer.masksToBounds = true
            
            // Đảm bảo button có thể nhận touch events
            self.captureButton.isEnabled = true
            self.captureButton.isUserInteractionEnabled = true
            self.captureButton.isExclusiveTouch = true
            
            // Thêm programmatic action như backup nếu IBAction không hoạt động
            self.captureButton.removeTarget(nil, action: nil, for: .touchUpInside)
            self.captureButton.addTarget(self, action: #selector(self.captureButtonTapped(_:)), for: .touchUpInside)
            
            print("📷 [CameraVC] ✅ Preview layer added on main thread")
            print("📷 [CameraVC] 📱 Preview view bounds: \(self.previewView.bounds)")
            print("📷 [CameraVC] 📱 Capture button frame: \(self.captureButton.frame)")
            print("📷 [CameraVC] 📱 Capture button superview: \(self.captureButton.superview?.description ?? "nil")")
            print("📷 [CameraVC] 📱 Capture button enabled: \(self.captureButton.isEnabled)")
            print("📷 [CameraVC] 📱 Capture button userInteractionEnabled: \(self.captureButton.isUserInteractionEnabled)")
        }
    }

    // MARK: - Capture Photo
    private func capturePhoto(manual: Bool = false) {
        guard let photoOutput = photoOutput else {
            print("📷 [CameraVC] ⚠️ Photo output is nil")
            return
        }
        
        // Kiểm tra xem đã có request đang chờ chưa (đặc biệt cho manual capture)
        if manual && manualCaptureRequested {
            print("📷 [CameraVC] ⚠️ Manual capture already requested, skipping duplicate")
            return
        }
        
        // Kiểm tra state để tránh capture khi đang xử lý
        if currentActionState == .manualCapture && manualCaptureRequested {
            print("📷 [CameraVC] ⚠️ Already capturing, skipping duplicate request")
            return
        }
        
        print("📷 [CameraVC] 📸 Starting photo capture...")
        let settings = AVCapturePhotoSettings()
        settings.isHighResolutionPhotoEnabled = true
        if let connection = photoOutput.connection(with: .video) {
            connection.videoOrientation = MotionManager.share.getOrientation()
        }
        if manual { 
            manualCaptureRequested = true
            print("📷 [CameraVC] ✅ Manual capture requested flag set")
        }
        photoOutput.capturePhoto(with: settings, delegate: self)
        print("📷 [CameraVC] ✅ Photo capture request sent")
    }

    // MARK: - Camera control
    private func switchCamera() {
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }

        if let currentInput = captureSession.inputs.first as? AVCaptureDeviceInput {
            captureSession.removeInput(currentInput)
            let newPosition: AVCaptureDevice.Position = currentInput.device.position == .back ? .front : .back
            if let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
               let newInput = try? AVCaptureDeviceInput(device: newDevice),
               captureSession.canAddInput(newInput) {
                captureSession.addInput(newInput)
            }
        }
    }

    // MARK: - Library picker
    private func openPhotoLibrary() {
        // Kiểm tra state - chỉ cho phép mở library khi idle
        guard currentActionState == .idle else {
            print("[Library] 🚫 Cannot open library - action in progress: \(currentActionState)")
            return
        }
        
        print("[Library] 📚 Opening photo library...")
        
        // Chuyển sang library state
        currentActionState = .librarySelection
        
        // Tạm dừng frame processing (only for AI Search mode)
        if cameraMode == .aiSearch {
            imViewModel?.isProcessingModel.accept(true)
        }
        
        if #available(iOS 14, *) {
            var config = PHPickerConfiguration()
            config.filter = .images
            config.selectionLimit = 1
            let picker = PHPickerViewController(configuration: config)
            picker.delegate = self
            present(picker, animated: true, completion: nil)
        } else {
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            present(picker, animated: true, completion: nil)
        }
    }
    
    func stopStreaming() {
        if captureSession.isRunning {
            captureSession.stopRunning()
            print("[Camera] 🛑 Camera streaming stopped")
        }
    }
    
    // MARK: - UI Updates
    
    /// Update library button color when AI result is found
    private func updateLibraryButtonColorForAIResult() {
        guard let libraryButton = openLibrary else {
            print("📷 [CameraVC] ⚠️ Library button outlet is nil")
            return
        }
        
        print("📷 [CameraVC] 🎨 Changing library button color to indicate AI result...")
        
        // Change to green color to indicate success
        UIView.animate(withDuration: 0.3, animations: {
            libraryButton.tintColor = .systemGreen
        }) { _ in
            print("📷 [CameraVC] ✅ Library button color changed to green")
        }
    }
    
    /// Reset library button color to original
    private func resetLibraryButtonColor() {
        guard let libraryButton = openLibrary else { return }
        
        if let originalColor = originalLibraryButtonTintColor {
            UIView.animate(withDuration: 0.3) {
                libraryButton.tintColor = originalColor
            }
            print("📷 [CameraVC] 🔄 Library button color reset to original")
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        if let error = error {
            print("📷 [CameraVC] ❌ Error processing photo: \(error)")
            print("📷 [CameraVC] Error domain: \((error as NSError).domain)")
            print("📷 [CameraVC] Error code: \((error as NSError).code)")
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.manualCaptureRequested = false
                self.currentActionState = .idle
                // Re-enable button on error
                self.captureButton.isEnabled = true
            }
            return
        }
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            print("📷 [CameraVC] ⚠️ Failed to get image data from photo")
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.manualCaptureRequested = false
                self.currentActionState = .idle
                // Re-enable button on error
                self.captureButton.isEnabled = true
            }
            return
        }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // In normal mode, dismiss immediately after capture
            if self.cameraMode == .normal {
                self.capturedImage.emit(image)
                if self.manualCaptureRequested {
                    self.manualCaptureRequested = false
                    self.dismiss(animated: true)
                }
            } else {
                // AI Search mode: gửi ảnh đến classifyTrigger để AI classification
                print("📷 [CameraVC] 📸 Manual capture in AI Search mode - sending to classifyTrigger")
                
                // Gửi ảnh đến classifyTrigger để AI classification
                if let viewModel = self.imViewModel {
                    print("📷 [CameraVC] 🤖 Sending image to classifyTrigger for AI classification")
                    viewModel.classifyTrigger.emit(image)
                    
                    // Emit capturedImage để trigger callback (nếu có)
                    self.capturedImage.emit(image)
                    
                    // Không dismiss camera ngay, đợi kết quả classification
                    // Kết quả sẽ được xử lý bởi topLabels observer trong CameraHelper
                    // Camera sẽ được dismiss trong onLabelsDetected callback
                } else {
                    print("⚠️ [CameraVC] ViewModel not found, cannot classify image")
                    // Fallback: emit capturedImage và dismiss nếu không có viewModel
                    self.capturedImage.emit(image)
                    if self.manualCaptureRequested {
                        self.manualCaptureRequested = false
                        self.currentActionState = .idle
                        // Re-enable button
                        self.captureButton.isEnabled = true
                        self.dismiss(animated: true)
                    }
                }
            }
        }
    }
}
    
// MARK: - PHPickerViewControllerDelegate
extension CameraViewController: PHPickerViewControllerDelegate {
    @available(iOS 14, *)
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let itemProvider = results.first?.itemProvider, itemProvider.canLoadObject(ofClass: UIImage.self) else { return }
        itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            if let image = object as? UIImage {
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.capturedImage.emit(image)
                    if self.cameraMode == .aiSearch {
                        self.stopCamera()
                    } else {
                        self.dismiss(animated: true)
                    }
                }
            }
        }
    }
    
    // UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            print("[Library] 📚 Selected image from library")
            
            picker.dismiss(animated: true) { [weak self] in
                guard let self = self else { return }
                self.capturedImage.emit(image)
                self.currentActionState = .idle
                
                if self.cameraMode == .aiSearch {
                    self.stopCamera()
                } else {
                    self.dismiss(animated: true)
                }
            }
        } else {
            // User cancel library - reset state
            picker.dismiss(animated: true) { [weak self] in
                print("[Library] 📚 User cancelled library selection")
                self?.currentActionState = .idle
                if self?.cameraMode == .aiSearch {
                    self?.imViewModel?.isProcessingModel.accept(false)
                }
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) { [weak self] in
            print("[Library] 📚 User cancelled library selection")
            self?.currentActionState = .idle
            if let self = self, self.cameraMode == .aiSearch {
                self.imViewModel?.isProcessingModel.accept(false)
            }
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        // Only process frames in AI Search mode
        guard cameraMode == .aiSearch else {
            // Log only first few times to avoid spam
            var logCount = 0
            if logCount < 1 {
                print("📷 [CameraVC] 📹 Frame received but mode is NORMAL - ignoring")
                logCount += 1
            }
            return
        }
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("📷 [CameraVC] ❌ Cannot get pixel buffer from sample buffer")
            return
        }
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let format = CVPixelBufferGetPixelFormatType(pixelBuffer)
        
        // Log first few frames to confirm streaming
        struct FrameCounter {
            static var count = 0
        }
        FrameCounter.count += 1
        let frameCount = FrameCounter.count
        
        if frameCount <= 10 || frameCount % 30 == 0 {
            print("📷 [CameraVC] 📹 Frame #\(frameCount) received: \(width)x\(height), format: \(format)")
        }
        
        print("📷 [CameraVC] 📤 Emitting pixelBuffer to pixelBufferStream...")
        pixelBufferStream.emit(pixelBuffer)
        print("📷 [CameraVC] ✅ pixelBuffer emitted (frame #\(frameCount))")
    }
}
