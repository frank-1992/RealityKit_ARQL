//
//  UserDefaults+Extension.swift
//  XYARKit
//
//  Created by user on 5/6/22.
//

import Foundation

extension UserDefaults {
    
    private static let kHasShowTheRotateTip = "WYARKitModule-kHasShowTheRotateTip"
    
    static var hasShowTheRotateTip: Bool {
        get {
            self.standard.bool(forKey: kHasShowTheRotateTip)
        }
        set {
            self.standard.set(newValue, forKey: kHasShowTheRotateTip)
        }
    }
}
