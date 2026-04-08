//
//  UIView+Shadow.swift
//  ECommerce
//
//  Created by wizard.os25 on 18/11/25.
//

import UIKit

extension UIView {
    func dropMMShadow() {
        self.dropShadow(opacity: 0.08,
                        radius: 12.0,
                        offset: CGSize(width: 0, height: 2.0))
    }

    func dropShadow(color: UIColor = .black,
                    opacity: Float = 0.12,
                    radius: CGFloat = 10.0,
                    offset: CGSize = CGSize(width: 0, height: 4.0)) {
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = opacity
        layer.shadowOffset = offset
        layer.shadowRadius = radius
        layer.masksToBounds = false
    }
}
