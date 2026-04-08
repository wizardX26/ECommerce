//
//  UIView+CornerRadius.swift
//  ECommerce
//
//  Created by wizard.os25 on 18/11/25.
//

import UIKit

// MARK: - Corer Radius
public extension UIView {
    func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
}
