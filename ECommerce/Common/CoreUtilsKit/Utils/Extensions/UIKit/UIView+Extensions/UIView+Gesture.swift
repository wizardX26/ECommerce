//
//  UIView+Gesture.swift
//  ECommerce
//
//  Created by wizard.os25 on 18/11/25.
//

import UIKit

public extension UIView {
    func visiblity(gone: Bool, dimension: CGFloat = 0.0, attribute: NSLayoutConstraint.Attribute = .height) {
        if let constraint = (self.constraints.filter { $0.firstAttribute == attribute }.first) {
            constraint.constant = gone ? 0.0 : dimension
            self.layoutIfNeeded()
            self.isHidden = gone
        }
    }

    @discardableResult
    func addTapGesture(_ target: Any?, action: Selector?) -> UITapGestureRecognizer? {
        isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: target, action: action)
        addGestureRecognizer(tapGesture)
        return tapGesture
    }
}
