//
//  EcoNavigationBarViewController.swift
//  ECommerce
//
//  Created by wizard.os25 on 8/1/26.
//

import UIKit

/// UIViewController that binds NavigationBarController and NavigationBarView
/// Similar to ProductsViewController pattern
public final class EcoNavigationBarViewController: UIViewController {
    
    // MARK: - Properties
    
    var navigationBarController: EcoNavigationBarController!
    private let navigationBarView: EcoNavigationBarView
    
    // MARK: - Init
    
    public init(controller: EcoNavigationBarController) {
        self.navigationBarController = controller
        self.navigationBarView = EcoNavigationBarView()
        super.init(nibName: nil, bundle: nil)
    }
    
    public convenience init(initialState: EcoNavigationState = .init()) {
        let controller = DefaultEcoNavigationBarController(initialState: initialState)
        self.init(controller: controller)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        bind(to: navigationBarController)
        navigationBarController.viewDidLoad()
    }
    
    deinit {
        unbind()
    }
    
    // MARK: - Setup
    
    private func setupView() {
        view = navigationBarView
        navigationBarView.translatesAutoresizingMaskIntoConstraints = false
        // Ensure view can receive touch events
        view.isUserInteractionEnabled = true
        view.backgroundColor = .clear
    }
    
    // MARK: - Binding
    
    private func bind(to controller: EcoNavigationBarController) {
        // Bind state changes to view rendering
        controller.state.observe(on: self) { [weak self] state in
            self?.render(state: state)
        }
        
        // Bind search field events to controller
        setupSearchFieldBindings()
    }
    
    /// Re-setup search field bindings (useful when callbacks are updated)
    func updateSearchFieldBindings() {
        print("📷 [EcoNavigationBarViewController] updateSearchFieldBindings called")
        // Verify callback exists before re-setting up bindings
        if let controller = navigationBarController as? DefaultEcoNavigationBarController {
            print("📷 [EcoNavigationBarViewController] onCameraTap callback before re-setup: \(controller.onCameraTap != nil ? "EXISTS" : "nil")")
        }
        setupSearchFieldBindings()
        // Verify callback exists after re-setting up bindings
        if let controller = navigationBarController as? DefaultEcoNavigationBarController {
            print("📷 [EcoNavigationBarViewController] onCameraTap callback after re-setup: \(controller.onCameraTap != nil ? "EXISTS" : "nil")")
        }
        print("📷 [EcoNavigationBarViewController] Search field bindings re-setup completed")
    }
    
    private func unbind() {
        navigationBarController.state.remove(observer: self)
        navigationBarController.statusBarStyle.remove(observer: self)
    }
    
    private func setupSearchFieldBindings() {
        let searchField = navigationBarView.searchField
        
        searchField.onTextChange = { [weak self] text in
            self?.navigationBarController.didSearchTextChange(text)
        }
        
        searchField.onSubmit = { [weak self] text in
            self?.navigationBarController.didSearchSubmit(text)
        }
        
        searchField.onClear = { [weak self] in
            self?.navigationBarController.didSearchClear()
        }
        
        // Setup camera tap handler - truy cập callback trực tiếp khi được gọi
        searchField.onCameraTap = { [weak self] in
            print("📷 [EcoNavigationBarViewController] Search field camera tap received")
            guard let self = self else {
                print("⚠️ [EcoNavigationBarViewController] self is nil")
                return
            }
            
            // Truy cập controller.onCameraTap trực tiếp khi được gọi, không capture
            if let controller = self.navigationBarController as? DefaultEcoNavigationBarController {
                print("📷 [EcoNavigationBarViewController] Controller found, onCameraTap: \(controller.onCameraTap != nil ? "EXISTS" : "nil")")
                // Gọi callback trực tiếp
                controller.onCameraTap?()
            } else {
                print("⚠️ [EcoNavigationBarViewController] Controller is not DefaultEcoNavigationBarController")
            }
        }
        
        // Setup item tap handlers to route through controller
        navigationBarView.onLeftItemTap = { [weak self] in
            self?.navigationBarController.didLeftItemTap()
        }
        
        navigationBarView.onRightItemTap = { [weak self] index in
            self?.navigationBarController.didRightItemTap(at: index)
        }
    }
    
    private func render(state: EcoNavigationState) {
        navigationBarView.render(state: state, animated: true)
    }
}

// MARK: - Public API

public extension EcoNavigationBarViewController {
    
    /// Access to the underlying controller
    var controller: EcoNavigationBarController {
        navigationBarController
    }
    
    /// Get current status bar style
    var currentStatusBarStyle: UIStatusBarStyle {
        navigationBarController.statusBarStyle.value
    }
    
    /// Update navigation bar state
    func updateState(_ state: EcoNavigationState, animated: Bool = true) {
        navigationBarController.didUpdateState(state)
    }
    
    /// Handle scroll updates
    func handleScroll(offset: CGFloat) {
        navigationBarController.didScrollUpdate(progress: offset)
        
        // Track previous scroll state để detect khi search field vừa được hiển thị
        let previousOffset = navigationBarView.scrollOffset
        navigationBarView.updateScroll(progress: offset)
        
        // Khi search field được hiển thị sau khi collapse (progress > 0.1)
        // Đảm bảo bindings được setup lại để camera button hoạt động
        guard let currentState = navigationBarView.currentState else { return }
        
        if currentState.scrollBehavior == .collapseWithSearch {
            let threshold: CGFloat = 50
            let maxOffset: CGFloat = 100
            let previousProgress = min(max((previousOffset - threshold) / (maxOffset - threshold), 0), 1)
            let currentProgress = min(max((offset - threshold) / (maxOffset - threshold), 0), 1)
            let shouldShowSearch = currentProgress > 0.1
            let previousShouldShow = previousProgress > 0.1
            
            // Nếu search field vừa được hiển thị (từ hidden -> visible)
            if shouldShowSearch && !previousShouldShow {
                print("📷 [EcoNavigationBarViewController] Search field just became visible after collapse")
                // Verify callback exists before re-setting up bindings
                if let controller = navigationBarController as? DefaultEcoNavigationBarController {
                    print("📷 [EcoNavigationBarViewController] onCameraTap callback when search field appears: \(controller.onCameraTap != nil ? "EXISTS" : "nil")")
                    if controller.onCameraTap == nil {
                        print("⚠️ [EcoNavigationBarViewController] onCameraTap is nil - attempting to re-setup from parent")
                        // Try to get callback from parent view controller (EcoBaseViewController/EcoViewController)
                        // Find parent and request to re-setup callbacks
                        if let parentVC = findParentEcoViewController() {
                            print("📷 [EcoNavigationBarViewController] Found parent EcoViewController, requesting callback re-setup")
                            // Get callback directly from controller and set it
                            let cameraCallback = parentVC.controller.onNavigationBarCameraTap
                            print("📷 [EcoNavigationBarViewController] Camera callback from parent: \(cameraCallback != nil ? "EXISTS" : "nil")")
                            controller.onCameraTap = cameraCallback
                            print("📷 [EcoNavigationBarViewController] onCameraTap callback after re-setup: \(controller.onCameraTap != nil ? "EXISTS" : "nil")")
                        } else {
                            print("⚠️ [EcoNavigationBarViewController] Parent EcoViewController not found")
                        }
                    }
                }
                // Re-setup bindings để đảm bảo camera button callback hoạt động
                // Note: Closure sẽ truy cập controller.onCameraTap trực tiếp khi được gọi, không capture
                updateSearchFieldBindings()
            }
        }
    }
    
    /// Find parent EcoViewController để có thể re-setup callbacks
    func findParentEcoViewController() -> EcoViewController? {
        var responder: UIResponder? = self
        while responder != nil {
            responder = responder?.next
            if let ecoVC = responder as? EcoViewController {
                return ecoVC
            }
        }
        return nil
    }
    
    /// Set callback for height changes during scroll
    func setHeightChangeCallback(_ callback: @escaping (CGFloat) -> Void) {
        navigationBarView.onHeightChange = callback
    }
    
    /// Get search text field for external configuration
    var searchField: EcoSearchTextField {
        navigationBarView.searchField
    }
    
    /// Convenience methods that delegate to controller
    func setTitle(_ title: String?) {
        if let controller = navigationBarController as? DefaultEcoNavigationBarController {
            controller.setTitle(title)
        }
    }
    
    func showSearch(_ show: Bool) {
        if let controller = navigationBarController as? DefaultEcoNavigationBarController {
            controller.showSearch(show)
        }
    }
    
    func setBackground(_ background: EcoNavigationBackground) {
        if let controller = navigationBarController as? DefaultEcoNavigationBarController {
            controller.setBackground(background)
        }
    }
    
    func setLeftItem(_ item: EcoNavItem?) {
        if let controller = navigationBarController as? DefaultEcoNavigationBarController {
            controller.setLeftItem(item)
        }
    }
    
    func setRightItems(_ items: [EcoNavItem]) {
        if let controller = navigationBarController as? DefaultEcoNavigationBarController {
            controller.setRightItems(items)
        }
    }
    
    func update(_ block: (inout EcoNavigationState) -> Void) {
        if let controller = navigationBarController as? DefaultEcoNavigationBarController {
            controller.update(block)
        }
    }
}

// MARK: - Navigation Bar Metrics

public struct EcoNavigationBarMetrics {
    public static let height: CGFloat = 44.0 + UIApplication.shared.statusBarFrame.height
    public static let barHeight: CGFloat = 44.0
}

