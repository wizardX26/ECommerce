//
//  UIViewController+Parent.swift
//  ECommerce
//
//  Generic extension to find parent view controller of any type
//

import UIKit

extension UIViewController {
    
    /// Find the first parent view controller of the specified type in the view controller hierarchy
    /// - Parameter type: The type of view controller to find
    /// - Returns: The parent view controller of the specified type, or nil if not found
    ///
    /// Example:
    /// ```swift
    /// if let containerVC = self.findParentViewController(ofType: SomeContainerViewController.self) {
    ///     containerVC.someMethod()
    /// }
    /// ```
    func findParentViewController<T: UIViewController>(ofType type: T.Type) -> T? {
        var currentViewController: UIViewController? = self
        
        // Check if current view controller is of the target type
        if let targetVC = currentViewController as? T {
            return targetVC
        }
        
        // Traverse up the parent hierarchy
        while let parent = currentViewController?.parent {
            if let targetVC = parent as? T {
                return targetVC
            }
            currentViewController = parent
        }
        
        // Also check navigation controller hierarchy
        if let navController = currentViewController?.navigationController {
            if let targetVC = navController as? T {
                return targetVC
            }
            
            // Check navigation controller's parent
            if let navParent = navController.parent as? T {
                return navParent
            }
        }
        
        // Check presenting view controller
        if let presenting = currentViewController?.presentingViewController as? T {
            return presenting
        }
        
        return nil
    }
    
    /// Find the first parent view controller of the specified type (convenience method)
    /// - Returns: The parent view controller of the specified type, or nil if not found
    ///
    /// Example:
    /// ```swift
    /// if let containerVC: SomeContainerViewController = self.findParentViewController() {
    ///     containerVC.someMethod()
    /// }
    /// ```
    func findParentViewController<T: UIViewController>() -> T? {
        return findParentViewController(ofType: T.self)
    }
    
    /// Check if this view controller has a parent of the specified type
    /// - Parameter type: The type of view controller to check for
    /// - Returns: True if a parent of the specified type exists
    func hasParentViewController<T: UIViewController>(ofType type: T.Type) -> Bool {
        return findParentViewController(ofType: type) != nil
    }
    
    /// Get all parent view controllers in the hierarchy
    /// - Returns: Array of all parent view controllers
    func getAllParentViewControllers() -> [UIViewController] {
        var parents: [UIViewController] = []
        var currentViewController: UIViewController? = self.parent
        
        while let parent = currentViewController {
            parents.append(parent)
            currentViewController = parent.parent
        }
        
        return parents
    }
}

// MARK: - Protocol-Based Convenience Methods

extension UIViewController {
    
    /// Find the first parent view controller that conforms to a specific protocol
    /// - Parameter protocolType: The protocol type to search for
    /// - Returns: The parent view controller conforming to the protocol, or nil if not found
    ///
    /// Example:
    /// ```swift
    /// if let sidebarRevealable = self.findParentViewController(conformingTo: SidebarRevealable.self) {
    ///     sidebarRevealable.revealSidebar()
    /// }
    /// ```
    func findParentViewController<P>(conformingTo protocolType: P.Type) -> P? {
        var currentViewController: UIViewController? = self
        
        // Check if current view controller conforms to the protocol
        if let conformingVC = currentViewController as? P {
            return conformingVC
        }
        
        // Traverse up the parent hierarchy
        while let parent = currentViewController?.parent {
            if let conformingVC = parent as? P {
                return conformingVC
            }
            currentViewController = parent
        }
        
        // Also check navigation controller hierarchy
        if let navController = currentViewController?.navigationController {
            if let conformingVC = navController as? P {
                return conformingVC
            }
            
            // Check navigation controller's parent
            if let navParent = navController.parent as? P {
                return navParent
            }
        }
        
        // Check presenting view controller
        if let presenting = currentViewController?.presentingViewController as? P {
            return presenting
        }
        
        // Check if inside TabBarController
        if let tabBarController = currentViewController as? UITabBarController {
            // Check TabBarController's parent
            if let parent = tabBarController.parent as? P {
                return parent
            }
            // Check TabBarController's presenting view controller
            if let presenting = tabBarController.presentingViewController as? P {
                return presenting
            }
        }
        
        return nil
    }
}


