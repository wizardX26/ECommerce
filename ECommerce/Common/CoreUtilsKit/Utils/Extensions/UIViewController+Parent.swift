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
    /// if let mainVC = self.findParentViewController(ofType: MainViewController.self) {
    ///     mainVC.revealSidebar()
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
    /// if let mainVC: MainViewController = self.findParentViewController() {
    ///     mainVC.revealSidebar()
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

// MARK: - Specific Implementation for MainViewController (if exists)
// Uncomment and customize if you have a MainViewController class

/*
extension UIViewController {
    /// Convenience method to find MainViewController
    /// - Returns: The MainViewController if found in the hierarchy
    func revealViewController() -> MainViewController? {
        return findParentViewController(ofType: MainViewController.self)
    }
}
*/



