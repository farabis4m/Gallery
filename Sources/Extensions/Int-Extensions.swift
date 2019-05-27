//
//  Int-Extensions.swift
//  Gallery-iOS
//
//  Created by Muhammed Azharudheen on 5/27/19.
//  Copyright © 2019 Hyper Interaktiv AS. All rights reserved.
//

import Foundation

extension Int {
    func secondsToHoursMinutesSeconds () -> (Int, Int, Int) {
        return (self / 3600, (self % 3600) / 60, (self % 3600) % 60)
        
    }
    func timerString() -> String {
        return String(format: "%02d:%02d:%02d", secondsToHoursMinutesSeconds().0, secondsToHoursMinutesSeconds().1, secondsToHoursMinutesSeconds().2)
    }
}

