//
//  UIViewController+Window.swift
//  ECommerce
//
//  Created by wizard.os25 on 18/11/25.
//

import UIKit

// MARK: - Keyboard
public extension UIViewController {
    func tapToDismissKeyboard() {
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
        tapGesture.cancelsTouchesInView = false
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
