//
//  MainContainerViewController.swift
//  ECommerce
//
//  Created by wizard.os25 on 18/11/25.
//

import UIKit

class MainContainerViewController: UIViewController {
    
    // MARK: - Properties
    
    // Content Layer: TabBarController
    internal var mainTabBarController: TabBarController!
    
    // SideMenu Layer: SideMenuViewController
    private var sideMenuViewController: SideMenuViewController!
    private var sideMenuController: SideMenuController!
    
    // Side Menu Configuration
    private var sideMenuRevealWidth: CGFloat = 260
    private let paddingForRotation: CGFloat = 150
    private var isExpanded: Bool = false
    private var sideMenuTrailingConstraint: NSLayoutConstraint!
    private var tabBarControllerLeadingConstraint: NSLayoutConstraint!
    private var revealSideMenuOnTop: Bool = false // side-in
    
    // Shadow View
    private var sideMenuShadowView: UIView!
    
    // Gesture Handling
    private var draggingIsEnabled: Bool = false
    private var panBaseLocation: CGFloat = 0.0
    
    // Store original gesture recognizer states to restore later
    private var originalGestureStates: [UIGestureRecognizer: Bool] = [:]
    
    // Flag to track if AddressViewController or ProfileViewController is opened from side menu
    private var didOpenFromSideMenu: Bool = false
    
    // ✅ QUAN TRỌNG: Flag để phân biệt khi push từ màn hình trong UIPageViewController
    // Ví dụ: từ ProductViewController sang ProductDetailViewController
    // Khi flag này được set, không cho phép sidebar gesture hoạt động
    private var isPushedFromPageViewController: Bool = false
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupSideMenu()
        setupTabBarController()
        setupGestures()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Ensure side menu is closed when view appears
        // This helps prevent side menu from staying open after swipe back
        if didOpenFromSideMenu {
            // Check if AddressViewController still exists in navigation stack
            if let nav = mainTabBarController?.selectedViewController as? UINavigationController {
                let hasAddressViewController = nav.viewControllers.contains { $0 is AddressViewController }
                if !hasAddressViewController && (isExpanded || sideMenuShadowView.alpha > 0) {
                    // AddressViewController no longer in stack, ensure side menu is closed
                    sideMenuState(expanded: false)
                    sideMenuShadowView.alpha = 0.0
                    didOpenFromSideMenu = false
                }
            }
        }
        
        // ✅ QUAN TRỌNG: Cập nhật flag khi view appear
        updatePushedFromPageViewControllerFlag()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Request push notification permission on first time entering main screen
        requestPushNotificationPermissionIfNeeded()
    }
    
    /// Request push notification permission only on first time
    private func requestPushNotificationPermissionIfNeeded() {
        let defaults = UserDefaults.standard
        let hasRequestedBefore = defaults.bool(forKey: Constants.UserDefaultsKey.pushNotificationPermissionRequested)
        
        // Only request if haven't requested before
        if !hasRequestedBefore {
            
            // Mark as requested
            defaults.set(true, forKey: Constants.UserDefaultsKey.pushNotificationPermissionRequested)
            
            // Request permission with a small delay to ensure UI is ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                AppDelegate.requestPushNotificationPermission()
            }
        }
    }
    
    // MARK: - Setup Methods
    
    private func setupView() {
        view.backgroundColor = #colorLiteral(red: 0, green: 0.375862439, blue: 1, alpha: 1)
    }
    
    private func setupSideMenu() {
        // Create SideMenuController first
        sideMenuController = DefaultSideMenuController()
        
        // Set logout callback
        sideMenuController.onLogout = { [weak self] in
            self?.handleLogout()
        }
        
        // Set navigate to shipping address callback
        sideMenuController.onNavigateToShippingAddress = { [weak self] in
            self?.handleNavigateToShippingAddress()
        }
        
        // Set navigate to profile callback
        sideMenuController.onNavigateToProfile = { [weak self] in
            self?.handleNavigateToProfile()
        }
        
        // Set navigate to payment callback
        sideMenuController.onNavigateToPayment = { [weak self] in
            self?.handleNavigateToPayment()
        }
        
        // Set navigate to order callback
        sideMenuController.onNavigateToOrder = { [weak self] in
            self?.handleNavigateToOrder()
        }
        
        // Create SideMenuViewController with controller using factory method
        sideMenuViewController = SideMenuViewController.create(with: sideMenuController)
        
        // Add SideMenu as child view controller (at index 0 - below TabBarController)
        addChild(sideMenuViewController)
        view.insertSubview(sideMenuViewController.view, at: revealSideMenuOnTop ? 2 : 0)
        sideMenuViewController.didMove(toParent: self)
        
        // Setup SideMenu constraints
        sideMenuViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        if revealSideMenuOnTop {
            sideMenuTrailingConstraint = sideMenuViewController.view.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: -sideMenuRevealWidth - paddingForRotation
            )
            sideMenuTrailingConstraint.isActive = true
        } else {
            sideMenuTrailingConstraint = sideMenuViewController.view.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: -sideMenuRevealWidth // Hidden to the left initially
            )
            sideMenuTrailingConstraint.isActive = true
        }
        
        NSLayoutConstraint.activate([
            sideMenuViewController.view.widthAnchor.constraint(equalToConstant: sideMenuRevealWidth),
            sideMenuViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sideMenuViewController.view.topAnchor.constraint(equalTo: view.topAnchor)
        ])
    }
    
    private func setupTabBarController() {
        // Create TabBarController
        mainTabBarController = TabBarController()
        
        // Add TabBarController as child view controller
        addChild(mainTabBarController)
        view.insertSubview(mainTabBarController.view, at: revealSideMenuOnTop ? 0 : 1)
        mainTabBarController.didMove(toParent: self)
        
        // Setup TabBarController constraints
        mainTabBarController.view.translatesAutoresizingMaskIntoConstraints = false
        
        if revealSideMenuOnTop {
            NSLayoutConstraint.activate([
                mainTabBarController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                mainTabBarController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                mainTabBarController.view.topAnchor.constraint(equalTo: view.topAnchor),
                mainTabBarController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        } else {
            // Side-in mode: TabBarController can move to the right but keeps full width
            tabBarControllerLeadingConstraint = mainTabBarController.view.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 0 // Starts at 0, will move to sideMenuRevealWidth when menu opens
            )
            tabBarControllerLeadingConstraint.isActive = true
            
            NSLayoutConstraint.activate([
                // Use width constraint instead of trailing to keep full screen width
                mainTabBarController.view.widthAnchor.constraint(equalTo: view.widthAnchor),
                mainTabBarController.view.topAnchor.constraint(equalTo: view.topAnchor),
                mainTabBarController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }
        
        // Setup shadow view for TabBarController
        setupShadowView()
    }
    
    private func setupShadowView() {
        sideMenuShadowView = UIView(frame: view.bounds)
        sideMenuShadowView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        sideMenuShadowView.backgroundColor = .black
        sideMenuShadowView.alpha = 0.0
        
        // Add to mainTabBarController.view in both modes (keeps consistent)
        mainTabBarController.view.addSubview(sideMenuShadowView)
        sideMenuShadowView.frame = mainTabBarController.view.bounds
    }
    
    private func setupGestures() {
        // Add pan gesture to TabBarController view
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
        panGestureRecognizer.delegate = self
        panGestureRecognizer.cancelsTouchesInView = false
        mainTabBarController.view.addGestureRecognizer(panGestureRecognizer)
        
        // Add tap gesture to close menu
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
        tapGestureRecognizer.numberOfTapsRequired = 1
        tapGestureRecognizer.delegate = self
        tapGestureRecognizer.cancelsTouchesInView = false
        mainTabBarController.view.addGestureRecognizer(tapGestureRecognizer)
        
        // Add gestures to each navigation controller (so gestures work when nav controller covers screen)
        if let viewControllers = mainTabBarController.viewControllers {
            for viewController in viewControllers {
                if let navController = viewController as? UINavigationController {
                    let navPanGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
                    navPanGesture.delegate = self
                    navPanGesture.cancelsTouchesInView = false
                    navController.view.addGestureRecognizer(navPanGesture)
                    
                    let navTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
                    navTapGesture.numberOfTapsRequired = 1
                    navTapGesture.delegate = self
                    navTapGesture.cancelsTouchesInView = false
                    navController.view.addGestureRecognizer(navTapGesture)
                }
            }
        }
    }
    
    // MARK: - Side Menu Control
    
    @objc open func revealSideMenu() {
        sideMenuState(expanded: isExpanded ? false : true)
    }
    
    private func sideMenuState(expanded: Bool, completion: ((Bool) -> Void)? = nil) {
        if expanded {
            // Open menu: Side menu moves to 0, TabBarController moves to sideMenuRevealWidth
            // Hide TabBar when sideMenu opens
            mainTabBarController.hideTabBar()
            animateSideMenu(targetPosition: revealSideMenuOnTop ? 0 : 0, tabBarPosition: revealSideMenuOnTop ? 0 : sideMenuRevealWidth) { finished in
                self.isExpanded = true
                completion?(finished)
            }
            UIView.animate(withDuration: 0.5) {
                self.sideMenuShadowView.alpha = 0.6
            }
        } else {
            // Close menu: Side menu moves to -sideMenuRevealWidth, TabBarController moves to 0
            // Show TabBar when sideMenu closes (only if at root)
            animateSideMenu(targetPosition: revealSideMenuOnTop ? (-sideMenuRevealWidth - paddingForRotation) : -sideMenuRevealWidth, tabBarPosition: revealSideMenuOnTop ? 0 : 0) { finished in
                self.isExpanded = false
                // Show TabBar only if at root of selected navigation controller
                self.mainTabBarController.showTabBar()
                completion?(finished)
            }
            UIView.animate(withDuration: 0.5) {
                self.sideMenuShadowView.alpha = 0.0
            }
        }
    }
    
    private func animateSideMenu(targetPosition: CGFloat, tabBarPosition: CGFloat, completion: @escaping (Bool) -> ()) {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0, options: .layoutSubviews, animations: {
            if self.revealSideMenuOnTop {
                self.sideMenuTrailingConstraint.constant = targetPosition
                self.view.layoutIfNeeded()
            } else {
                // Side-in mode: Move both side menu and TabBarController
                self.sideMenuTrailingConstraint.constant = targetPosition
                self.tabBarControllerLeadingConstraint.constant = tabBarPosition
                self.view.layoutIfNeeded()
            }
        }, completion: completion)
    }
    
    // MARK: - Rotation Handling
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate { _ in
            if self.revealSideMenuOnTop {
                self.sideMenuTrailingConstraint.constant = self.isExpanded ? 0 : (-self.sideMenuRevealWidth - self.paddingForRotation)
            } else {
                // Side-in mode: Update both constraints
                self.sideMenuTrailingConstraint.constant = self.isExpanded ? 0 : -self.sideMenuRevealWidth
                self.tabBarControllerLeadingConstraint.constant = self.isExpanded ? self.sideMenuRevealWidth : 0
            }
        }
    }
}


// MARK: - SideMenuViewControllerDelegate

//extension MainContainerViewController: SideMenuViewControllerDelegate {
//    func selectedCell(_ row: Int) {
//        switch row {
//        case 0:
//            mainTabBarController.selectedIndex = 0
//        case 1:
//            mainTabBarController.selectedIndex = 1
//        case 2:
//            mainTabBarController.selectedIndex = 2
//        case 3:
//            mainTabBarController.selectedIndex = 3
//        default:
//            break
//        }
//        
//        // Collapse side menu
//        DispatchQueue.main.async {
//            self.sideMenuState(expanded: false)
//        }
//    }
//}

// MARK: - UIGestureRecognizerDelegate

extension MainContainerViewController: UIGestureRecognizerDelegate {
    
    @objc private func handleTapGesture(sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            if isExpanded {
                sideMenuState(expanded: false)
            }
        }
    }
    
    // Avoid intercepting taps that should go to SideMenu hoặc UITableView (chỉ trong ProductsViewController)
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let pt = touch.location(in: self.view)
        let touchedView = self.view.hitTest(pt, with: nil)
        
        // ✅ QUAN TRỌNG: Chỉ block UITableView trong ProductsViewController
        // KHÔNG block UICollectionView trong ProductDetailViewController
        // Kiểm tra xem có phải UICollectionView không - nếu có thì không block (cho phép scroll)
        var isInCollectionView = false
        var currentView: UIView? = touchedView
        while currentView != nil {
            if currentView is UICollectionView {
                isInCollectionView = true
                break
            }
            currentView = currentView?.superview
        }
        
        // Nếu touch trong UICollectionView → không block (cho phép scroll trong ProductDetail)
        if isInCollectionView {
            return true // Cho phép gesture hoạt động, nhưng sẽ được filter trong gestureRecognizerShouldBegin
        }
        
        // Chỉ kiểm tra UITableView
        var isInTableView = false
        currentView = touchedView
        while currentView != nil {
            if currentView is UITableView {
                isInTableView = true
                break
            }
            currentView = currentView?.superview
        }
        
        // Nếu touch trong tableView và KHÔNG từ left edge → không intercept
        if isInTableView && pt.x > 30 {
            return false
        }
        
        // Convert touch point to root view coordinates and check if it's inside side menu view
        if let menuView = sideMenuViewController?.view,
           menuView.convert(menuView.bounds, to: self.view).contains(pt) {
            return false
        }
        return true
    }
    
    // We generally don't want simultaneous recognition for this design
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // ✅ QUAN TRỌNG: Nếu otherGestureRecognizer là interactivePopGestureRecognizer (swipe back),
        // không cho phép simultaneous recognition để ưu tiên swipe back
        if let nav = mainTabBarController?.selectedViewController as? UINavigationController,
           otherGestureRecognizer === nav.interactivePopGestureRecognizer {
            return false
        }
        
        // Allow side menu pan to work with scroll views
        if gestureRecognizer is UIPanGestureRecognizer {
            if otherGestureRecognizer is UIPanGestureRecognizer,
               let otherPan = otherGestureRecognizer as? UIPanGestureRecognizer,
               let scrollView = otherPan.view as? UIScrollView {
                return true
            }
        }
        return false
    }
    
    // ✅ QUAN TRỌNG: Yêu cầu PageViewController scrollView gesture phải fail
    // khi ở page 0 (Home) và swipe right, để container gesture có thể xử lý
    // HOẶC khi tap gesture được detect (để tap hoạt động)
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // ✅ QUAN TRỌNG: SideMenu pan gesture phải FAIL khi interactivePopGestureRecognizer (swipe back) cần hoạt động
        // Điều này đảm bảo swipe back gesture luôn được ưu tiên khi có màn hình được push
        if gestureRecognizer is UIPanGestureRecognizer,
           let nav = mainTabBarController?.selectedViewController as? UINavigationController,
           otherGestureRecognizer === nav.interactivePopGestureRecognizer {
            // Kiểm tra xem có màn hình nào được push không (viewControllers.count > 1)
            if nav.viewControllers.count > 1 {
                return true
            }
        }
        
        // ✅ QUAN TRỌNG: Nếu otherGestureRecognizer là tap gesture → yêu cầu PageViewController pan gesture fail
        // Điều này đảm bảo tap gesture có priority và hoạt động ngay
        if otherGestureRecognizer is UITapGestureRecognizer {
            // Kiểm tra xem gestureRecognizer có phải là từ PageViewController scrollView không
            guard let panGesture = gestureRecognizer as? UIPanGestureRecognizer,
                  let scrollView = panGesture.view as? UIScrollView else {
                return false
            }
            
            // Kiểm tra xem scrollView có phải từ PageViewController không
            guard let nav = mainTabBarController?.selectedViewController as? UINavigationController,
                  let contentVC = nav.viewControllers.first(where: { $0 is ContentViewController }) as? ContentViewController else {
                return false
            }
            
            guard let pageViewController = contentVC.children.first(where: { $0 is UIPageViewController }) as? UIPageViewController,
                  scrollView.isDescendant(of: pageViewController.view) else {
                return false
            }
            
            return true
        }
        
        // Kiểm tra xem gesture khác có phải là từ PageViewController scrollView không
        guard let otherPan = otherGestureRecognizer as? UIPanGestureRecognizer,
              let scrollView = otherPan.view as? UIScrollView else {
            return false
        }
        
        // Kiểm tra xem scrollView có phải từ PageViewController không
        guard let nav = mainTabBarController?.selectedViewController as? UINavigationController,
              let contentVC = nav.viewControllers.first(where: { $0 is ContentViewController }) as? ContentViewController else {
            return false
        }
        
        // ContentViewController chứa SegmentedPageContainer
        // SegmentedPageContainer addChild UIPageViewController vào ContentViewController
        // Tìm UIPageViewController trong children của ContentViewController
        guard let pageViewController = contentVC.children.first(where: { $0 is UIPageViewController }) as? UIPageViewController,
              scrollView.isDescendant(of: pageViewController.view) else {
            return false
        }
        
        // Lấy thông tin về page hiện tại
        let currentPageIndex = contentVC.currentPageIndex
        
        // ✅ QUAN TRỌNG: shouldBeRequiredToFailBy được gọi rất sớm, velocity có thể = 0
        // Thay vào đó, chỉ kiểm tra page index và location
        // Nếu ở page 0 (Home) và swipe từ cạnh trái → Yêu cầu scrollView gesture FAIL
        if currentPageIndex == 0 {
            let location = otherPan.location(in: self.view)
            // Nếu swipe từ cạnh trái (x < 100) → Yêu cầu scrollView gesture FAIL
            if location.x < 100 {
                return true
            }
        }
        
        return false
    }
    
    // Decide whether a pan gesture should begin (important central logic)
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let panGesture = gestureRecognizer as? UIPanGestureRecognizer else {
            return true
        }
        
        // ✅ QUAN TRỌNG: Kiểm tra flag isPushedFromPageViewController
        // Nếu được push từ UIPageViewController (ví dụ ProductDetailViewController), không cho phép sidebar gesture
        updatePushedFromPageViewControllerFlag()
        if isPushedFromPageViewController {
            return false
        }
        
        // Use root view coords for location & velocity to keep checks consistent
        let locationInRoot = panGesture.location(in: self.view)
        let velocityInRoot = panGesture.velocity(in: self.view)
        let vx = velocityInRoot.x
        
        // ✅ GIẢI PHÁP CHÍNH: Kiểm tra tabbar visibility
        // Nếu tabbar đang ẩn (isHidden = true) → đã push vào màn hình khác → chỉ cho phép swipe back, không cho mở SideMenu
        let isTabBarVisible = !(mainTabBarController?.tabBar.isHidden ?? true)
        
        // Check if current top view controller is AddressViewController
        let isTopAddressViewController = {
            guard let nav = mainTabBarController?.selectedViewController as? UINavigationController,
                  let topVC = nav.topViewController else { return false }
            return topVC is AddressViewController
        }()
        
        // Check if current top view controller is ProfileViewController
        let isTopProfileViewController = {
            guard let nav = mainTabBarController?.selectedViewController as? UINavigationController,
                  let topVC = nav.topViewController else { return false }
            return topVC is ProfileViewController
        }()
        
        // Check if current top view controller is PaymentCardViewController
        let isTopPaymentCardViewController = {
            guard let nav = mainTabBarController?.selectedViewController as? UINavigationController,
                  let topVC = nav.topViewController else { return false }
            return topVC is PaymentCardViewController
        }()
        
        // Check if current top view controller is OrderContainerViewController
        let isTopOrderContainerViewController = {
            guard let nav = mainTabBarController?.selectedViewController as? UINavigationController,
                  let topVC = nav.topViewController else { return false }
            return topVC is OrderContainerViewController
        }()
        
        // Check if any view controller in the navigation stack was opened after AddressViewController, ProfileViewController or PaymentCardViewController (when flag is set)
        // This includes MapViewController, EditProfileViewController and any other screens pushed after them
        let hasViewControllersAfterSideMenuVC = {
            guard didOpenFromSideMenu,
                  let nav = mainTabBarController?.selectedViewController as? UINavigationController,
                  nav.viewControllers.count >= 2 else { return false }
            
            // Find AddressViewController, ProfileViewController, PaymentCardViewController or OrderContainerViewController index in the stack
            let addressVCIndex = nav.viewControllers.firstIndex(where: { $0 is AddressViewController })
            let profileVCIndex = nav.viewControllers.firstIndex(where: { $0 is ProfileViewController })
            let paymentCardVCIndex = nav.viewControllers.firstIndex(where: { $0 is PaymentCardViewController })
            let orderContainerVCIndex = nav.viewControllers.firstIndex(where: { $0 is OrderContainerViewController })
            
            // Get the minimum index (the one that was opened first)
            let sideMenuVCIndex: Int?
            let indices = [addressVCIndex, profileVCIndex, paymentCardVCIndex, orderContainerVCIndex].compactMap { $0 }
            if !indices.isEmpty {
                sideMenuVCIndex = indices.min()
            } else {
                sideMenuVCIndex = nil
            }
            
            guard let vcIndex = sideMenuVCIndex else {
                return false
            }
            
            // If topViewController is not the side menu VC, it means some screen was pushed after it
            // All screens pushed after the side menu VC should block side menu gesture
            let topVCIndex = nav.viewControllers.count - 1
            let result = topVCIndex > vcIndex
            
            // Debug logging
            if result {
                let stackDescription = nav.viewControllers.map { String(describing: type(of: $0)) }.joined(separator: " -> ")
            }
            
            return result
        }()
        
        let translation = panGesture.translation(in: self.view)
        
        // If menu is expanded, allow pan (to close)
        if isExpanded {
            return true
        }
        
        // ✅ GIẢI PHÁP CHÍNH: Nếu tabbar đang ẩn → đã push vào màn hình khác → block SideMenu gesture, chỉ cho phép swipe back
        if !isTabBarVisible {
            return false
        }
        
        // ✅ Nếu tabbar visible và đang ở các màn hình đặc biệt (Address, Profile, PaymentCard, OrderContainer)
        // Kiểm tra didOpenFromSideMenu để quyết định behavior
        if isTopAddressViewController || isTopProfileViewController || isTopPaymentCardViewController || isTopOrderContainerViewController {
            if didOpenFromSideMenu {
                // Opened from side menu: block side menu gesture (let swipe back handle)
                let vcName: String
                if isTopAddressViewController {
                    vcName = "AddressViewController"
                } else if isTopProfileViewController {
                    vcName = "ProfileViewController"
                } else if isTopPaymentCardViewController {
                    vcName = "PaymentCardViewController"
                } else {
                    vcName = "OrderContainerViewController"
                }
                return false
            } else {
                // NOT opened from side menu: allow side menu gesture (drag from left edge opens side menu)
                let vcName: String
                if isTopAddressViewController {
                    vcName = "AddressViewController"
                } else if isTopProfileViewController {
                    vcName = "ProfileViewController"
                } else if isTopPaymentCardViewController {
                    vcName = "PaymentCardViewController"
                } else {
                    vcName = "OrderContainerViewController"
                }
                // Continue with normal side menu gesture logic below
            }
        }
        
        // If any view controller was pushed after AddressViewController or ProfileViewController (when flag is set),
        // block side menu gesture to allow swipe back for all screens in that navigation flow
        if hasViewControllersAfterSideMenuVC {
            return false
        }
        
        // ✅ QUAN TRỌNG: Chỉ block UITableView trong ProductsViewController
        // KHÔNG block UICollectionView trong ProductDetailViewController
        let touchedView = self.view.hitTest(locationInRoot, with: nil)
        
        // ✅ QUAN TRỌNG: Nếu touch trong UICollectionView → KHÔNG block để cho phép scroll
        // UICollectionView trong ProductDetail cần scroll tự do
        var isInCollectionView = false
        var currentView: UIView? = touchedView
        while currentView != nil {
            if currentView is UICollectionView {
                isInCollectionView = true
                break
            }
            currentView = currentView?.superview
        }
        
        // Nếu touch trong UICollectionView → không block (cho phép scroll trong ProductDetail)
        if isInCollectionView {
            return false // Không block để cho phép UICollectionView scroll tự do
        }
        
        // Chỉ kiểm tra UITableView
        var isInTableView = false
        currentView = touchedView
        while currentView != nil {
            if currentView is UITableView {
                isInTableView = true
                break
            }
            currentView = currentView?.superview
        }
        
        // Nếu touch trong tableView và KHÔNG từ left edge → block để cho tableView xử lý
        if isInTableView && locationInRoot.x > 30 {
            return false
        }
        
        // If touch is inside side menu area, don't intercept
        if let menuView = sideMenuViewController?.view,
           menuView.convert(menuView.bounds, to: self.view).contains(locationInRoot) {
            return false
        }
        
        // Find inner page scroll view (if exists) and current page index (via ContentViewController API)
        if let (scrollView, currentPageIndex) = findInnerScrollViewAndPageIndex(from: panGesture) {
            
            // If the gesture started inside the page scrollView bounds, consider letting inner scroll handle it
            let gestureStartedInScroll = {
                // location relative to scrollView
                let local = panGesture.location(in: scrollView)
                return scrollView.bounds.contains(local)
            }()
            
            
            if gestureStartedInScroll {
                // If inner scroll cannot scroll horizontally (single page) — let container handle
                let canScrollHorizontally = scrollView.contentSize.width > scrollView.frame.width + 0.5
                let scrollOffset = scrollView.contentOffset.x
                
                if !canScrollHorizontally {
                    return true
                }
                
                // If current page is NOT the left-most, prefer inner scroll to handle horizontal gestures
                if currentPageIndex != 0 {
                    // However, if the inner scroll is at its left edge and user swipes right, allow container takeover
                    let atLeftEdge = scrollOffset <= 0.5
                    if atLeftEdge || vx > 0 {
                        return true
                    }
                    return false // inner page handles it
                } else {
                    // currentPageIndex == 0 (Home)
                    // ✅ QUAN TRỌNG: Ở page 0, nếu scrollOffset gần 0 (trong phạm vi 1 page width)
                    // thì coi như đang ở left edge và cho phép container xử lý right swipe
                    let pageWidth = scrollView.frame.width
                    let atLeftEdge = scrollOffset <= pageWidth + 10 // Cho phép một chút tolerance
                    
                    // ✅ QUAN TRỌNG: Chỉ allow khi thực sự là swipe (có velocity hoặc translation)
                    // Không allow khi chỉ là tap (vx = 0 và translation nhỏ)
                    let translation = panGesture.translation(in: self.view)
                    let hasMovement = abs(vx) > 50 || abs(translation.x) > 10
                    
                    if atLeftEdge && hasMovement && vx > 0 {
                        return true
                    }
                    
                    // If user is swiping left (to go to next page) → prefer inner scroll
                    if vx < -50 {
                        return false
                    }
                    
                    // ✅ Nếu không có movement (tap), block để cho tap gesture hoạt động
                    if !hasMovement {
                        return false
                    }
                    
                    // ✅ Nếu ở page 0 và velocity > 0 (right swipe) nhưng không ở left edge
                    // Vẫn cho phép container xử lý nếu velocity đủ hoặc location từ cạnh trái
                    // (fallthrough to edge checks below)
                }
            }
            // If gesture didn't start in the scrollView's bounds, continue with edge/velocity checks below
        }
        
        // ✅ QUAN TRỌNG: Kiểm tra movement để phân biệt tap và swipe
        // Note: translation đã được khai báo ở dòng 462
        let hasMovement = abs(vx) > 50 || abs(translation.x) > 10
        
        // Nếu không có movement (tap), block để cho tap gesture hoạt động
        if !hasMovement {
            return false
        }
        
        // Allow right swipe from left edge (first 80 points)
        if locationInRoot.x < 80 && vx > 0 {
            return true
        }
        
        // ✅ Nếu đang ở page 0, cho phép right swipe với velocity thấp hơn
        if let (_, currentPageIndex) = findInnerScrollViewAndPageIndex(from: panGesture), currentPageIndex == 0 {
            if vx > 0 && vx > 30 { // Lower threshold for page 0
                return true
            }
        }
        
        // Allow sufficiently fast right swipes anywhere
        if vx > 200 {
            return true
        }
        
        return false
    }
    
    // Helper: Try to find the inner UIScrollView of PageViewController and the current page index (if any).
    // Returns (scrollView, currentPageIndex) or nil if not found.
    // 
    // Hierarchy: ContentViewController -> SegmentedPageContainer -> UIPageViewController (as child) -> UIScrollView (internal)
    private func findInnerScrollViewAndPageIndex(from panGesture: UIPanGestureRecognizer) -> (UIScrollView, Int)? {
        // 1. Get current nav and ContentViewController
        guard let nav = mainTabBarController?.selectedViewController as? UINavigationController,
              let contentVC = nav.viewControllers.first(where: { $0 is ContentViewController }) as? ContentViewController
        else {
            return nil
        }
        
        // 2. SegmentedPageContainer addChild UIPageViewController vào ContentViewController
        // (Trong SegmentedPageContainer.setupPageViewController(), gọi parent.addChild(pageViewController))
        // Vậy UIPageViewController sẽ là child của ContentViewController
        guard let pageVC = contentVC.children.first(where: { $0 is UIPageViewController }) as? UIPageViewController else {
            return nil
        }
        
        // 3. Find UIScrollView inside pageVC.view.subviews
        // UIPageViewController có internal UIScrollView để scroll giữa các pages
        guard let scrollView = pageVC.view.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView else {
            return nil
        }
        
        // 4. Obtain current page index via ContentViewController API
        // ContentViewController.currentPageIndex lấy từ SegmentedPageContainer.currentIndex
        let currentPageIndex = contentVC.currentPageIndex
        return (scrollView, currentPageIndex)
    }
    
    // ✅ QUAN TRỌNG: Cập nhật flag isPushedFromPageViewController
    // Kiểm tra xem topViewController có phải ProductDetailViewController không
    // và có phải được push từ ProductsViewController (trong UIPageViewController) không
    private func updatePushedFromPageViewControllerFlag() {
        guard let nav = mainTabBarController?.selectedViewController as? UINavigationController,
              let topVC = nav.topViewController else {
            isPushedFromPageViewController = false
            return
        }
        
        // Kiểm tra xem topViewController có phải ProductDetailViewController không
        let isProductDetail = topVC is ProductDetailViewController
        
        if isProductDetail {
            // Kiểm tra xem có ProductsViewController trong navigation stack không
            // Nếu có, nghĩa là được push từ ProductsViewController (trong UIPageViewController)
            let hasProductsViewController = nav.viewControllers.contains { $0 is ProductsViewController }
            isPushedFromPageViewController = hasProductsViewController
            
            if isPushedFromPageViewController {
            }
        } else {
            // Không phải ProductDetailViewController → reset flag
            isPushedFromPageViewController = false
        }
    }
    
    /// Disable tất cả các gesture khác khi đang vuốt trái mở side menu
    private func disableOtherGestures() {
        guard let nav = mainTabBarController?.selectedViewController as? UINavigationController,
              let topVC = nav.topViewController else { return }
        
        // Tìm tất cả gesture recognizers trong view hierarchy
        let allGestures = findAllGestureRecognizers(in: topVC.view)
        
        // Lưu trạng thái hiện tại và disable
        for gesture in allGestures {
            // Bỏ qua pan gesture của side menu
            if gesture.view == mainTabBarController?.view || gesture.view == sideMenuViewController?.view {
                continue
            }
            
            originalGestureStates[gesture] = gesture.isEnabled
            gesture.isEnabled = false
        }
        
    }
    
    /// Enable lại tất cả các gesture đã disable
    private func enableOtherGestures() {
        // Restore original states
        for (gesture, wasEnabled) in originalGestureStates {
            gesture.isEnabled = wasEnabled
        }
        originalGestureStates.removeAll()
        
    }
    
    /// Recursively find all gesture recognizers in a view hierarchy
    private func findAllGestureRecognizers(in view: UIView) -> [UIGestureRecognizer] {
        var gestures: [UIGestureRecognizer] = []
        
        // Add gestures from current view
        gestures.append(contentsOf: view.gestureRecognizers ?? [])
        
        // Recursively find in subviews
        for subview in view.subviews {
            gestures.append(contentsOf: findAllGestureRecognizers(in: subview))
        }
        
        return gestures
    }
    
    @objc private func handlePanGesture(sender: UIPanGestureRecognizer) {
        let gestureView = sender.view ?? self.view
        let position: CGFloat = sender.translation(in: gestureView).x
        let velocity: CGFloat = sender.velocity(in: gestureView).x
        
        
        switch sender.state {
        case .began:
            // Khi bắt đầu vuốt trái mở side menu, disable tất cả các gesture khác
            disableOtherGestures()
            
        case .ended, .cancelled, .failed:
            // Khi kết thúc gesture, enable lại các gesture khác
            enableOtherGestures()
            
        default:
            break
        }
        
        switch sender.state {
        case .began:
            // If gesture originates from an inner page scroll view that should handle it, skip container drag
            let isInsidePageScroll = isGestureInsidePageScrollView(sender)
            
            if isInsidePageScroll {
                draggingIsEnabled = false
                return
            }
            
            
            // If user tries to expand while already expanded and swipes right, cancel (no extra expand)
            if velocity > 0, isExpanded {
                sender.state = .cancelled
                return
            }
            
            // Enable dragging when swiping right to open (and not expanded) OR swiping left to close (when expanded)
            if velocity > 0, !isExpanded {
                draggingIsEnabled = true
            } else if velocity < 0, isExpanded {
                draggingIsEnabled = true
            }
            
            if draggingIsEnabled {
                // If swipe is sufficiently fast, complete toggle immediately
                let velocityThreshold: CGFloat = 550
                if abs(velocity) > velocityThreshold {
                    sideMenuState(expanded: isExpanded ? false : true)
                    draggingIsEnabled = false
                    return
                }
                
                panBaseLocation = isExpanded ? sideMenuRevealWidth : 0.0
            }
            
        case .changed:
            // Expand/Collapse side menu while dragging
            if draggingIsEnabled {
                if revealSideMenuOnTop {
                    // Show/Hide shadow background view while dragging
                    let xLocation: CGFloat = panBaseLocation + position
                    let percentage = max(0, min(xLocation / sideMenuRevealWidth, 1.0))
                    let alpha = percentage >= 0.6 ? 0.6 : percentage
                    sideMenuShadowView.alpha = alpha
                    
                    // Move side menu while dragging
                    if xLocation <= sideMenuRevealWidth {
                        sideMenuTrailingConstraint.constant = xLocation - sideMenuRevealWidth
                    }
                } else {
                    // Side-in mode: Move both side menu and TabBarController
                    let xLocation: CGFloat = panBaseLocation + position
                    let clampedX = max(0, min(xLocation, sideMenuRevealWidth))
                    
                    let percentage = clampedX / sideMenuRevealWidth
                    let alpha = percentage >= 0.6 ? 0.6 : percentage
                    sideMenuShadowView.alpha = alpha
                    
                    sideMenuTrailingConstraint.constant = clampedX - sideMenuRevealWidth
                    tabBarControllerLeadingConstraint.constant = clampedX
                }
            }
            
        case .ended, .cancelled, .failed:
            // Reset dragging flag and decide final state based on threshold
            if draggingIsEnabled {
                draggingIsEnabled = false
                if revealSideMenuOnTop {
                    let movedMoreThanHalf = sideMenuTrailingConstraint.constant > -(sideMenuRevealWidth * 0.5)
                    sideMenuState(expanded: movedMoreThanHalf)
                } else {
                    let movedMoreThanHalf = tabBarControllerLeadingConstraint.constant > (sideMenuRevealWidth * 0.5)
                    sideMenuState(expanded: movedMoreThanHalf)
                }
            } else {
                draggingIsEnabled = false
            }
            
        default:
            break
        }
    }
    
    // This function determines whether the pan gesture originates from a PageViewController's UIScrollView
    // that should keep handling the gesture (return true) or not.
    // 
    // Hierarchy: ContentViewController -> SegmentedPageContainer -> UIPageViewController (as child) -> UIScrollView (internal)
    func isGestureInsidePageScrollView(_ gesture: UIPanGestureRecognizer) -> Bool {
        // 1. Get current nav and ContentViewController
        guard let nav = mainTabBarController?.selectedViewController as? UINavigationController,
              let contentVC = nav.viewControllers.first(where: { $0 is ContentViewController }) as? ContentViewController
        else {
            return false
        }
        
        // 2. SegmentedPageContainer addChild UIPageViewController vào ContentViewController
        // Tìm UIPageViewController trong children của ContentViewController
        guard let pageVC = contentVC.children.first(where: { $0 is UIPageViewController }) as? UIPageViewController else {
            return false
        }
        
        // 3. Get internal UIScrollView
        guard let scrollView = pageVC.view.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView else {
            return false
        }
        
        // 4. If gesture's start point is inside that scrollView's bounds, and the inner page should handle => return true
        let startPointInScroll = gesture.location(in: scrollView)
        if scrollView.bounds.contains(startPointInScroll) {
            
            // If inner cannot scroll horizontally -> treat as container opportunity
            let canScrollHorizontally = scrollView.contentSize.width > scrollView.frame.width + 0.5
            let scrollOffset = scrollView.contentOffset.x
            let vx = gesture.velocity(in: scrollView).x
            let currentIndex = contentVC.currentPageIndex
            
            
            if !canScrollHorizontally {
                return false
            }
            
            // Use ContentViewController.currentPageIndex as truth
            // If we're not on page 0 -> inner should handle horizontal swipes
            if currentIndex != 0 {
                return true
            }
            
            // If on page 0: if scrollView at left edge and user swipes right -> allow container takeover (return false)
            // ✅ QUAN TRỌNG: Ở page 0, nếu scrollOffset gần 0 (trong phạm vi 1 page width)
            // thì coi như đang ở left edge
            let pageWidth = scrollView.frame.width
            let atLeftEdge = scrollOffset <= pageWidth + 10 // Cho phép một chút tolerance
            
            
            if atLeftEdge || vx > 0 {
                return false
            }
            
            // Otherwise allow inner to handle (e.g. swipe left to change page)
            return true
        }
        
        return false
    }
    
    // MARK: - Navigation Handlers
    
    private func handleNavigateToShippingAddress() {
        // Push immediately without closing side menu first
        navigateToShippingAddress()
    }
    
    // MARK: - Logout Handling
    
    private func handleLogout() {
        // Close side menu first
        sideMenuState(expanded: false)
        
        // Clear session and user data
        let utilities = Utilities()
        utilities.logout()
        
        // Navigate to Login screen
        navigateToLogin()
    }
    
    private func navigateToLogin() {
        // Create AuthSceneDIContainer and LoginCoordinatingController
        // We need to get AppDIContainer - check if we can access it
        // For now, create a new instance
        let appDIContainer = AppDIContainer()
        let authSceneDIContainer = appDIContainer.makeAuthSceneDIContainer()
        let navigationController = UINavigationController()
        let loginCoordinatingController = authSceneDIContainer.makeLoginCoordinatingController(
            navigationController: navigationController
        )
        
        // Start LoginCoordinatingController which will push LoginViewController
        loginCoordinatingController.start()
        
        // Transition to Login screen as root view controller
        transitionToRootViewController(navigationController)
    }
    
    private func navigateToShippingAddress() {
        // Get navigation controller from current tab
        // selectedViewController is already a UINavigationController (see TabBarController.swift)
        guard let navController = mainTabBarController.selectedViewController as? UINavigationController else {
            return
        }
        
        // Set navigation controller delegate to detect when back
        navController.delegate = self
        
        // Mark that AddressViewController is opened from side menu
        didOpenFromSideMenu = true
        
        // Create AddressCoordinatingController and push AddressViewController
        let appDIContainer = AppDIContainer()
        let addressDIContainer = appDIContainer.makeAddressDIContainer()
        let addressCoordinatingController = addressDIContainer.makeAddressCoordinatingController(
            navigationController: navController
        )
        
        // Start AddressCoordinatingController which will push AddressViewController
        addressCoordinatingController.start()
        
        // Close side menu after push
        sideMenuState(expanded: false)
        
    }
    
    private func handleNavigateToProfile() {
        navigateToProfile()
    }
    
    private func handleNavigateToPayment() {
        navigateToPayment()
    }
    
    private func handleNavigateToOrder() {
        navigateToOrder()
    }
    
    private func navigateToOrder() {
        // Get navigation controller from current tab
        guard let navController = mainTabBarController.selectedViewController as? UINavigationController else {
            return
        }
        
        // Set navigation controller delegate to detect when back
        navController.delegate = self
        
        // Mark that OrderContainerViewController is opened from side menu
        didOpenFromSideMenu = true
        
        // Create OrderContainerViewController and push
        let appDIContainer = AppDIContainer()
        let orderContainerDIContainer = appDIContainer.makeOrderContainerDIContainer()
        let orderContainerViewController = orderContainerDIContainer.makeOrderContainerViewController()
        
        // Push OrderContainerViewController
        navController.pushViewController(orderContainerViewController, animated: true)
        
        // Close side menu after push
        sideMenuState(expanded: false)
        
    }
    
    private func navigateToPayment() {
        // Get navigation controller from current tab
        guard let navController = mainTabBarController.selectedViewController as? UINavigationController else {
            return
        }
        
        // Set navigation controller delegate to detect when back
        navController.delegate = self
        
        // Mark that PaymentCardViewController is opened from side menu
        didOpenFromSideMenu = true
        
        // Create PaymentCardCoordinatingController and push PaymentCardViewController
        let appDIContainer = AppDIContainer()
        let paymentCardDIContainer = appDIContainer.makePaymentCardDIContainer()
        let paymentCardCoordinatingController = paymentCardDIContainer.makePaymentCardCoordinatingController(
            navigationController: navController
        )
        
        // Start PaymentCardCoordinatingController which will push PaymentCardViewController
        paymentCardCoordinatingController.start()
        
        // Close side menu after push
        sideMenuState(expanded: false)
        
    }
    
    private func navigateToProfile() {
        // Get navigation controller from current tab
        guard let navController = mainTabBarController.selectedViewController as? UINavigationController else {
            return
        }
        
        // Set navigation controller delegate to detect when back
        navController.delegate = self
        
        // Mark that ProfileViewController is opened from side menu
        didOpenFromSideMenu = true
        
        // Create ProfileViewController and push
        let appDIContainer = AppDIContainer()
        let profileDIContainer = appDIContainer.makeProfileDIContainer()
        let profileViewController = profileDIContainer.makeProfileViewController()
        
        // Push ProfileViewController
        navController.pushViewController(profileViewController, animated: true)
        
        // Close side menu after push
        sideMenuState(expanded: false)
        
    }
    
    private func transitionToRootViewController(_ viewController: UIViewController) {
        guard let window = view.window ?? UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else {
            return
        }
        
        
        UIView.transition(
            with: window,
            duration: 0.4,
            options: .transitionCrossDissolve,
            animations: {
                window.rootViewController = viewController
            },
            completion: { finished in
            }
        )
    }
}

// MARK: - UINavigationControllerDelegate

extension MainContainerViewController: UINavigationControllerDelegate {
    
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        // ✅ QUAN TRỌNG: Cập nhật flag isPushedFromPageViewController khi navigation thay đổi
        updatePushedFromPageViewControllerFlag()
        
        // Check if AddressViewController still exists in the navigation stack
        let hasAddressViewControllerInStack = navigationController.viewControllers.contains { $0 is AddressViewController }
        let isAddressViewController = viewController is AddressViewController
        
        // Check if ProfileViewController still exists in the navigation stack
        let hasProfileViewControllerInStack = navigationController.viewControllers.contains { $0 is ProfileViewController }
        let isProfileViewController = viewController is ProfileViewController
        
        // Check if PaymentCardViewController still exists in the navigation stack
        let hasPaymentCardViewControllerInStack = navigationController.viewControllers.contains { $0 is PaymentCardViewController }
        let isPaymentCardViewController = viewController is PaymentCardViewController
        
        // Check if OrderContainerViewController still exists in the navigation stack
        let hasOrderContainerViewControllerInStack = navigationController.viewControllers.contains { $0 is OrderContainerViewController }
        let isOrderContainerViewController = viewController is OrderContainerViewController
        
        // Debug: Print all view controllers in stack
        let stackDescription = navigationController.viewControllers.map { vc in
            let className = String(describing: type(of: vc))
            let isAddress = vc is AddressViewController
            let isMap = vc is MapViewController
            return "\(className)\(isAddress ? " [AddressVC]" : "")\(isMap ? " [MapVC]" : "")"
        }.joined(separator: " -> ")
        
        
        if didOpenFromSideMenu {
            // If AddressViewController, ProfileViewController, PaymentCardViewController and OrderContainerViewController are no longer in the stack, we've fully popped back
            if !hasAddressViewControllerInStack && !hasProfileViewControllerInStack && !hasPaymentCardViewControllerInStack && !hasOrderContainerViewControllerInStack {
                // User has completely popped back from side menu flow
                // Reset flag
                didOpenFromSideMenu = false
                
                // Always ensure side menu and overlay are completely closed
                
                // Force close side menu and hide overlay regardless of isExpanded state
                // This prevents overlay from remaining visible after swipe back
                if isExpanded || sideMenuShadowView.alpha > 0 {
                    sideMenuState(expanded: false)
                }
                
                // Ensure shadow view is completely hidden (in case animation didn't complete)
                DispatchQueue.main.async { [weak self] in
                    self?.sideMenuShadowView.alpha = 0.0
                }
            } else if isAddressViewController || isProfileViewController || isPaymentCardViewController {
                // We're back to AddressViewController or ProfileViewController (from other screens)
                // Ensure side menu is closed when returning
                let vcName = isAddressViewController ? "AddressViewController" : "ProfileViewController"
                if isExpanded || sideMenuShadowView.alpha > 0 {
                    sideMenuState(expanded: false)
                }
            }
        }
    }
}


// MARK: - UIViewController Extension

extension UIViewController {
    
    func container<T: UIViewController>() -> T? {
        var viewController: UIViewController? = self
        while viewController != nil {
            if let container = viewController as? T {
                return container
            }
            viewController = viewController?.parent
        }
        return nil
    }
}


