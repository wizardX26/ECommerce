//
//  UIViewController+Window.swift
//  ECommerce
//
//  Created by wizard.os25 on 18/11/25.
//

import UIKit

// MARK: - Window
@objc
public extension UIViewController {
    func appWindow() -> UIWindow {
        return ((UIApplication.shared.delegate?.window)!)!
    }
}
