//
//  CameraBottomView.swift
//  Gallery-iOS
//
//  Created by Muhammed Azharudheen on 4/21/19.
//  Copyright © 2019 Hyper Interaktiv AS. All rights reserved.
//

import UIKit

class CameraBottomView: UIView {
    
    typealias ButtonActionHandler = (UIButton) -> ()
    
    var didTapToggleCamera: ButtonActionHandler?
    var didTapCamera: ButtonActionHandler?
    var didTapCaptureVideo: ButtonActionHandler?
    var didTapbuttonFlash: ButtonActionHandler?
    
    var mode: Mode = .camera {
        didSet {
            updateMode()
        }
    }
    
    enum Mode {
        case camera
        case video
        
        var cameraImage: UIImage? {
            switch self {
            case .camera: return GalleryBundle.image("camera_button")
            case .video: return GalleryBundle.image("video")
            }
        }
    }
    
    private lazy var buttonCamera = makeCameraButton()
    private lazy var buttonFlash = makeFlashButton()
    private lazy var buttonToggleCamera = makeToggleCameraButton()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
        setupActions()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        setupActions()
    }
    
    func setup() {
        
        backgroundColor = UIColor.black
        
        addSubview(buttonCamera)
        buttonCamera.g_pinCenter()
        buttonCamera.g_pin(size: CGSize(width: 66, height: 66))
        
        addSubview(buttonFlash)
        buttonFlash.g_pin(on: .left, constant: 16)
        buttonFlash.g_pin(on: .centerY)
        buttonFlash.g_pin(size: CGSize(width: 28, height: 28))
        
        addSubview(buttonToggleCamera)
        buttonToggleCamera.g_pin(on: .right, constant: -16)
        buttonToggleCamera.g_pin(on: .centerY)
        buttonToggleCamera.g_pin(size: CGSize(width: 40, height: 40))
    }
    
    func setupActions() {
        buttonToggleCamera.addTarget(self, action: #selector(buttonToggleCameraTapped(_:)), for: .touchUpInside)
        buttonCamera.addTarget(self, action: #selector(buttonCameraTapped(_:)), for: .touchUpInside)
        buttonFlash.addTarget(self, action: #selector(buttonCameraTapped(_:)), for: .touchUpInside)
    }
}

private extension CameraBottomView {
    
    private func updateMode() {
        buttonCamera.setImage(mode.cameraImage, for: .normal)
    }
}

private extension CameraBottomView {
    func makeCameraButton() -> UIButton {
        let button = UIButton()
        button.setImage(GalleryBundle.image("camera_button")!, for: .normal)
        return button
    }
    
    func makeFlashButton() -> UIButton {
        let button = UIButton()
        button.setImage(GalleryBundle.image("flash_auto")!, for: .normal)
        return button
    }
    
    func makeToggleCameraButton() -> UIButton {
        let button = UIButton()
        button.setImage(GalleryBundle.image("selfie")!, for: .normal)
        return button
    }
}

private extension CameraBottomView {
    
    @objc
    func buttonCameraTapped(_ sender: UIButton) {
        guard mode == .camera else {
            didTapCaptureVideo?(sender)
            return
        }
        didTapCamera?(sender)
    }
    
    @objc
    func buttonFlashTapped(_ sender: UIButton) {
        didTapbuttonFlash?(sender)
    }
    
    @objc
    func buttonToggleCameraTapped(_ sender: UIButton) {
        didTapToggleCamera?(sender)
    }
}
