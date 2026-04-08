//
//  UIView+Bounds.swift
//  ECommerce
//
//  Created by wizard.os25 on 18/11/25.
//

import UIKit

extension UIView {
    var windowFrame: CGRect? {
        return superview?.convert(frame, to: nil)
    }
}
