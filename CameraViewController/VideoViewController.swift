//
//  VideoViewController.swift
//  Gallery-iOS
//
//  Created by Muhammed Azharudheen on 4/18/19.
//  Copyright © 2019 Hyper Interaktiv AS. All rights reserved.
//

import UIKit

class CurrentContrller {
    
    static let shared = CurrentContrller()
    
    private init () { }
    
    var type: CameraViewController.MediaType = .camera
    
    
    
}

class VideoViewController: CameraViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .red
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if CurrentContrller.shared.type == .video {
            startCamera()
        }
    }
}

extension VideoViewController: PageAware {
    func pageDidShow() {
        
    }
    
    
    
    
}


extension VideoViewController {
    
    enum MediaType {
        case camera
        case video
        case gallery
    }
}
