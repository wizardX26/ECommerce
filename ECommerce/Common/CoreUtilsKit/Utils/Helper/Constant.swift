//
//  AccountObject.swift
//  ECommerce
//
//  Created by wizard.os25 on 18/11/25.
//

import UIKit

public struct Constant {
    public static let ratio = UIScreen.main.bounds.size.width / 375.0
    public static let applePhoneNumber = "1234567899"
    public static let appsFlyerPrivateKey = "u8x/A?D(G+KaPdSgVkYp3s6v9y$B&E)H"
    
    public struct DropDownAnimation {
        public static let duration = 0.12
        public static let entranceOptions: UIView.AnimationOptions = [.allowUserInteraction, .curveEaseOut]
        public static let exitOptions: UIView.AnimationOptions = [.allowUserInteraction, .curveEaseIn]
        public static let downScaleTransform = CGAffineTransform(scaleX: 0.88, y: 0.88)
    }
}
