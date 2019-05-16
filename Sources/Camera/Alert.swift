//
//  Alert.swift
//  Gallery-iOS
//
//  Created by Muhammed Azharudheen on 4/29/19.
//  Copyright © 2019 Hyper Interaktiv AS. All rights reserved.
//

import Foundation
import UIKit

class Alert {
    
    enum Mode {
        case camera
        case library
        
        var title: String {
            return self == .camera ? "gallery.alert.camera.title".g_localize(fallback: "Camera") : "gallery.alert.library.title".g_localize(fallback: "Library")
        }
        
        var message: String {
            return self == .camera ? "gallery.alert.camera.message".g_localize(fallback: "Please go to Settings and allow access to your camera.") : "gallery.alert.library.message".g_localize(fallback: "Please go to Settings and allow access to your photo library.")
        }
        
        var ok : String {
            return "gallery.alert.title.ok".g_localize(fallback: "O.K")
        }
        
        var cancel: String {
            return "gallery.alert.cancel".g_localize(fallback: "Cancel")
        }
    }
    
    static let shared = Alert()
    
    func show(from: UIViewController?, mode: Mode) {
        let alert = UIAlertController(title: "", message: mode.message, preferredStyle: .alert)
        
        // Add "OK" Button to alert, pressing it will bring you to the settings app
        alert.addAction(UIAlertAction(title: mode.ok, style: .default, handler: { action in
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
        }))
        
        alert.addAction(UIAlertAction(title: mode.cancel, style: .default, handler: { action in
            EventHub.shared.didCancelPermission?()
        }))
        
        // Show the alert with animation
        from?.present(alert, animated: true)
    }
}
