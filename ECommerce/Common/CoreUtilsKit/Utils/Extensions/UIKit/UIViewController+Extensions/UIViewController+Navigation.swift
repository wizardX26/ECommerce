//
//  UIViewController+Navigation.swift
//  ECommerce
//
//  Created by wizard.os25 on 18/11/25.
//

import UIKit

public extension UIViewController {
    
    /// Present full screen
    func presentFullScreen(_ viewController: UIViewController, animated: Bool = true) {
        viewController.modalPresentationStyle = .fullScreen
        present(viewController, animated: animated)
    }
    
    /// Present popup (over full screen)
    func presentPopupScreen(_ viewController: UIViewController, animated: Bool = true) {
        viewController.modalTransitionStyle = .crossDissolve
        viewController.modalPresentationStyle = .overFullScreen
        present(viewController, animated: animated)
    }
    
    /// Present from top-most view controller
    func presentViewControllerFromTop(_ viewController: UIViewController) {
        UIApplication.getTopMostViewController()?.presentFullScreen(viewController)
    }
    
    /// Push from top-most navigation controller
    func pushViewControllerFromTop(_ viewController: UIViewController) {
        UIApplication.getTopMostViewController()?.navigationController?.pushViewController(viewController, animated: true)
    }
    
    /// Dismiss if presented
    func dismissIfNeeded(animated: Bool = true, _ completion: (() -> Void)? = nil) {
        if let presentedVC = self.presentedViewController {
            presentedVC.dismiss(animated: animated, completion: completion)
        } else {
            completion?()
        }
    }
}
