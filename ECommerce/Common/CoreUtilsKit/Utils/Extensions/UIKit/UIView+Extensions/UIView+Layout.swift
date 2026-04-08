//
//  UIView+Layout.swift
//  ECommerce
//
//  Created by wizard.os25 on 18/11/25.
//

import UIKit

// MARK: - Layout Helpers
extension UIView {

    func fillSuperview() {
        fillSuperviewVertically()
        fillSuperviewHorizontally()
    }

    func fillSuperviewVertically() {
        guard let superview = superview else { return }
        topAnchor.constraint(equalTo: superview.topAnchor).isActive = true
        bottomAnchor.constraint(equalTo: superview.bottomAnchor).isActive = true
    }

    func fillSuperviewHorizontally() {
        guard let superview = superview else { return }
        leadingAnchor.constraint(equalTo: superview.leadingAnchor).isActive = true
        trailingAnchor.constraint(equalTo: superview.trailingAnchor).isActive = true
    }

    func pinEdges(to other: UIView, insets: UIEdgeInsets = .zero) {
        translatesAutoresizingMaskIntoConstraints = false
        leadingAnchor.constraint(equalTo: other.leadingAnchor, constant: insets.left).isActive = true
        trailingAnchor.constraint(equalTo: other.trailingAnchor, constant: insets.right).isActive = true
        topAnchor.constraint(equalTo: other.topAnchor, constant: insets.top).isActive = true
        bottomAnchor.constraint(equalTo: other.bottomAnchor, constant: insets.bottom).isActive = true
    }

    func addConstraints(format: String,
                        options: NSLayoutConstraint.FormatOptions = [],
                        metrics: [String: AnyObject]? = nil,
                        views: [String: UIView]) {
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: format,
                                                      options: options,
                                                      metrics: metrics,
                                                      views: views))
    }

    func addUniversalConstraints(format: String,
                                 options: NSLayoutConstraint.FormatOptions = [],
                                 metrics: [String: AnyObject]? = nil,
                                 views: [String: UIView]) {
        addConstraints(format: "H:\(format)", options: options, metrics: metrics, views: views)
        addConstraints(format: "V:\(format)", options: options, metrics: metrics, views: views)
    }
}
