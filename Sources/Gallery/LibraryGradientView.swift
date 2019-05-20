//
//  LibraryGradientView.swift
//  Gallery-iOS
//
//  Created by Muhammed Azharudheen on 5/20/19.
//  Copyright © 2019 Hyper Interaktiv AS. All rights reserved.
//

import UIKit

class LibraryGradientView: UIView {
    
    private let gradient: CAGradientLayer = {
        let layer = CAGradientLayer()
        let topColor = UIColor(red: 12/255, green: 18/255, blue: 28/255, alpha: 0)
        let bottomColor = UIColor(red: 12/255, green: 18/255, blue: 28/255, alpha: 0.5)
        layer.colors = [topColor.cgColor, bottomColor.cgColor]
        layer.locations = [0,1]
        return layer
    }()
    
    init() {
        super.init(frame: .zero)
        gradient.frame = frame
        layer.insertSublayer(gradient, at: 0)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
        
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hitView = super.hitTest(point, with: event), hitView != self else { return nil }
        return hitView
    }
}
