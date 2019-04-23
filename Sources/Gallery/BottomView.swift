//
//  BottomView.swift
//  Gallery-iOS
//
//  Created by Muhammed Azharudheen on 4/23/19.
//  Copyright © 2019 Hyper Interaktiv AS. All rights reserved.
//

import UIKit

class BottomView: UIView {
    
    var didTapLeft: (() -> ())?
    var didTapCenter: (() -> ())?
    var didTapRight: (() -> ())?
    
    private lazy var leftButton = makeButton()
    private lazy var centerButton = makeButton()
    private lazy var rightButton = makeButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    private func setup() {
        
        backgroundColor = .red
        
        [leftButton, centerButton, rightButton].forEach {
            addSubview($0)
            $0.g_pin(on: .centerY)
        }
        
        leftButton.tag = 0
        centerButton.tag = 1
        rightButton.tag = 2
        
        leftButton.g_pin(on: .left, constant: 8)
        centerButton.g_pin(on: .centerX, constant: 8)
        rightButton.g_pin(on: .right, constant: -8)
        
        [leftButton, centerButton, rightButton].forEach {
            $0.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        }
    }
    
    @objc
    private func buttonTapped(_ sender: UIButton) {
        switch sender.tag {
        case 0: didTapLeft?()
        case 1: didTapCenter?()
        case 2: didTapRight?()
        default: break
        }
    }
    
    private func makeButton() -> UIButton {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(UIColor.white, for: .normal)
        button.setTitle("Test", for: .normal)
        return button
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
}

