//
//  ProductDetailViewController.swift
//  ECommerce
//
//  Created by wizard.os25 on 14/1/26.
//

import UIKit

final class ProductDetailViewController: EcoViewController {
    
    private var productDetailController: ProductDetailController! {
        get { controller as? ProductDetailController }
    }
    
    private var collectionViewController: ProductDetailCollectionViewController?
    private var orderActionView: OrderActionView!
    private var cardViewController: CardViewController?
    
    // Quantity từ ProductInfoCell
    private var itemQuantity: Int = 1
    
    // OrderUseCase và Cancellable
    private var orderUseCase: OrderUseCase?
    private var placeOrderTask: Cancellable? { willSet { placeOrderTask?.cancel() } }
    private var placedOrder: Order?
    
    // Utilities for location cache
    private let utilities = Utilities()
    
    // MARK: - Lifecycle
    
    static func create(
        with productDetailController: ProductDetailController
    ) -> ProductDetailViewController {
        let view = ProductDetailViewController.instantiateViewController()
        view.controller = productDetailController
        return view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Ẩn TabBar ngay từ viewDidLoad để đảm bảo ẩn khi mở lần đầu
        self.tabBarController?.tabBar.isHidden = true
        setupViews()
        setupChildViewController()
        setupOrderActionView()
        setupBackNavigation()
        setupOrderUseCase()
        
        // ✅ QUAN TRỌNG: Gọi onViewDidLoad để trigger navigation state setup
        productDetailController.onViewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Ẩn TabBar khi vào màn hình ProductDetail (đảm bảo ẩn khi quay lại)
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Hiện TabBar khi rời màn hình ProductDetail
        self.tabBarController?.tabBar.isHidden = false
    }
    
    // MARK: - Setup
    
    private func setupBackNavigation() {
        // Setup back button callback
        if let defaultProductDetailController = productDetailController as? DefaultProductDetailController {
            defaultProductDetailController.onBack = { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
            
            defaultProductDetailController.onTapCart = { [weak self] in
                self?.navigateToCart()
            }
            
            defaultProductDetailController.onTapSearch = { [weak self] in
                self?.navigateToSearch()
            }
        }
    }
    
    private func navigateToSearch() {
        guard let navigationController = navigationController else { return }
        
        let appDIContainer = AppDIContainer.shared
        let searchSceneDIContainer = appDIContainer.makeSearchSceneDIContainer()
        let searchVC = searchSceneDIContainer.makeSearchViewController()
        
        navigationController.pushViewController(searchVC, animated: true)
    }
    
    private func navigateToCart() {
        guard let navigationController = navigationController else { return }
        
        let appDIContainer = AppDIContainer.shared
        let cartSceneDIContainer = appDIContainer.makeCartSceneDIContainer()
        let cartCoordinatingController = cartSceneDIContainer.makeCartCoordinatingController(navigationController: navigationController)
        
        cartCoordinatingController.start()
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        view.backgroundColor = .white
    }
    
    private func setupChildViewController() {
        let collectionVC = ProductDetailCollectionViewController.instantiateViewController()
        collectionVC.productDetailController = productDetailController
        
        // Setup callback để nhận quantity changes
        collectionVC.onQuantityChanged = { [weak self] quantity in
            self?.itemQuantity = quantity
            self?.updateOrderActionView()
        }
        
        addChild(collectionVC)
        view.addSubview(collectionVC.view)
        collectionVC.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            collectionVC.view.topAnchor.constraint(equalTo: view.topAnchor),
            collectionVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -124) // Reserve space for button (100 + 24pt)
        ])
        
        collectionVC.didMove(toParent: self)
        collectionViewController = collectionVC
        
        // Bind collection view scroll with navigation bar
        if let collectionView = collectionVC.collectionView {
            bindNavigationBar(to: collectionView)
        }
        
        // ✅ QUAN TRỌNG: Đảm bảo navigation bar nằm trên cùng của layer UI
        // Cần gọi sau khi đã add child view controller
        if let navBarView = navigationBarViewController?.view {
            view.bringSubviewToFront(navBarView)
            navBarView.isUserInteractionEnabled = true
        }
    }
    
    private func setupOrderUseCase() {
        let appDIContainer = AppDIContainer.shared
        let orderDIContainer = appDIContainer.makeOrderDIContainer()
        orderUseCase = orderDIContainer.makeOrderUseCase()
    }
    
    private func setupOrderActionView() {
        orderActionView = OrderActionView()
        orderActionView.delegate = self
        orderActionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(orderActionView)
        
        NSLayoutConstraint.activate([
            orderActionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            orderActionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            orderActionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            orderActionView.heightAnchor.constraint(greaterThanOrEqualToConstant: 80 + 12) // Giảm padding một nửa (từ 24 xuống 12)
        ])
        
        // Configure OrderActionView
        // Padding giảm một nửa - sẽ được xử lý trong OrderActionView
        orderActionView.topLeftLabelText = "Subtotal"
        orderActionView.buttonTitle = "Start order"
        orderActionView.buttonCornerRadius = BorderRadius.tokenBorderRadius16
        // Icon cart với dấu + (cart.badge.plus hoặc cart.fill.badge.plus)
        orderActionView.leftItemType = .icon(UIImage(systemName: "cart.badge.plus") ?? UIImage(systemName: "cart.fill.badge.plus"))
        
        // Update initial values
        updateOrderActionView()
        
        // Giảm padding một nửa cho ProductDetail
        adjustOrderActionViewPadding()
        
        // Ensure z-order: Navigation bar > OrderActionView > Collection view
        // OrderActionView should be below navbar but above collection view
        view.bringSubviewToFront(orderActionView)
    }
    
    private func adjustOrderActionViewPadding() {
        // Tìm containerStackView trong OrderActionView và giảm padding một nửa
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Tìm containerStackView trong OrderActionView
            for subview in self.orderActionView.subviews {
                if let stackView = subview as? UIStackView {
                    // Điều chỉnh constraints của stackView - giảm padding một nửa
                    for constraint in self.orderActionView.constraints {
                        if (constraint.firstItem === stackView || constraint.secondItem === stackView) {
                            // Giảm top padding từ 12pt xuống 6pt
                            if constraint.firstAttribute == .top && constraint.constant == Spacing.tokenSpacing12 {
                                constraint.constant = Spacing.tokenSpacing12 / 2
                            }
                            // Giảm bottom padding từ -12pt xuống -6pt
                            if constraint.firstAttribute == .bottom && constraint.constant == -Spacing.tokenSpacing12 {
                                constraint.constant = -Spacing.tokenSpacing12 / 2
                            }
                            // Giảm leading/trailing padding từ 12pt xuống 6pt
                            if (constraint.firstAttribute == .leading || constraint.firstAttribute == .trailing) && 
                               abs(constraint.constant) == Spacing.tokenSpacing12 {
                                constraint.constant = constraint.constant > 0 ? Spacing.tokenSpacing12 / 2 : -Spacing.tokenSpacing12 / 2
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func updateOrderActionView() {
        guard let product = productDetailController.product.value else { return }
        
        let priceNumber = product.price.convertMoneyToNumber()
        let totalPrice = priceNumber * Double(itemQuantity)
        
        // Format totalPrice bỏ .00 khi không cần, có separator
        let formattedPrice = totalPrice.formattedWithSeparatorWithoutTrailingZeros
        
        // Format: "mũi tên hướng lên (chevron.up) 600000 vnd"
        // Sử dụng SF Symbol chevron.up hoặc Unicode ↑
        let chevronUp = "↑" // Unicode arrow up
        orderActionView.topRightLabelText = "\(chevronUp) \(formattedPrice) vnd"
    }
    
    private func formatDoubleToCurrency(_ value: Double) -> String {
        // Format bỏ .00 khi không cần
        return value.formattedWithSeparatorWithoutTrailingZeros
    }
    
    private func openAddToCardOrderCard() {
        guard let product = productDetailController.product.value else {
            return
        }
        
        
        // Create Card Configuration - cách top 200pt
        let screenHeight = view.bounds.height
        let topPadding: CGFloat = 200
        let cardConfig = CardConfiguration(
            expandedHeight: screenHeight - topPadding,
            collapsedHeight: screenHeight - topPadding,
            presentationMode: .onDemand,
            enableGesture: true
        )
        
        // Create Card Controller
        let cardController = DefaultCardController(configuration: cardConfig)
        
        // Create Card View Controller
        let cardVC = CardViewController.create(with: cardController)
        
        // Attach to current view controller
        cardVC.attach(to: self)
        
        // Create OrderViewController with cart items
        let cartItems = [CartItem(id: product.id, quantity: itemQuantity)]
        let appDIContainer = AppDIContainer.shared
        let orderDIContainer = appDIContainer.makeOrderDIContainer()
        let orderVC = orderDIContainer.makeOrderViewController(cartItems: cartItems, product: product, isAddToCardMode: true)
        
        // Set OrderViewController as content
        cardVC.setContent(orderVC)
        
        // Store reference
        cardViewController = cardVC
        
        // Ensure view is laid out and parent view height is set before showing
        view.layoutIfNeeded()
        
        DispatchQueue.main.async { [weak cardVC, weak self] in
            guard let cardVC = cardVC, let self = self else { return }
            let height = self.view.bounds.height
            if height > 0 {
                cardVC.updateParentViewHeightIfNeeded()
                cardVC.show()
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    cardVC.updateParentViewHeightIfNeeded()
                    cardVC.show()
                }
            }
        }
    }
    
    private func openOrderCard() {
        guard let product = productDetailController.product.value else {
            return
        }
        
        
        // Check if card already exists and is still attached
        if let existingCard = cardViewController, existingCard.parent != nil {
            existingCard.show()
            return
        }
        
        // If card exists but is not attached (was dismissed), clean it up first
        if cardViewController != nil {
            cardViewController?.detach()
            cardViewController = nil
        }
        
        
        // Create Card Configuration - cách top 180pt
        let screenHeight = view.bounds.height
        let topPadding: CGFloat = 180
        let cardConfig = CardConfiguration(
            expandedHeight: screenHeight - topPadding,
            collapsedHeight: screenHeight - topPadding,
            presentationMode: .onDemand,
            enableGesture: true
        )
        
        // Create Card Controller
        let cardController = DefaultCardController(configuration: cardConfig)
        
        // Create Card View Controller
        let cardVC = CardViewController.create(with: cardController)
        
        // Attach to current view controller
        cardVC.attach(to: self)
        
        // Create OrderViewController with cart items
        let cartItems = [CartItem(id: product.id, quantity: itemQuantity)]
        let appDIContainer = AppDIContainer.shared
        let orderDIContainer = appDIContainer.makeOrderDIContainer()
        let orderVC = orderDIContainer.makeOrderViewController(cartItems: cartItems, product: product)
        
        // Set OrderViewController as content
        cardVC.setContent(orderVC)
        
        // Store reference
        cardViewController = cardVC
        
        // Ensure view is laid out and parent view height is set before showing
        view.layoutIfNeeded()
        
        DispatchQueue.main.async { [weak cardVC, weak self] in
            guard let cardVC = cardVC, let self = self else { return }
            let height = self.view.bounds.height
            if height > 0 {
                cardVC.updateParentViewHeightIfNeeded()
                cardVC.show()
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    cardVC.updateParentViewHeightIfNeeded()
                    cardVC.show()
                }
            }
        }
    }
    
    private func placeOrder() {
        guard let product = productDetailController.product.value else { return }
        guard let orderUseCase = orderUseCase else { return }
        
        // Get cached address
        let address = utilities.getCachedAddress() ?? ""
        
        // Create cart items
        let cartItems = [CartItem(id: product.id, quantity: itemQuantity)]
        
        // Set loading state
        orderActionView.isLoading = true
        
        // Place order
        // TODO: Get address details from user's saved addresses if available
        placeOrderTask = orderUseCase.placeOrder(
            cart: cartItems,
            orderNote: nil,
            deliveryAddressId: nil,
            addressDetail: address,
            countryId: nil,
            provinceId: nil,
            districtId: nil,
            wardId: nil,
            contactPersonName: "", // TODO: Get from user profile
            contactPersonNumber: "" // TODO: Get from user profile
        ) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.orderActionView.isLoading = false
                
                switch result {
                case .success(let order):
                    self.placedOrder = order
                    // Open order card after successful placement
                    self.openOrderCard()
                case .failure(let error): break
                    // TODO: Show error alert
                }
            }
        }
    }
    
    private func showPricingCalculationPopup() {
        guard let product = productDetailController.product.value else { return }
        
        let priceNumber = product.price.convertMoneyToNumber()
        let totalPrice = priceNumber * Double(itemQuantity)
        
        let popup = PricingCaculationPopup(frame: .zero)
        popup.subTotalValue.text = formatDoubleToCurrency(totalPrice) + CoreUtilsKitLocalization.currency_unit.localized
        popup.orderBreakdownValueLabel.text = formatDoubleToCurrency(totalPrice) + CoreUtilsKitLocalization.currency_unit.localized
        popup.shippingValueLabel.text = "0" + CoreUtilsKitLocalization.currency_unit.localized
        
        popup.show(in: view)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // ✅ QUAN TRỌNG: Đảm bảo z-order đúng: Navigation bar > OrderActionView > Collection view
        // Navigation bar ở trên cùng
        if let navBarView = navigationBarViewController?.view {
            view.bringSubviewToFront(navBarView)
            navBarView.isUserInteractionEnabled = true
        }
        
        // OrderActionView ở dưới navbar nhưng trên collection view
        view.bringSubviewToFront(orderActionView)
    }
    
    // MARK: - Navigation Override
    
    override func applyNavigation(_ state: EcoNavigationState) {
        super.applyNavigation(state)
        
        // Setup searchTextField để disable input và navigate khi tap
        DispatchQueue.main.async { [weak self] in
            self?.setupSearchTextField()
        }
    }
    
    private func setupSearchTextField() {
        guard let navBarView = navigationBarViewController?.view as? EcoNavigationBarView else { return }
        let searchTextField = navBarView.searchField
        
        // Remove existing tap gestures
        if let gestures = searchTextField.gestureRecognizers {
            for gesture in gestures {
                searchTextField.removeGestureRecognizer(gesture)
            }
        }
        
        // Disable user input vào searchTextField (không cho user type)
        searchTextField.isEnabled = false
        
        // Add tap gesture để navigate to SearchViewController khi tap vào searchTextField
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(searchTextFieldTapped))
        searchTextField.addGestureRecognizer(tapGesture)
        searchTextField.isUserInteractionEnabled = true // Enable để nhận tap gesture
    }
    
    @objc private func searchTextFieldTapped() {
        navigateToSearch()
    }
}

// MARK: - OrderActionViewDelegate

extension ProductDetailViewController: OrderActionViewDelegate {
    
    func orderActionViewDidTapAction(_ view: OrderActionView) {
        // When "Start order" button is tapped, push CheckoutViewController
        pushCheckoutViewController()
    }
    
    func orderActionViewDidTapLeftItem(_ view: OrderActionView) {
        // When left icon (add to card) is tapped, open CardView with OrderViewController
        openAddToCardOrderCard()
    }
    
    func orderActionViewDidTapTopRightLabel(_ view: OrderActionView) {
        showPricingCalculationPopup()
    }
    
    private func pushCheckoutViewController() {
        // Get productDetailModel từ controller
        guard let productDetailModel = productDetailController.product.value else {
            return
        }
        
        // Find navigation controller
        guard let navigationController = self.navigationController else {
            return
        }
        
        // Create cart items from product
        let cartItems = [CartItem(id: productDetailModel.id, quantity: itemQuantity)]
        
        // Use CheckoutSceneDIContainer to create CheckoutViewController with proper controller injection
        let appDIContainer = AppDIContainer.shared
        let checkoutSceneDIContainer = appDIContainer.makeCheckoutSceneDIContainer()
        let checkoutVC = checkoutSceneDIContainer.makeCheckoutViewController(cartItems: cartItems, product: productDetailModel)
        
        navigationController.pushViewController(checkoutVC, animated: true)
    }
}
