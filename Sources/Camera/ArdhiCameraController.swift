//
//  ArdhiCameraController.swift
//  Gallery-iOS
//
//  Created by Muhammed Azharudheen on 4/21/19.
//  Copyright © 2019 Hyper Interaktiv AS. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMotion

class ArdhiCameraController: UIViewController {
    
    var timer: Timer?
    var time: Int = 0 {
        didSet {
            labelTimer.text = time.timerString()
        }
    }
    
    private lazy var timerView = makeTimerview()
    private lazy var labelTimer = makeTimerLabel()
    
    var manager: CameraManager?
    var orientationLast = UIInterfaceOrientation.portrait {
        didSet {
            updateCameraViewOrientation()
        }
    }
    var motionManager: CMMotionManager?
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    convenience init(cart: Cart) {
        self.init(nibName: nil, bundle: nil)
        self.cart = cart
    }
    
    var cart = Cart()
    
    var mediaType: MediaType = .camera {
        didSet {
            viewBottom.mediaType = mediaType
            manager?.mediaType = mediaType
            timerView.isHidden = !(mediaType == .video)
        }
    }

    lazy var viewBottom = makeBottomView()
    lazy var viewPreview = makePreviewView()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMotionManager()
        setupViews()
        setupActions()
        
        if Permission.Camera.status != .authorized {
            Permission.Camera.request { [weak self] in
                guard Permission.Camera.status == .authorized else {
                    DispatchQueue.main.async { [weak self] in
                        guard let strongSelf = self else { return }
                        Alert.shared.show(from: strongSelf, mode: .camera)
                    }
                    return
                }
                self?.setupCamera()
            }
        } else {
            setupCamera()
        }
    }
    
    func setupCamera() {
        DispatchQueue.global().async {
            self.setupCameraManager()
            DispatchQueue.main.async { [weak self] in
                self?.setupCameraManagerActions()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        manager?.stop()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        manager?.updateFrame()
    }
}

private extension ArdhiCameraController {
    func setupViews() {
        
        view.addSubview(viewBottom)
        viewBottom.g_pin(on: .left)
        viewBottom.g_pin(on: .right)
        viewBottom.g_pin(on: .bottom)
        viewBottom.g_pin(height: 101)
        
        view.addSubview(viewPreview)
        viewPreview.g_pin(on: .left)
        viewPreview.g_pin(on: .top)
        viewPreview.g_pin(on: .right)
        viewPreview.g_pin(on: .bottom, view: viewBottom, on: .top)
        
        view.addSubview(timerView)
        timerView.g_pin(height: 30)
        timerView.g_pin(on: .left)
        timerView.g_pin(on: .top)
        timerView.g_pin(on: .right)
        
        timerView.addSubview(labelTimer)
        labelTimer.g_pinCenter()
        
    }
}

private extension ArdhiCameraController {
    
    func makePreviewView() -> UIView {
        let view = UIView()
        return view
    }
    
    func makeBottomView() -> CameraBottomView {
        let view = CameraBottomView()
        return view
    }
    
    func makeTimeLabel() -> UILabel {
        let lbl = UILabel()
        return lbl
    }
    
    func makeTimerview() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        return view
    }
    
    func makeTimerLabel() -> UILabel {
        let label = UILabel()
        label.text = "00:00:00"
        label.textColor = .white
        label.backgroundColor = .clear
        return label
    }
}

private extension ArdhiCameraController {
    
    func setupActions() {
        
        viewBottom.didTapbuttonFlash = { [unowned self] sender in
            print(sender.isSelected)
            sender.isSelected = !sender.isSelected
            print(sender.isSelected)
            self.manager?.isFlashEnabled = sender.isSelected
        }
        
        viewBottom.didTapCamera = { [unowned self] sender in
            self.manager?.capturePhoto()
        }
        
        viewBottom.didTapCaptureVideo = { [unowned self] sender in
            self.manageTimer()
            self.manager?.captureVideo()
        }
        
        viewBottom.didTapToggleCamera = { [unowned self] sender in
            self.manager?.cameraPosition.toggle()
        }
    }
    
    func manageTimer() {
        if let timer = timer, timer.isValid {
            timer.invalidate()
        } else {
            time = 0
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { _ in
                self.time += 1
            })
        }
    }
}

extension ArdhiCameraController: PageAware {
    func pageDidShow() { }
    
    func setupCameraManager() {
        manager = CameraManager(previewView: viewPreview)
    }
    
    func setupCameraManagerActions() {
        manager?.didCapturedPhoto = { [weak self] image, error in
            guard let image = image else { return }
            self?.cart.reset()
            self?.cart.image = image
            EventHub.shared.capturedImage?()
        }
        manager?.didStartedVideoCapturing = { [weak self] in
            self?.viewBottom.mode = .disabled
        }
        manager?.didCapturedVideo = { [weak self] url, error in
            guard let welf = self, let url = url, welf.mediaType == .video else { return }
            self?.viewBottom.mode = .enabled
            welf.cart.reset()
            welf.cart.url = url
            EventHub.shared.capturedVideo?()
            self?.time = 0
        }
        
        manager?.isFlashAvailable = { [weak self] flashAvailable in
            guard let welf = self else { return }
            welf.viewBottom.shouldHideFlashButton = !flashAvailable
        }
    }
}

extension ArdhiCameraController {
    enum MediaType {
        case camera
        case video
        case gallery
    }
}

extension UIViewController {
    func dismissController() {
        dismiss(animated: true)
    }
}

private extension ArdhiCameraController {
    
    func setupMotionManager() {
        motionManager = CMMotionManager()
        motionManager?.accelerometerUpdateInterval = 0.2
        motionManager?.gyroUpdateInterval = 0.2
        
        if let current = OperationQueue.current {
            motionManager?.startAccelerometerUpdates(to: current, withHandler: {
                (accelerometerData, error) -> Void in
                if error == nil, let acceleration = accelerometerData?.acceleration {
                    self.outputAccelertionData(acceleration)
                }
                else {
                    print("\(error?.localizedDescription ?? "Accelerometerdata error")")
                }
            })
        }
    }
    
    func outputAccelertionData(_ acceleration: CMAcceleration) {
        var orientationNew: UIInterfaceOrientation
        if acceleration.x >= 0.75 {
            orientationNew = .landscapeLeft
        }
        else if acceleration.x <= -0.75 {
            orientationNew = .landscapeRight
        }
        else if acceleration.y <= -0.75 {
            orientationNew = .portrait
        }
        else if acceleration.y >= 0.75 {
            orientationNew = .portraitUpsideDown
        } else {
            return
        }
        
        if orientationNew == orientationLast {
            return
        }
        
        orientationLast = orientationNew
    }
    
    func updateCameraViewOrientation() {
        manager?.capturedOrientation = orientationLast
        viewBottom.orientation = orientationLast
    }
}
