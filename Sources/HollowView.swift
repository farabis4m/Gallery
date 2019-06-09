//
//  HollowView.swift
//  Gallery-iOS
//
//  Created by Muhammed Azharudheen on 5/6/19.
//  Copyright © 2019 Hyper Interaktiv AS. All rights reserved.
//

import UIKit

class HollowView: UIView {
    
    var transparentRect: CGRect?
    
    init(frame: CGRect, transparentRect: CGRect) {
        super.init(frame: frame)
        
        self.transparentRect = transparentRect
        self.isUserInteractionEnabled = false
        self.alpha = 0.5
        self.isOpaque = false
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        guard let transparentRect = transparentRect else { return }
        backgroundColor?.setFill()
        UIRectFill(rect)
        
        let holeRectIntersection = transparentRect.intersection( rect )
        
        UIColor.clear.setFill();
        UIRectFill(holeRectIntersection);
        
        let path = UIBezierPath(rect: holeRectIntersection)
        path.lineWidth = 2.0
        UIColor(red: 255/255, green: 107/255, blue: 0, alpha: 1.0).setStroke()
        path.stroke()
    }
}
