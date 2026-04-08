//
//  OrderViewController.swift
//  ECommerce
//
//  Created by wizard.os25 on 14/1/26.
//

import UIKit
import StripePaymentSheet

final class OrderViewController: EcoViewController {
    
    // MARK: - UI Components
    
    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.separatorStyle = .none
        tableView.backgroundColor = .systemBackground
        tableView.keyboardDismissMode = .onDrag
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private var orderController: OrderController! {
        get { controller as? OrderController }
    }
    
    // Store selected address
    private var selectedAddress: Address?
    private var quantity: Int = 1
    
    // CardViewController for location list popup
    private var locationListCardViewController: CardViewController?
    
    // Reference to quantity cell
    private var quantityCell: OrderQuantityCell?
    
    // Add to card mode
    var isAddToCardMode: Bool = false {
        didSet {
            if isAddToCardMode {
                setupAddToCardOrderActionView()
            }
        }
    }
    
    // OrderActionView for add to card mode
    private var addToCardOrderActionView: OrderActionView?
    
    // OrderActionView for start order flow (not add to card mode)
    private var startOrderActionView: OrderActionView?
    
    // MARK: - Lifecycle
    
    static func create(
        with orderController: OrderController
    ) -> OrderViewController {
        let view = OrderViewController.instantiateViewController()
        view.controller = orderController
        return view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        if isAddToCardMode {
            setupAddToCardOrderActionView()
        } else {
            setupStartOrderActionView()
        }
        bindOrderSpecific()
        loadInitialQuantity()
        orderController.didLoadView()
    }
    
    // MARK: - Common Binding Override
    
    override func bindCommon() {
        super.bindCommon()
        bindOrderSpecific()
    }
    
    override func applyNavigation(_ state: EcoNavigationState) {
        super.applyNavigation(state)
        DispatchQueue.main.async { [weak self] in
            if let navBarController = self?.navigationBarViewController?.controller as? DefaultEcoNavigationBarController {
                navBarController.onLeftItemTap = { [weak self] in
                    self?.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
    
    // MARK: - Order-Specific Binding
    
    private func bindOrderSpecific() {
        orderController.product.observe(on: self) { [weak self] _ in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
                if self?.isAddToCardMode == true {
                    self?.updateAddToCardOrderActionView()
                } else {
                    self?.updateStartOrderActionView()
                }
            }
        }
        
        orderController.isOrderPlaced.observe(on: self) { [weak self] isPlaced in
            if isPlaced {
                self?.handleOrderPlaced()
            }
        }
        
        orderController.error.observe(on: self) { [weak self] error in
            guard let self = self, let error = error else { return }
            self.showAlert(title: "Error", message: error.localizedDescription)
        }
        
        orderController.loading.observe(on: self) { [weak self] isLoading in
            if let startOrderActionView = self?.startOrderActionView {
                startOrderActionView.isLoading = isLoading
            }
            if let addToCardOrderActionView = self?.addToCardOrderActionView {
                addToCardOrderActionView.isLoading = isLoading
            }
        }
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        view.backgroundColor = .systemBackground
        
        // Setup TableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(cell: OrderProductImageCell.self)
        tableView.register(cell: OrderQuantityCell.self)
        tableView.register(cell: OrderDeliverCell.self)
        
        view.addSubview(tableView)
        
        // Always reserve space for OrderActionView at bottom
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -100)
        ])
    }
    
    private func setupAddToCardOrderActionView() {
        guard isAddToCardMode else { return }
        
        let orderActionView = OrderActionView()
        orderActionView.delegate = self
        orderActionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(orderActionView)
        
        // Configure OrderActionView for add to card mode
        orderActionView.topLeftLabelText = "Subtotal"
        orderActionView.buttonTitle = "Add to card"
        orderActionView.buttonCornerRadius = BorderRadius.tokenBorderRadius16
        orderActionView.leftItemType = .none // No left item
        
        // Update price
        updateAddToCardOrderActionView()
        
        NSLayoutConstraint.activate([
            orderActionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            orderActionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            orderActionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        addToCardOrderActionView = orderActionView
        view.bringSubviewToFront(orderActionView)
    }
    
    private func setupStartOrderActionView() {
        let orderActionView = OrderActionView()
        orderActionView.delegate = self
        orderActionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(orderActionView)
        
        // Configure OrderActionView for start order flow
        orderActionView.topLeftLabelText = "Subtotal"
        orderActionView.buttonTitle = "Start order"
        orderActionView.buttonCornerRadius = BorderRadius.tokenBorderRadius16
        orderActionView.leftItemType = .icon(UIImage(systemName: "plus.circle")) // Add to card icon
        
        // Update price
        updateStartOrderActionView()
        
        NSLayoutConstraint.activate([
            orderActionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            orderActionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            orderActionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        startOrderActionView = orderActionView
        view.bringSubviewToFront(orderActionView)
    }
    
    private func updateStartOrderActionView() {
        guard let orderActionView = startOrderActionView,
              let product = orderController.product.value else { return }
        
        let priceNumber = product.price.convertMoneyToNumber()
        let totalPrice = priceNumber * Double(quantity)
        
        // Format totalPrice to currency string
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.groupingSeparator = "."
        numberFormatter.decimalSeparator = ","
        numberFormatter.locale = Locale(identifier: "en_US")
        numberFormatter.maximumFractionDigits = 0
        
        let formattedPrice = numberFormatter.string(from: NSNumber(value: totalPrice)) ?? "0"
        
        orderActionView.topRightLabelText = "$ \(formattedPrice) ⋀"
    }
    
    private func updateAddToCardOrderActionView() {
        guard let orderActionView = addToCardOrderActionView,
              let product = orderController.product.value else { return }
        
        let priceNumber = product.price.convertMoneyToNumber()
        let totalPrice = priceNumber * Double(quantity)
        
        // Format totalPrice to currency string
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.groupingSeparator = "."
        numberFormatter.decimalSeparator = ","
        numberFormatter.locale = Locale(identifier: "en_US")
        numberFormatter.maximumFractionDigits = 0
        
        let formattedPrice = numberFormatter.string(from: NSNumber(value: totalPrice)) ?? "0"
        
        orderActionView.topRightLabelText = "$ \(formattedPrice) ⋀"
    }
    
    
    private func loadInitialQuantity() {
        if let firstItem = orderController.cartItems.value.first {
            quantity = firstItem.quantity
        }
    }
    
    private func updateCartItemsQuantity() {
        guard let firstItem = orderController.cartItems.value.first else { return }
        let updatedCartItems = [CartItem(id: firstItem.id, quantity: quantity)]
        orderController.updateCartItems(updatedCartItems)
    }
    
    // MARK: - Helper Methods
    
    private func handleOrderPlaced() {
        guard let order = orderController.orderResult.value else { return }
        showAlert(
            title: "Success",
            message: "Order placed successfully! Order ID: \(order.orderId)"
        )
    }
    
}

// MARK: - UITableViewDataSource

extension OrderViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            // Product Image Cell
            let cell: OrderProductImageCell = tableView.dequeueReusableCell(at: indexPath)
            cell.configure(with: orderController.product.value)
            return cell
            
        case 1:
            // Quantity Cell
            let cell: OrderQuantityCell = tableView.dequeueReusableCell(at: indexPath)
            cell.configure(quantity: quantity)
            cell.onQuantityChanged = { [weak self] newQuantity in
                self?.quantity = newQuantity
                self?.updateCartItemsQuantity()
                if self?.isAddToCardMode == true {
                    self?.updateAddToCardOrderActionView()
                } else {
                    self?.updateStartOrderActionView()
                }
            }
            quantityCell = cell
            return cell
            
        case 2:
            // Deliver Cell
            let cell: OrderDeliverCell = tableView.dequeueReusableCell(at: indexPath)
            return cell
            
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return nil
        case 1:
            return "Quantity"
        case 2:
            return "Deliver"
        default:
            return nil
        }
    }
}

// MARK: - UITableViewDelegate

extension OrderViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return UITableView.automaticDimension // Dynamic height for title and description
        case 1:
            return 60
        case 2:
            return UITableView.automaticDimension
        default:
            return 44
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return 100 // Estimated height
        case 1:
            return 60
        case 2:
            return 120
        default:
            return 44
        }
    }
}

// MARK: - OrderActionViewDelegate

extension OrderViewController: OrderActionViewDelegate {
    
    func orderActionViewDidTapAction(_ view: OrderActionView) {
        if isAddToCardMode {
            // Save to cart: totalPrice, id, quantity
            guard let product = orderController.product.value,
                  let firstItem = orderController.cartItems.value.first else { return }
            
            print("🛒 [OrderViewController] ========================================")
            print("🛒 [OrderViewController] orderActionViewDidTapAction - Add to card mode")
            print("   Product ID: \(product.id)")
            print("   Product Name: \(product.name)")
            print("   Quantity: \(quantity)")
            print("   Price: \(product.price)")
            
            // Get shared cart controller
            let appDIContainer = AppDIContainer.shared
            print("   ✅ AppDIContainer.shared retrieved")
            
            let cartDIContainer = appDIContainer.makeCartSceneDIContainer()
            print("   ✅ CartSceneDIContainer retrieved (shared instance)")
            
            let cartController = cartDIContainer.makeCartController()
            print("   ✅ CartController retrieved. Type: \(type(of: cartController))")
            if let defaultController = cartController as? DefaultCartController {
                print("   ✅ CartController instance ID: \(ObjectIdentifier(defaultController))")
            }
            
            // Add item to cart
            print("   📦 Calling cartController.didAddItem...")
            cartController.didAddItem(
                productId: product.id,
                productName: product.name,
                productDescription: product.description,
                productImageUrl: product.imageUrl,
                price: product.price,
                quantity: quantity
            )
            print("   ✅ cartController.didAddItem completed")
            print("🛒 [OrderViewController] ========================================")
            
            // Dismiss card if exists
            if let cardVC = parent as? CardViewController {
                cardVC.dismiss(animated: true)
            }
            
            // Show success message
            showAlert(
                title: "Success",
                message: "Product added to cart successfully!"
            )
        } else {
            // Start order flow - call API place order
            placeOrder()
        }
    }
    
    func orderActionViewDidTapLeftItem(_ view: OrderActionView) {
        // When left item (add to card icon) is tapped, save to cart
        guard !isAddToCardMode else { return }
        
        guard let product = orderController.product.value,
              let firstItem = orderController.cartItems.value.first else { return }
        
        // Get shared cart controller
        let appDIContainer = AppDIContainer.shared
        let cartDIContainer = appDIContainer.makeCartSceneDIContainer()
        let cartController = cartDIContainer.makeCartController()
        
        // Add item to cart
        cartController.didAddItem(
            productId: product.id,
            productName: product.name,
            productDescription: product.description,
            productImageUrl: product.imageUrl,
            price: product.price,
            quantity: quantity
        )
        
        print("✅ [OrderViewController] Add to card via left icon:")
        print("   Product ID: \(product.id)")
        print("   Quantity: \(quantity)")
        
        // Show success message
        showAlert(
            title: "Success",
            message: "Product added to cart successfully!"
        )
    }
    
    func orderActionViewDidTapTopRightLabel(_ view: OrderActionView) {
        // Show pricing calculation popup
        guard let product = orderController.product.value else { return }
        
        let priceNumber = product.price.convertMoneyToNumber()
        let totalPrice = priceNumber * Double(quantity)
        
        let popup = PricingCaculationPopup(frame: .zero)
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.groupingSeparator = "."
        numberFormatter.decimalSeparator = ","
        numberFormatter.locale = Locale(identifier: "en_US")
        numberFormatter.maximumFractionDigits = 0
        let formattedPrice = numberFormatter.string(from: NSNumber(value: totalPrice)) ?? "0"
        let currencyUnit = CoreUtilsKitLocalization.currency_unit.localized
        
        // Configure labels theo yêu cầu
        popup.titlePricingLabel.text = "Price breakdown"
        popup.orderBreakdownLabel.text = "\(product.name) • \(quantity) item"
        popup.orderBreakdownValueLabel.text = "$ \(formattedPrice)"
        
        // Ẩn shipping nếu không có giá trị
        let shippingValue: Double = 0 // TODO: Get from order or product
        if shippingValue > 0 {
            popup.shippingLabel.isHidden = false
            popup.shippingValueLabel.isHidden = false
            let formattedShipping = numberFormatter.string(from: NSNumber(value: shippingValue)) ?? "0"
            popup.shippingValueLabel.text = "$ \(formattedShipping)"
        } else {
            popup.shippingLabel.isHidden = true
            popup.shippingValueLabel.isHidden = true
        }
        
        // Subtotal = totalPrice + shippingValue (nếu có)
        let subTotal = totalPrice + shippingValue
        let formattedSubTotal = numberFormatter.string(from: NSNumber(value: subTotal)) ?? "0"
        popup.subTotalLabel.text = "Total price"
        popup.subTotalValue.text = "$ \(formattedSubTotal)"
        
        popup.show(in: self.view)
    }
    
    private func placeOrder() {
        // Get cached address
        let utilities = Utilities()
        let address = utilities.getCachedAddress() ?? ""
        
        // Call API place order through OrderController
        // longitude and latitude are not used by backend anymore, but kept for compatibility
        orderController.didTapPlaceOrder(
            address: address,
            longitude: "", // Not used by backend anymore
            latitude: "", // Not used by backend anymore
            contactPersonName: "", // TODO: Get from user profile or input field
            contactPersonNumber: "", // TODO: Get from user profile or input field
            orderNote: nil
        )
        
        // Push CheckoutViewController ngay không chờ kết quả
        pushCheckoutViewController()
    }
    
    private func pushCheckoutViewController() {
        // Load CheckoutViewController from storyboard
        let storyboard = UIStoryboard(name: "CheckoutViewController", bundle: nil)
        guard let checkoutVC = storyboard.instantiateViewController(withIdentifier: "CheckoutViewController") as? CheckoutViewController else {
            print("⚠️ [OrderViewController] Failed to load CheckoutViewController from storyboard")
            return
        }
        
        // Find navigation controller
        var navigationController: UINavigationController?
        
        // Try self.navigationController first
        if let navController = self.navigationController {
            navigationController = navController
        }
        // If embedded in CardViewController, try parent's navigation controller
        else if let cardVC = parent as? CardViewController,
                let parentNav = cardVC.parent?.navigationController {
            navigationController = parentNav
        }
        // Try to find from view hierarchy
        else if let parentVC = parent,
                let navController = parentVC.navigationController {
            navigationController = navController
        }
        
        guard let navController = navigationController else {
            print("⚠️ [OrderViewController] No navigation controller found")
            return
        }
        
        // Dismiss CardViewController if exists
        if let cardVC = parent as? CardViewController {
            cardVC.dismiss(animated: false) {
                navController.pushViewController(checkoutVC, animated: true)
            }
        } else {
            navController.pushViewController(checkoutVC, animated: true)
        }
    }
}
