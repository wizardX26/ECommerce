//
//  UIView+Screen.swift
//  ECommerce
//
//  Created by wizard.os25 on 18/11/25.
//

import UIKit

public extension UIView {
    var screenWidth: CGFloat? {
        return UIWindow.visibleWindow()?.screen.bounds.size.width
    }

    var screenHeight: CGFloat? {
        return UIWindow.visibleWindow()?.screen.bounds.size.height
    }
}
