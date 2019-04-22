//
//  ArdhiCameraController.swift
//  Gallery-iOS
//
//  Created by Muhammed Azharudheen on 4/21/19.
//  Copyright © 2019 Hyper Interaktiv AS. All rights reserved.
//

import UIKit
import Photos

class ArdhiCameraController: UIViewController, PageAware {
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var viewBottom = makeBottomView()
    private lazy var viewPreview = makePreviewView()
    
    public typealias MediaDidSelectedBlock = (UIImage?, URL?, MediaType) -> Void
    var mediaDidSelectBlock : MediaDidSelectedBlock?
    
    var captureSesssion: AVCaptureSession?
    var cameraOutput: AVCapturePhotoOutput?
//    var videoOutput: AVCaptureVideoDataOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    enum MediaType {
        case camera
        case video
    }
    
    var mode: MediaType = .camera
    
    var cart = Cart()
    
    convenience init(cart: Cart) {
        self.init(nibName: nil, bundle: nil)
        self.cart = cart
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        checkCameraPermission()
        setupCameraActions()
    }
    
    private func configureCamera() {
        if captureSesssion == nil { captureSesssion = AVCaptureSession() }
        captureSesssion?.sessionPreset = AVCaptureSession.Preset.photo
        cameraOutput = AVCapturePhotoOutput()
        startCamera()
    }
    
    func startCamera(shouldShowBackCamera: Bool = true) {
        var device: AVCaptureDevice?
        device = shouldShowBackCamera ? AVCaptureDevice.default(.builtInWideAngleCamera,
                                                                for: AVMediaType.video,
                                                                position: .back) : AVCaptureDevice.default(.builtInWideAngleCamera,
                                                                                                           for: AVMediaType.video,
                                                                                                           position: .front)
        
        guard let captureDevice = device, let input = try? AVCaptureDeviceInput(device: captureDevice), let session = captureSesssion, session.canAddInput(input) else { return }
        captureSesssion?.addInput(input)
        guard let output = cameraOutput else { return }
        if session.canAddOutput(output) {
            session.addOutput(output)
            previewLayer = AVCaptureVideoPreviewLayer(session: session)
            guard let layer = previewLayer else { return }
            layer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            viewPreview.layer.addSublayer(layer)
            layer.frame = viewPreview.bounds
            captureSesssion?.startRunning()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = viewPreview.bounds
    }
    
    func pageDidShow() {
        configureCamera()
        switch mode {
        case .camera: viewBottom.mode = .camera
        case .video: viewBottom.mode = .video
        }
    }
    
    func toogleInput(shouldShowBackCamera: Bool = false) {
        captureSesssion?.beginConfiguration()
        for input in captureSesssion?.inputs ?? [] {
            captureSesssion?.removeInput(input)
        }
        
        captureSesssion = AVCaptureSession()
        captureSesssion?.sessionPreset = AVCaptureSession.Preset.photo
        cameraOutput = AVCapturePhotoOutput()
        
        startCamera(shouldShowBackCamera: shouldShowBackCamera)
    }
}


extension ArdhiCameraController {
    // This method you can use somewhere you need to know camera permission   state
    func checkCameraPermission() {
        
        let cameraPermissionStatus =  AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        
        switch cameraPermissionStatus {
            
        case .denied:
            print("denied")/*
            DispatchQueue.main.async() {
                
                AlertViewController.show(from: self, with: .cameraPermission, cancelHandler: { [weak self] (alertView) in
                    alertView.dismissController()
                    self?.dismissController()
                    
                    }, completionHandler: {[weak self] (alertView) in
                        alertView.dismissController()
                        
                        // go to setting to enable camera
                        guard let settingsURL = NSURL(string: UIApplication.openSettingsURLString) as URL? else { return }
                        UIApplication.shared.open(settingsURL, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
                        
                        self?.dismissController()
                        
                })
            }  */
            
        case .restricted:
            print("restricted")
//            DispatchQueue.main.async() { [weak self] in
//                self?.dismissController()
//            }
            
        case .authorized:
            configureCamera()
            
        default:
            configureCamera()
            
            AVCaptureDevice.requestAccess(for: AVMediaType.video) { [weak self]
                (granted :Bool) -> Void in
                
                if granted {
                }
                else {
                    
                    // dismiss if not permitted
                    DispatchQueue.main.async() { [weak self] in
//                        self?.dismissController()
                    }
                }
            }
        }
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
}

private extension ArdhiCameraController {
    
    func setupCameraActions() {
        
        viewBottom.didTapbuttonFlash = { [unowned self] sender in
            print("flash tappeed")
        }
        
        viewBottom.didTapCamera = { [unowned self] sender in
            self.capturePicture()
        }
        
        viewBottom.didTapCaptureVideo = { [unowned self] sender in
            print("video tapped")
        }
        
        viewBottom.didTapToggleCamera = { [unowned self] sender in
            sender.isSelected = !sender.isSelected
            self.toogleInput(shouldShowBackCamera: !sender.isSelected)
        }
    }
}

private extension ArdhiCameraController {
    
    func capturePicture() {
        let settings = AVCapturePhotoSettings()
        let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first
        let previewFormat: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: previewPixelType as Any,
            kCVPixelBufferWidthKey as String: 160,
            kCVPixelBufferHeightKey as String: 160
        ]
        settings.previewPhotoFormat = previewFormat
        cameraOutput?.capturePhoto(with: settings, delegate: self)
    }
}

extension ArdhiCameraController: AVCapturePhotoCaptureDelegate {

}

class SelectedView: UIView {
    
    private lazy var imageView = makeImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(frame: CGRect, image: UIImage) {
        self.init(frame: frame)
        imageView.image = image
    }
    
    func setup() {
        addSubview(imageView)
        imageView.g_pinEdges()
    }
    
    private func makeImageView() -> UIImageView {
        let imageview = UIImageView()
        return imageview
    }
}
