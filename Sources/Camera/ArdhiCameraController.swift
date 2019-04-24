//
//  ArdhiCameraController.swift
//  Gallery-iOS
//
//  Created by Muhammed Azharudheen on 4/21/19.
//  Copyright © 2019 Hyper Interaktiv AS. All rights reserved.
//

import UIKit
import AVFoundation

class ArdhiCameraController: UIViewController {
    
    var manager: CameraManager?
    
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
        }
    }

    lazy var viewBottom = makeBottomView()
    lazy var viewPreview = makePreviewView()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupActions()
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
}

private extension ArdhiCameraController {
    
    func setupActions() {
        
        viewBottom.didTapbuttonFlash = { [unowned self] sender in
            print("flash tappeed")
        }
        
        viewBottom.didTapCamera = { [unowned self] sender in
            self.manager?.capturePhoto()
        }
        
        viewBottom.didTapCaptureVideo = { [unowned self] sender in
            self.manager?.captureVideo()
        }
        
        viewBottom.didTapToggleCamera = { [unowned self] sender in
            print("toggle tapped")
        }
    }
}

extension ArdhiCameraController: PageAware {
    func pageDidShow() {
        manager = CameraManager(previewView: viewPreview)
        
        manager?.photoCaptureCompletionBlock = { [weak self] image, error in
            guard let image = image else { return }
            self?.cart.reset()
            self?.cart.image = image
            EventHub.shared.capturedImage?()
        }
        manager?.videoCaptureStartedBlock = {
            print("started video capture")
        }
        manager?.videoCaptureCompletionBlock = { [weak self] url, error in
            guard let url = url else { return }
            self?.cart.reset()
            self?.cart.url = url
            EventHub.shared.capturedVideo?()
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
