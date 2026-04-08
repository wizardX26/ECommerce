//
//  UIView+AddChild.swift
//  ECommerce
//
//  Created by wizard.os25 on 18/11/25.
//

import UIKit

extension UIView {
    func addSubviews(_ views: UIView...) {
        views.forEach { addSubview($0) }
    }
}

extension UIView {
    
    /// Thêm subview và fill superview luôn
    func addAndFill(_ subview: UIView, insets: UIEdgeInsets = .zero) {
        addSubview(subview)
        subview.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            subview.topAnchor.constraint(equalTo: topAnchor, constant: insets.top),
            subview.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.left),
            subview.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -insets.bottom),
            subview.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -insets.right)
        ])
    }
    
    /// Remove all subviews
    func removeAllSubviews() {
        subviews.forEach { $0.removeFromSuperview() }
    }
}
