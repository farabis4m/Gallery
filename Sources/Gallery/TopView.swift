//
//  TopView.swift
//  Gallery-iOS
//
//  Created by Muhammed Azharudheen on 4/23/19.
//  Copyright © 2019 Hyper Interaktiv AS. All rights reserved.
//

import UIKit

class TopView: UIView {
    
    var padding: CGFloat = 8
    
    var didTapLeft: (() -> ())?
    var didTapRight: (() -> ())?
    
    var mode: GalleryMode = .cameraUnselected {
        didSet {
            updateTopView()
        }
    }
    
    var leftTitle: String? {
        didSet {
            buttonLeft.setTitle(leftTitle, for: .normal)
        }
    }
    
    var title: String? {
        didSet {
            labelTitle.text = title
        }
    }
    
    var rightTitle: String? {
        didSet {
            buttonRight.setTitle(rightTitle, for: .normal)
        }
    }
    
    lazy var buttonLeft = makeButtonLeft()
    lazy var labelTitle = makeLabelTitle()
    lazy var buttonRight = makeButtonRight()
    
    private func makeButtonLeft() -> UIButton {
        let button = UIButton()
        button.setTitleColor(UIColor.white, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("left", for: .normal)
        return button
    }
    
    private func makeLabelTitle() -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.white
        label.text = "title"
        return label
    }
    
    private func makeButtonRight() -> UIButton {
        let button = UIButton()
        button.setTitleColor(UIColor.white, for: .normal)
        button.setTitle("right", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        setup()
        updateTopView()
    }
    
    private func setup() {
        addSubview(buttonLeft)
        
        backgroundColor = .red
        
        NSLayoutConstraint.activate([
            buttonLeft.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            buttonLeft.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
        
        addSubview(labelTitle)
        NSLayoutConstraint.activate([
            labelTitle.centerYAnchor.constraint(equalTo: centerYAnchor),
            labelTitle.centerXAnchor.constraint(equalTo: centerXAnchor)
            ])
        
        addSubview(buttonRight)
        NSLayoutConstraint.activate([
            buttonRight.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            buttonRight.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
        
        buttonLeft.addTarget(self, action: #selector(buttonLeftTapped), for: .touchUpInside)
        buttonRight.addTarget(self, action: #selector(buttonRightTapped), for: .touchUpInside)
    }
    
    private func updateTopView() {
        buttonLeft.setTitle(mode.leftTitle, for: .normal)
        buttonRight.setTitle(mode.rightTitle, for: .normal)
        buttonRight.isHidden = mode.shouldHideButtonRight
        labelTitle.text = mode.title
    }
    
    @objc private func buttonLeftTapped() {
        didTapLeft?()
    }
    
    @objc private func buttonRightTapped() {
        didTapRight?()
    }
}

enum GalleryMode {
    case photoLibraryUnselected
    case photoLibrarySelected
    case cameraUnselected
    case cameraSelected
    
    var leftTitle: String {
        switch self {
        case .photoLibraryUnselected, .cameraUnselected, .photoLibrarySelected: return "Close"
        case .cameraSelected: return "Retake"
        }
    }
    
    var rightTitle: String {
        return "Save"
    }
    
    var shouldHideButtonRight: Bool {
        switch self {
        case .cameraUnselected, .photoLibraryUnselected: return true
        case .photoLibrarySelected, .cameraSelected: return false
        }
    }
    
    var title: String {
        return "Add Media"
    }
    
    var shouldShowPreviewScreen: Bool {
        switch self {
        case .cameraSelected: return true
        case .photoLibrarySelected, .photoLibraryUnselected, .cameraUnselected: return false
        }
    }
}
