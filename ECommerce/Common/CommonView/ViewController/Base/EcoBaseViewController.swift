//
//  EcoBaseViewController.swift
//  ECommerce
//
//  Created by wizard.os25 on 8/1/26.
//

import UIKit

open class EcoBaseViewController: UIViewController {

    // MARK: - Navigation Bar

    public private(set) var navigationBarViewController: EcoNavigationBarViewController?
    private var navigationBarHeightConstraint: NSLayoutConstraint?
    
    // MARK: - Keyboard Handling
    
    private var keyboardObserverTokens: [NSObjectProtocol] = []
    private var dismissKeyboardTapGesture: UITapGestureRecognizer?

    // MARK: - Status Bar

    open var statusBarStyle: UIStatusBarStyle = .darkContent {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
        }
    }

    open override var preferredStatusBarStyle: UIStatusBarStyle {
        statusBarStyle
    }

    // MARK: - Swipe Back Gesture

    open var isSwipeBackEnabled: Bool = true {
        didSet {
            updateSwipeBackGesture()
        }
    }

    // MARK: - Lifecycle

    open override func viewDidLoad() {
        super.viewDidLoad()
        configureBaseUI()
        setupKeyboardObservers()
        setupSwipeBackGestureDelegate()
        setupDismissKeyboardGesture()
    }
    
    private func setupSwipeBackGestureDelegate() {
        // Set delegate for interactive pop gesture recognizer
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        print("🔵 [EcoBaseViewController] Swipe back gesture delegate set")
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Ensure system navigation bar is always hidden
        navigationController?.isNavigationBarHidden = true
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Ensure system navigation bar is always hidden
        navigationController?.isNavigationBarHidden = true
        updateSwipeBackGesture()
        syncStatusBarStyleFromNavigationBar()
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Reset scroll view insets when view disappears
        adjustScrollViewForKeyboard(keyboardHeight: 0)
    }

    deinit {
        removeKeyboardObservers()
        removeDismissKeyboardGesture()
        detachNavigationBar()
    }
}

private extension EcoBaseViewController {

    func configureBaseUI() {
        view.backgroundColor = .systemBackground

        // Disable automatic inset adjustment
        if #available(iOS 11.0, *) {
            // handled by safeArea
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }

        // Hide system navigation bar if embedded
        navigationController?.isNavigationBarHidden = true
    }

    func updateSwipeBackGesture() {
        guard let navigationController else {
            print("⚠️ [EcoBaseViewController] updateSwipeBackGesture - navigationController is nil")
            return
        }
        let isEnabled = isSwipeBackEnabled && navigationController.viewControllers.count > 1
        navigationController.interactivePopGestureRecognizer?.isEnabled = isEnabled
        print("🔵 [EcoBaseViewController] updateSwipeBackGesture - isSwipeBackEnabled: \(isSwipeBackEnabled), viewControllers.count: \(navigationController.viewControllers.count), gesture enabled: \(isEnabled)")
    }

    func syncStatusBarStyleFromNavigationBar() {
        guard let navBarVC = navigationBarViewController else { return }
        statusBarStyle = navBarVC.currentStatusBarStyle
    }
    
    func setupKeyboardObservers() {
        let willShowToken = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleKeyboardWillShow(notification)
        }
        
        let willHideToken = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleKeyboardWillHide(notification)
        }
        
        keyboardObserverTokens = [willShowToken, willHideToken]
    }
    
    func removeKeyboardObservers() {
        keyboardObserverTokens.forEach {
            NotificationCenter.default.removeObserver($0)
        }
        keyboardObserverTokens.removeAll()
    }
    
    func handleKeyboardWillShow(_ notification: Foundation.Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }
        
        adjustScrollViewForKeyboard(keyboardHeight: keyboardFrame.height)
    }
    
    func handleKeyboardWillHide(_ notification: Foundation.Notification) {
        adjustScrollViewForKeyboard(keyboardHeight: 0)
    }
    
    func adjustScrollViewForKeyboard(keyboardHeight: CGFloat) {
        // Find all scroll views in view hierarchy and adjust contentInset
        view.subviews.forEach { subview in
            if let scrollView = subview as? UIScrollView {
                let contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
                scrollView.contentInset = contentInset
                scrollView.scrollIndicatorInsets = contentInset
            }
        }
    }
    
    func setupDismissKeyboardGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
        dismissKeyboardTapGesture = tapGesture
    }
    
    func removeDismissKeyboardGesture() {
        if let gesture = dismissKeyboardTapGesture {
            view.removeGestureRecognizer(gesture)
            dismissKeyboardTapGesture = nil
        }
    }
    
    @objc public override func dismissKeyboard() {
        view.endEditing(true)
    }
}

public extension EcoBaseViewController {

    // MARK: Attach

    func attachNavigationBar(
        initialState: EcoNavigationState = .init(),
        onSearchTextChange: ((String) -> Void)? = nil,
        onSearchSubmit: ((String) -> Void)? = nil,
        onSearchClear: (() -> Void)? = nil,
        onLeftItemTap: (() -> Void)? = nil,
        onRightItemTap: ((Int) -> Void)? = nil,
        onCameraTap: (() -> Void)? = nil
    ) {
        if navigationBarViewController == nil {
            let navBarVC = EcoNavigationBarViewController(initialState: initialState)
            
            // Setup callbacks
            if let controller = navBarVC.controller as? DefaultEcoNavigationBarController {
                controller.onSearchTextChange = onSearchTextChange
                controller.onSearchSubmit = onSearchSubmit
                controller.onSearchClear = onSearchClear
                controller.onLeftItemTap = onLeftItemTap
                controller.onRightItemTap = onRightItemTap
                controller.onCameraTap = onCameraTap
                print("📷 [EcoBaseViewController] attachNavigationBar - onCameraTap callback set: \(onCameraTap != nil ? "EXISTS" : "nil")")
                
                // Re-setup search field bindings sau khi callback được set
                // Đảm bảo closure capture callback mới nhất
                navBarVC.updateSearchFieldBindings()
                print("📷 [EcoBaseViewController] attachNavigationBar - Search field bindings updated")
            }

            addChild(navBarVC)
            view.addSubview(navBarVC.view)
            navBarVC.didMove(toParent: self)

            navBarVC.view.translatesAutoresizingMaskIntoConstraints = false

            let height = initialState.height ?? EcoNavigationBarMetrics.barHeight
            let heightConstraint = navBarVC.view.heightAnchor
                .constraint(equalToConstant: height)

            navigationBarHeightConstraint = heightConstraint

            NSLayoutConstraint.activate([
                navBarVC.view.topAnchor.constraint(
                    equalTo: view.topAnchor
                ),
                navBarVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                navBarVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                heightConstraint
            ])

            navigationBarViewController = navBarVC
            
            // Ensure navigation bar is on top of all other views
            view.bringSubviewToFront(navBarVC.view)
            
            // Ensure navigation bar view can receive touch events
            navBarVC.view.isUserInteractionEnabled = true
            
            // Debug: Check if scrollView might be blocking touches
            if let scrollView = view.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView {
                print("⚠️ [EcoBaseViewController] ScrollView found - checking if it blocks navigation bar")
                print("   - ScrollView frame: \(scrollView.frame)")
                print("   - ScrollView isUserInteractionEnabled: \(scrollView.isUserInteractionEnabled)")
            }
            
            // Debug logging
            print("🔵 [EcoBaseViewController] Navigation bar attached:")
            print("   - Height: \(height)")
            print("   - Frame after layout: \(navBarVC.view.frame)")
            print("   - Superview: \(navBarVC.view.superview != nil ? "EXISTS" : "nil")")
            print("   - isHidden: \(navBarVC.view.isHidden)")
            print("   - alpha: \(navBarVC.view.alpha)")
            
            // Setup height change callback for scroll behavior
            navBarVC.setHeightChangeCallback { [weak self] newHeight in
                self?.updateNavigationBarHeight(newHeight, animated: true)
            }
        } else {
            navigationBarViewController?.updateState(initialState, animated: true)
            // Update callbacks
            if let controller = navigationBarViewController?.controller as? DefaultEcoNavigationBarController {
                controller.onSearchTextChange = onSearchTextChange
                controller.onSearchSubmit = onSearchSubmit
                controller.onSearchClear = onSearchClear
                controller.onLeftItemTap = onLeftItemTap
                controller.onRightItemTap = onRightItemTap
                controller.onCameraTap = onCameraTap
                print("📷 [EcoBaseViewController] attachNavigationBar (update) - onCameraTap callback set: \(onCameraTap != nil ? "EXISTS" : "nil")")
                
                // Re-setup search field bindings sau khi callback được update
                if let navBarVC = navigationBarViewController {
                    navBarVC.updateSearchFieldBindings()
                    print("📷 [EcoBaseViewController] attachNavigationBar (update) - Search field bindings updated")
                }
            }
        }

        syncStatusBarStyleFromNavigationBar()
    }

    // MARK: Update

    func updateNavigationBar(
        _ state: EcoNavigationState,
        animated: Bool = true
    ) {
        navigationBarViewController?.updateState(state, animated: animated)

        if let height = state.height {
            updateNavigationBarHeight(height, animated: animated)
        }

        syncStatusBarStyleFromNavigationBar()
    }

    // MARK: Height

    func updateNavigationBarHeight(
        _ height: CGFloat,
        animated: Bool = true
    ) {
        guard let constraint = navigationBarHeightConstraint else { return }

        let update = {
            constraint.constant = height
            self.view.layoutIfNeeded()
        }

        animated
            ? UIView.animate(withDuration: 0.25, animations: update)
            : update()
    }

    // MARK: Detach

    func detachNavigationBar() {
        guard let navBarVC = navigationBarViewController else { return }

        navBarVC.willMove(toParent: nil)
        navBarVC.view.removeFromSuperview()
        navBarVC.removeFromParent()

        navigationBarViewController = nil
        navigationBarHeightConstraint = nil
    }
}


public extension EcoBaseViewController {

    func bindNavigationBar(to scrollView: UIScrollView) {
        scrollView.delegate = self
    }

    func unbindNavigationBar(from scrollView: UIScrollView) {
        if scrollView.delegate === self {
            scrollView.delegate = nil
        }
    }
    
    /// Access to navigation bar controller for advanced usage
    var navigationBarController: EcoNavigationBarController? {
        navigationBarViewController?.controller
    }
    
    /// Get navigation bar height for layout calculations
    var navigationBarHeight: CGFloat {
        guard let navBarVC = navigationBarViewController else {
            return 0
        }
        // Use frame height if available (after layout), otherwise use constraint constant or default
        if navBarVC.view.frame.height > 0 {
            return navBarVC.view.frame.height
        }
        // Try to get from state height or use default
        if let stateHeight = navBarVC.controller.state.value.height {
            return stateHeight
        }
        return EcoNavigationBarMetrics.barHeight
    }
}

extension EcoBaseViewController: UIScrollViewDelegate {

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        navigationBarViewController?.handleScroll(
            offset: scrollView.contentOffset.y
        )
    }
}

// MARK: - UIGestureRecognizerDelegate

extension EcoBaseViewController: UIGestureRecognizerDelegate {
    
    // Allow interactive pop gesture to work simultaneously with scroll view
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Allow pop gesture to work with scroll view gestures
        if gestureRecognizer === navigationController?.interactivePopGestureRecognizer {
            print("🔵 [EcoBaseViewController] shouldRecognizeSimultaneouslyWith - allowing pop gesture with scroll")
            return true
        }
        
        // Allow dismiss keyboard gesture to work simultaneously with other gestures
        if gestureRecognizer === dismissKeyboardTapGesture {
            return true
        }
        
        return false
    }
    
    // Make scroll gesture fail when pop gesture should work (at top and swiping from left)
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // If pop gesture, require scroll view pan gesture to fail when at top and swiping from left
        if gestureRecognizer === navigationController?.interactivePopGestureRecognizer,
           let panGesture = otherGestureRecognizer as? UIPanGestureRecognizer,
           let scrollView = panGesture.view as? UIScrollView {
            let isAtTop = scrollView.contentOffset.y <= 0
            if isAtTop {
                // Check if swipe is from left edge
                let location = panGesture.location(in: view)
                let isFromLeftEdge = location.x < 50 // Within 50pt from left edge
                print("🔵 [EcoBaseViewController] shouldBeRequiredToFailBy - scrollView pan at top: \(isAtTop), from left: \(isFromLeftEdge)")
                return isFromLeftEdge
            }
        }
        return false
    }
    
    // Allow pop gesture to begin
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === navigationController?.interactivePopGestureRecognizer {
            // Only allow if there's more than one view controller
            let shouldBegin = (navigationController?.viewControllers.count ?? 0) > 1
            print("🔵 [EcoBaseViewController] gestureRecognizerShouldBegin - interactivePopGestureRecognizer: \(shouldBegin), viewControllers.count: \(navigationController?.viewControllers.count ?? 0)")
            return shouldBegin
        }
        return true
    }
    
    // Check if touch is at left edge (for pop gesture)
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer === navigationController?.interactivePopGestureRecognizer {
            let location = touch.location(in: view)
            let isAtLeftEdge = location.x < 20 // Within 20pt from left edge
            print("🔵 [EcoBaseViewController] shouldReceive touch - location: \(location), isAtLeftEdge: \(isAtLeftEdge)")
            return true // Always allow, but log for debugging
        }
        
        // For dismiss keyboard tap gesture, only dismiss if not tapping on a control
        if gestureRecognizer === dismissKeyboardTapGesture {
            let location = touch.location(in: view)
            let hitView = view.hitTest(location, with: nil)
            // Don't dismiss if tapping on button, text field, text view, or other interactive controls
            if let hitView = hitView {
                if hitView is UIControl || hitView is UITextField || hitView is UITextView {
                    return false
                }
                // Check if the view is part of navigation bar
                if let navBarView = navigationBarViewController?.view,
                   hitView.isDescendant(of: navBarView) {
                    return false
                }
            }
            return true
        }
        
        return true
    }
}
