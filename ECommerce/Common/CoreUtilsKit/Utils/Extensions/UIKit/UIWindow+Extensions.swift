//
//  AccountObject.swift
//  ECommerce
//
//  Created by wizard.os25 on 18/11/25.
//

import UIKit

public extension UIWindow {
    static func visibleWindow() -> UIWindow? {
        var currentWindow = UIApplication.shared.keyWindow
        
        if currentWindow == nil {
            let frontToBackWindows = Array(UIApplication.shared.windows.reversed())
            
            for window in frontToBackWindows where window.windowLevel == UIWindow.Level.normal {
                currentWindow = window
                break
            }
        }
        
        return currentWindow
    }
}
