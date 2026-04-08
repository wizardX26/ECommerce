//
//  SidebarRevealBehavior.swift
//  ECommerce
//
//  Behavior to handle sidebar reveal/collapse functionality
//

import UIKit

/// Protocol that view controllers with sidebar functionality should conform to
protocol SidebarRevealable {
    func revealSidebar()
    func hideSidebar()
    func toggleSidebar()
}

/// Behavior to add sidebar reveal/collapse functionality to any view controller
/// This behavior can be added to child view controllers to access parent sidebar functionality
final class SidebarRevealBehavior: ViewControllerLifecycleBehavior {
    
    private weak var targetViewController: UIViewController?
    private let revealButton: UIButton?
    private let gestureRecognizer: UIGestureRecognizer?
    
    /// Initialize with a button that triggers sidebar reveal
    /// - Parameter revealButton: Button that will trigger sidebar reveal when tapped
    init(revealButton: UIButton) {
        self.revealButton = revealButton
        self.gestureRecognizer = nil
        revealButton.addTarget(self, action: #selector(handleRevealAction), for: .touchUpInside)
    }
    
    /// Initialize with a gesture recognizer that triggers sidebar reveal
    /// - Parameter gestureRecognizer: Gesture recognizer that will trigger sidebar reveal
    init(gestureRecognizer: UIGestureRecognizer) {
        self.gestureRecognizer = gestureRecognizer
        self.revealButton = nil
        gestureRecognizer.addTarget(self, action: #selector(handleRevealAction))
    }
    
    /// Initialize with custom action handler
    /// - Parameter actionHandler: Closure to execute when reveal action is triggered
    init(actionHandler: @escaping () -> Void) {
        self.revealButton = nil
        self.gestureRecognizer = nil
        self.actionHandler = actionHandler
    }
    
    private var actionHandler: (() -> Void)?
    
    func viewDidLoad(viewController: UIViewController) {
        targetViewController = viewController
        
        // Add gesture recognizer to view if provided
        if let gestureRecognizer = gestureRecognizer {
            viewController.view.addGestureRecognizer(gestureRecognizer)
        }
    }
    
    func viewWillDisappear(viewController: UIViewController) {
        // Clean up if needed
    }
    
    @objc private func handleRevealAction() {
        if let actionHandler = actionHandler {
            actionHandler()
        } else {
            // Try to find parent view controller with sidebar functionality
            // We need to check all parents to find one that conforms to SidebarRevealable
            guard let targetViewController = targetViewController else { return }
            
            let parents = targetViewController.getAllParentViewControllers()
            for parent in parents {
                if let sidebarVC = parent as? SidebarRevealable {
                    sidebarVC.toggleSidebar()
                    return
                }
            }
            
            // Also check self
            if let sidebarVC = targetViewController as? SidebarRevealable {
                sidebarVC.toggleSidebar()
            }
        }
    }
}

// MARK: - Generic Sidebar Behavior

/// Generic behavior to find and interact with parent view controller of specific type
final class ParentViewControllerBehavior<T: UIViewController>: ViewControllerLifecycleBehavior {
    
    private weak var targetViewController: UIViewController?
    private let onFound: ((T) -> Void)?
    private let onNotFound: (() -> Void)?
    
    /// Initialize with callbacks
    /// - Parameters:
    ///   - onFound: Called when parent view controller is found
    ///   - onNotFound: Called when parent view controller is not found
    init(onFound: ((T) -> Void)? = nil, onNotFound: (() -> Void)? = nil) {
        self.onFound = onFound
        self.onNotFound = onNotFound
    }
    
    func viewDidLoad(viewController: UIViewController) {
        targetViewController = viewController
        findParentViewController()
    }
    
    private func findParentViewController() {
        guard let targetViewController = targetViewController else { return }
        
        if let parentVC = targetViewController.findParentViewController(ofType: T.self) {
            onFound?(parentVC)
        } else {
            onNotFound?()
        }
    }
}

// MARK: - Example Usage Helper

extension UIViewController {
    
    /// Add sidebar reveal behavior with a button
    /// - Parameter button: Button that will trigger sidebar reveal
    func addSidebarRevealBehavior(button: UIButton) {
        let behavior = SidebarRevealBehavior(revealButton: button)
        addBehaviors([behavior])
    }
    
    /// Add sidebar reveal behavior with a gesture recognizer
    /// - Parameter gestureRecognizer: Gesture recognizer that will trigger sidebar reveal
    func addSidebarRevealBehavior(gestureRecognizer: UIGestureRecognizer) {
        let behavior = SidebarRevealBehavior(gestureRecognizer: gestureRecognizer)
        addBehaviors([behavior])
    }
    
    /// Add sidebar reveal behavior with custom action
    /// - Parameter action: Closure to execute when reveal action is triggered
    func addSidebarRevealBehavior(action: @escaping () -> Void) {
        let behavior = SidebarRevealBehavior(actionHandler: action)
        addBehaviors([behavior])
    }
    
    /// Add behavior to find parent view controller of specific type
    /// - Parameters:
    ///   - type: Type of parent view controller to find
    ///   - onFound: Called when parent is found
    ///   - onNotFound: Called when parent is not found
    func addParentViewControllerBehavior<T: UIViewController>(
        ofType type: T.Type,
        onFound: @escaping (T) -> Void,
        onNotFound: (() -> Void)? = nil
    ) {
        let behavior = ParentViewControllerBehavior<T>(onFound: onFound, onNotFound: onNotFound)
        addBehaviors([behavior])
    }
}

