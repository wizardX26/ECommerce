//
//  UIViewController+Animation.swift
//  ECommerce
//
//  Created by wizard.os25 on 18/11/25.
//

import UIKit

extension UIViewController {
    
    /// Animate side menu to target position
    /// - Parameters:
    ///   - targetPosition: Target position for the side menu (CGFloat)
    ///   - sideMenuTrailingConstraint: Optional constraint for side menu leading/trailing (used when revealSideMenuOnTop is true)
    ///   - revealSideMenuOnTop: Whether the side menu is revealed on top of content
    ///   - completion: Completion handler called when animation finishes
    func animateSideMenu(
        targetPosition: CGFloat,
        sideMenuTrailingConstraint: NSLayoutConstraint? = nil,
        revealSideMenuOnTop: Bool = true,
        completion: @escaping (Bool) -> Void
    ) {
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 1.0,
            initialSpringVelocity: 0,
            options: .layoutSubviews,
            animations: {
                if revealSideMenuOnTop {
                    sideMenuTrailingConstraint?.constant = targetPosition
                    self.view.layoutIfNeeded()
                } else {
                    if self.view.subviews.count > 1 {
                        self.view.subviews[1].frame.origin.x = targetPosition
                    }
                }
            },
            completion: completion
        )
    }
}
