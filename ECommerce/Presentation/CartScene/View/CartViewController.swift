//
//  CartViewController.swift
//  ECommerce
//
//  Created by wizard.os25 on 17/1/26.
//

import UIKit

final class CartViewController: EcoViewController {
    
    // MARK: - UI Components
    
    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .systemBackground
        tv.separatorStyle = .none
        tv.translatesAutoresizingMaskIntoConstraints = false
        // Set spacing between cells (8pt)
        tv.sectionHeaderHeight = 0
        tv.sectionFooterHeight = 0
        tv.estimatedRowHeight = 0
        return tv
    }()
    
    private let orderActionView: OrderActionView = {
        let view = OrderActionView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "Your cart is empty"
        label.textAlignment = .center
        label.font = Typography.fontRegular16
        label.textColor = Colors.tokenDark60
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var tableViewTopConstraint: NSLayoutConstraint?
    
    private var cartController: CartController! {
        get { controller as? CartController }
    }
    
    // MARK: - Lifecycle
    
    static func create(
        with cartController: CartController
    ) -> CartViewController {
        let view = CartViewController.instantiateViewController()
        view.controller = cartController
        return view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let defaultController = cartController as? DefaultCartController {
        }
        
        setupViews()
        bindCartSpecific()
        cartController.didLoadView()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Refresh navigation bar title when coming back
        cartController.onViewDidLoad()
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        view.backgroundColor = .systemBackground
        
        // TableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "CartItemCell", bundle: nil), forCellReuseIdentifier: "CartItemCell")
        view.addSubview(tableView)
        
        // Empty state label
        view.addSubview(emptyStateLabel)
        
        // OrderActionView
        orderActionView.delegate = self
        orderActionView.configureForCheckout(
            topLeftText: nil,
            topRightText: nil,
            buttonTitle: "Checkout",
            leftItem: .none
        )
        view.addSubview(orderActionView)
        
        let tableViewTop = tableView.topAnchor.constraint(equalTo: view.topAnchor)
        tableViewTopConstraint = tableViewTop
        
        NSLayoutConstraint.activate([
            tableViewTop,
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: orderActionView.topAnchor),
            
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            orderActionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            orderActionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            orderActionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        updateTableViewTopConstraint()
        updateOrderActionView()
    }
    
    private func updateTableViewTopConstraint() {
        // Update constraint after navigation bar is attached
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let navBarHeight = self.navigationBarHeight
            self.tableViewTopConstraint?.constant = navBarHeight
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: - Binding
    
    private func bindCartSpecific() {
        cartController.cartItems.observe(on: self) { [weak self] items in
            if !items.isEmpty {
                items.enumerated().forEach { index, item in
                }
            } else {
            }
            
            DispatchQueue.main.async {
                self?.tableView.reloadData()
                
                self?.updateEmptyState(isEmpty: items.isEmpty)
                
                self?.updateOrderActionView()
                
                self?.updateNavigationBar()
            }
        }
        
        cartController.selectedItemsCount.observe(on: self) { [weak self] _ in
            self?.updateNavigationBar()
        }
        
        cartController.totalPrice.observe(on: self) { [weak self] _ in
            self?.updateOrderActionView()
        }
        
        cartController.loading.observe(on: self) { [weak self] isLoading in
            self?.orderActionView.isLoading = isLoading
        }
        
        cartController.error.observe(on: self) { [weak self] error in
            guard let error = error else { return }
            self?.showAlert(title: "Error", message: error.localizedDescription)
        }
        
        // Setup callback for navigation to checkout
        if let defaultController = cartController as? DefaultCartController {
            defaultController.onNavigateToCheckout = { [weak self] cartItems in
                self?.navigateToCheckout(cartItems: cartItems)
            }
        }
    }
    
    private func updateEmptyState(isEmpty: Bool) {
        emptyStateLabel.isHidden = !isEmpty
        tableView.isHidden = isEmpty
    }
    
    private func updateOrderActionView() {
        let total = cartController.totalPrice.value
        let selectedCount = cartController.selectedItemsCount.value
        
        // Format total price
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.groupingSeparator = "."
        numberFormatter.decimalSeparator = ","
        numberFormatter.locale = Locale(identifier: "en_US")
        numberFormatter.maximumFractionDigits = 2
        
        let formattedPrice = numberFormatter.string(from: NSNumber(value: total)) ?? "0"
        
        // Update right label with total price
        orderActionView.topRightLabelText = "\(formattedPrice) VND"
        
        // Enable/disable checkout button based on selection
        orderActionView.isButtonEnabled = selectedCount > 0
    }
    
    private func updateNavigationBar() {
        cartController.onViewDidLoad()
        updateTableViewTopConstraint()
    }
    
    override func applyNavigation(_ state: EcoNavigationState) {
        super.applyNavigation(state)
        // Update table view constraint after navigation bar is attached
        DispatchQueue.main.async { [weak self] in
            self?.updateTableViewTopConstraint()
        }
    }
    
    // MARK: - Navigation
    
    private func navigateToCheckout(cartItems: [CartItem]) {
        guard let navigationController = navigationController else { return }
        
        let appDIContainer = AppDIContainer.shared
        let checkoutSceneDIContainer = appDIContainer.makeCheckoutSceneDIContainer()
        
        // Get selected cart item models with full product details
        let selectedCartItemModels = cartController.cartItems.value.filter { $0.isSelected }
        
        // Create productMap: productId -> ProductDetailModel for accurate product info
        var productMap: [Int: ProductDetailModel] = [:]
        for itemModel in selectedCartItemModels {
            let productDetail = ProductDetailModel(
                id: itemModel.productId,
                name: itemModel.productName,
                description: itemModel.productDescription,
                price: itemModel.price,
                stars: nil,
                location: "",
                imageUrl: itemModel.productImageUrl,
                imageBlurhash: nil,
                soldCount: nil,
                sellerName: nil,
                sellerImageUrl: nil
            )
            productMap[itemModel.productId] = productDetail
        }
        
        // Store product IDs in checkout controller for removal after payment
        let checkoutController = checkoutSceneDIContainer.makeCheckoutController(
            cartItems: cartItems,
            product: nil,
            productMap: productMap
        )
        
        if let defaultController = checkoutController as? DefaultCheckoutController {
            let productIds = selectedCartItemModels.map { $0.productId }
            defaultController.setPurchasedProductIds(productIds)
        }
        
        let checkoutVC = CheckoutViewController.create(with: checkoutController)
        
        navigationController.pushViewController(checkoutVC, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension CartViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cartController.cartItems.value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CartItemCell", for: indexPath) as! CartItemCell
        
        let item = cartController.cartItems.value[indexPath.row]
        cell.configure(with: item)
        
        // Add bottom spacing (8pt) except for last cell
        if indexPath.row < cartController.cartItems.value.count - 1 {
            cell.contentView.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 8, right: 0)
        } else {
            cell.contentView.layoutMargins = UIEdgeInsets.zero
        }
        
        cell.onToggleSelection = { [weak self] in
            self?.cartController.didToggleItemSelection(productId: item.productId)
        }
        
        cell.onQuantityChanged = { [weak self] quantity in
            self?.cartController.didUpdateItemQuantity(productId: item.productId, quantity: quantity)
        }
        
        cell.onDelete = { [weak self] in
            self?.cartController.didDeleteItem(productId: item.productId)
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension CartViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - OrderActionViewDelegate

extension CartViewController: OrderActionViewDelegate {
    
    func orderActionViewDidTapAction(_ view: OrderActionView) {
        cartController.didTapCheckout()
    }
    
    func orderActionViewDidTapLeftItem(_ view: OrderActionView) {
        // Not used in cart
    }
    
    func orderActionViewDidTapTopRightLabel(_ view: OrderActionView) {
        // Could show pricing breakdown popup
    }
}
