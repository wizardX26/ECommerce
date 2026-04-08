//
//  CheckoutViewController.swift
//  ECommerce
//
//  Created by wizard.os25 on 15/1/26.
//

import UIKit
import StripePaymentSheet

final class CheckoutViewController: EcoViewController {
    
    // MARK: - UI Components
    
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .systemBackground
        cv.showsVerticalScrollIndicator = false
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    private let progressIndicator = CheckoutProgressIndicator()
    
    private let orderActionView = OrderActionView()
    
    private var checkoutController: CheckoutController! {
        get { controller as? CheckoutController }
    }
    
    // CardViewController for address
    private var addressCardViewController: CardViewController?
    
    // CardViewController for location list
    private var locationListCardViewController: CardViewController?
    
    // PaymentSheet
    private var paymentSheet: PaymentSheet?
    
    // Flag để track khi nào cần auto-show PaymentSheet
    private var shouldAutoShowPaymentSheet = false
    
    // MARK: - Lifecycle
    
    static func create(
        with checkoutController: CheckoutController
    ) -> CheckoutViewController {
        let view = CheckoutViewController.instantiateViewController()
        view.controller = checkoutController
        return view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Ẩn TabBar ngay từ viewDidLoad để đảm bảo ẩn khi mở lần đầu
        self.tabBarController?.tabBar.isHidden = true
        isSwipeBackEnabled = true // Cho phép swipe back
        setupViews()
        bindCheckoutSpecific()
        checkoutController.didLoadView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Ẩn TabBar khi vào màn hình Checkout (đảm bảo ẩn khi quay lại)
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Hiện TabBar khi rời màn hình Checkout
        self.tabBarController?.tabBar.isHidden = false
    }
    
    override func applyNavigation(_ state: EcoNavigationState) {
        super.applyNavigation(state)
        // Override left item tap callback để pop back về trước
        DispatchQueue.main.async { [weak self] in
            if let navBarController = self?.navigationBarViewController?.controller as? DefaultEcoNavigationBarController {
                navBarController.onLeftItemTap = { [weak self] in
                    self?.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        view.backgroundColor = .systemBackground
        
        // Progress indicator
        progressIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressIndicator)
        
        // Collection view
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(CheckoutAddressCell.self, forCellWithReuseIdentifier: "CheckoutAddressCell")
        collectionView.register(CheckoutProductsCell.self, forCellWithReuseIdentifier: "CheckoutProductsCell")
        collectionView.register(CheckoutNoteCell.self, forCellWithReuseIdentifier: "CheckoutNoteCell")
        collectionView.register(CheckoutPaymentMethodCell.self, forCellWithReuseIdentifier: "CheckoutPaymentMethodCell")
        collectionView.register(CheckoutOrderSummaryCell.self, forCellWithReuseIdentifier: "CheckoutOrderSummaryCell")
        collectionView.register(SectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "SectionHeader")
        view.addSubview(collectionView)
        
        // OrderActionView
        orderActionView.delegate = self
        orderActionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(orderActionView)
        
        NSLayoutConstraint.activate([
            progressIndicator.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 88),
            progressIndicator.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressIndicator.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            collectionView.topAnchor.constraint(equalTo: progressIndicator.bottomAnchor, constant: 4),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: orderActionView.topAnchor),
            
            orderActionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            orderActionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            orderActionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        updateOrderActionView()
    }
    
    // MARK: - Binding
    
    private func bindCheckoutSpecific() {
        checkoutController.currentStep.observe(on: self) { [weak self] step in
            self?.progressIndicator.updateProgress(to: CheckoutProgressIndicator.Step(rawValue: step.rawValue) ?? .placeOrder)
            self?.updateOrderActionView()
        }
        
        checkoutController.selectedAddress.observe(on: self) { [weak self] _ in
            self?.updateOrderActionView()
            self?.collectionView.reloadData()
        }
        
        checkoutController.cartItems.observe(on: self) { [weak self] _ in
            self?.collectionView.reloadData()
        }
        
        checkoutController.orderSummary.observe(on: self) { [weak self] _ in
            self?.updateOrderActionView()
            self?.collectionView.reloadData()
        }
        
        checkoutController.loading.observe(on: self) { [weak self] isLoading in
            self?.orderActionView.isLoading = isLoading
        }
        
        checkoutController.error.observe(on: self) { [weak self] error in
            guard let error = error else { return }
            self?.showAlert(title: "Error", message: error.localizedDescription)
        }
        
        // Setup callback to navigate to PaymentMethodViewController
        if let defaultController = checkoutController as? DefaultCheckoutController {
            defaultController.onNavigateToPaymentMethod = { [weak self] order, clientSecret, paymentIntentId, customerId, ephemeralKey in
                self?.navigateToPaymentMethod(
                    order: order,
                    clientSecret: clientSecret,
                    paymentIntentId: paymentIntentId,
                    customerId: customerId,
                    ephemeralKey: ephemeralKey
                )
            }
        }
        
        checkoutController.readyForPayment.observe(on: self) { [weak self] ready in
            guard let self = self else { return }
            // Khi ready, cập nhật UI
            self.updateOrderActionView()
            // Tự động hiển thị PaymentSheet nếu đang ở trạng thái chờ (sau khi tap Add new card hoặc Choose Card)
            if ready && self.shouldAutoShowPaymentSheet {
                self.shouldAutoShowPaymentSheet = false
                self.showPaymentSheetIfReady()
            }
        }
    }
    
    private func updateOrderActionView() {
        let step = checkoutController.currentStep.value
        let hasAddress = checkoutController.selectedAddress.value != nil
        
        // Bỏ topLeftLabelText và topRightLabelText
        orderActionView.topLeftLabelText = nil
        orderActionView.topRightLabelText = nil
        
        if !hasAddress {
            // No address - show "Add address" button
            orderActionView.buttonTitle = "Add address"
            orderActionView.leftItemType = .none
            orderActionView.isButtonEnabled = true
            return
        }
        
        switch step {
        case .placeOrder:
            orderActionView.buttonTitle = "Order"
            orderActionView.leftItemType = .none
            orderActionView.isButtonEnabled = true
        case .createCustomer:
            orderActionView.buttonTitle = "Processing..."
            orderActionView.isButtonEnabled = false
        case .createPayment:
            orderActionView.buttonTitle = "Create Payment"
            orderActionView.isButtonEnabled = false
        case .complete:
            // Khi ở step complete, nếu đã ready thì button sẽ trigger PaymentSheet
            // Nếu chưa ready thì hiển thị "Processing..."
            if checkoutController.readyForPayment.value {
                orderActionView.buttonTitle = "Pay Now"
                orderActionView.isButtonEnabled = true
            } else {
                orderActionView.buttonTitle = "Processing..."
                orderActionView.isButtonEnabled = false
            }
        }
    }
}

// MARK: - UICollectionViewDataSource

extension CheckoutViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 3 // Address, Products, Summary
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0: return 1 // Address
        case 1: return 1 // Products
        case 2: return 1 // Order summary
        default: return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {
        case 0:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CheckoutAddressCell", for: indexPath) as! CheckoutAddressCell
            cell.configure(
                address: checkoutController.selectedAddress.value,
                useDefault: checkoutController.useDefaultAddress.value,
                onTap: { [weak self] in
                    self?.checkoutController.didTapAddAddress()
                    self?.showAddressCard()
                },
                onToggleDefault: { [weak self] isDefault in
                    self?.checkoutController.didToggleUseDefaultAddress(isDefault)
                },
                onTapUseSavedLocation: { [weak self] in
                    self?.showLocationListCard()
                }
            )
            return cell
        case 1:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CheckoutProductsCell", for: indexPath) as! CheckoutProductsCell
            // Pass shippingFeePerItem từ address (String?)
            let shippingFeePerItem = checkoutController.selectedAddress.value?.shippingFee
            cell.configure(
                items: checkoutController.cartItems.value,
                note: checkoutController.noteToSeller.value,
                shippingFeePerItem: shippingFeePerItem,
                onQuantityChanged: { [weak self] productId, quantity in
                    self?.checkoutController.didUpdateCartItemQuantity(productId: productId, quantity: quantity)
                },
                onTapAddNote: { [weak self] in
                    self?.showNotePopup()
                }
            )
            return cell
        case 2:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CheckoutOrderSummaryCell", for: indexPath) as! CheckoutOrderSummaryCell
            // Pass shippingFee từ address nếu có (String?) và items để tính số lượng
            let shippingFeeFromAddress = checkoutController.selectedAddress.value?.shippingFee
            cell.configure(
                summary: checkoutController.orderSummary.value,
                shippingFeeFromAddress: shippingFeeFromAddress,
                items: checkoutController.cartItems.value
            )
            return cell
        default:
            return UICollectionViewCell()
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension CheckoutViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width
        switch indexPath.section {
        case 0: return CGSize(width: width, height: 100) // Address (reduced from 120 - removed checkbox)
        case 1: return CGSize(width: width, height: 260) // Products scroll + note (reduced from 280)
        case 2: return CGSize(width: width, height: 120) // Order summary (reduced from 140)
        default: return CGSize(width: width, height: 100)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "SectionHeader", for: indexPath) as! SectionHeaderView
            switch indexPath.section {
            case 0: header.title = nil // Không có title cho section 0
            case 1: header.title = "product".localized()
            case 2: header.title = "order_summary".localized()
            default: header.title = nil
            }
            return header
        }
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == 0 {
            return CGSize(width: collectionView.bounds.width, height: 1) // Divider nhỏ cho section 0
        }
        return CGSize(width: collectionView.bounds.width, height: 12) // Header với title (reduced from 24)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0) // Reduced from 8
    }
}

// MARK: - OrderActionViewDelegate

extension CheckoutViewController: OrderActionViewDelegate {
    
    func orderActionViewDidTapAction(_ view: OrderActionView) {
        let hasAddress = checkoutController.selectedAddress.value != nil
        
        if !hasAddress {
            showAddressCard()
            return
        }
        
        let step = checkoutController.currentStep.value
        switch step {
        case .placeOrder:
            checkoutController.didTapPlaceOrder()
        case .complete:
            // Hiển thị PaymentSheet khi user tap button
            if checkoutController.readyForPayment.value {
                showPaymentSheetIfReady()
            }
        default:
            break
        }
    }
    
    func orderActionViewDidTapLeftItem(_ view: OrderActionView) {
        // Khi tap vào label $ (tổng giá) thì mở popup PricingCaculationPopup
        showPricingPopup()
    }
    
    func orderActionViewDidTapTopRightLabel(_ view: OrderActionView) {
        // Show pricing calculation popup
        showPricingPopup()
    }
}

// MARK: - Helper Methods

extension CheckoutViewController {
    
    private func showAddressCard() {
        // Create CardViewController with AddressViewController
        let appDIContainer = AppDIContainer()
        let addressDIContainer = appDIContainer.makeAddressDIContainer()
        let addressVC = addressDIContainer.makeAddressViewController()
        
        let cardConfig = CardConfiguration(
            expandedHeight: view.bounds.height - 100,
            collapsedHeight: view.bounds.height - 100,
            presentationMode: .onDemand,
            enableGesture: true
        )
        
        let cardController = DefaultCardController(configuration: cardConfig)
        let cardVC = CardViewController.create(with: cardController)
        cardVC.attach(to: self)
        addressCardViewController = cardVC
        cardVC.setContent(addressVC)
        
        // Setup callback when address is saved (after cardVC is created)
        if let addressController = addressVC.controller as? DefaultAddressController {
            addressController.onAddressSaved = { [weak self, weak cardVC] address in
                self?.checkoutController.didSelectAddress(address)
                cardVC?.dismiss()
                if cardVC === self?.addressCardViewController {
                    self?.addressCardViewController = nil
                }
            }
        }
        
        // Also setup callback for LocationList if user selects from list
        // This is handled inside AddressViewController when user taps the list icon
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            cardVC.show()
        }
    }
    
    private func showLocationListCard() {
        // Prevent opening multiple times
        if let existingCard = locationListCardViewController, existingCard.parent != nil {
            existingCard.show()
            return
        }
        
        // If card exists but is not attached, clean it up first
        if locationListCardViewController != nil {
            locationListCardViewController?.detach()
            locationListCardViewController = nil
        }
        
        // Check cache first
        let utilities = Utilities()
        var cachedAddress: Address? = nil
        
        if utilities.hasLocationCache() {
            // Create Address from cache
            if let addressId = utilities.getCachedAddressId(),
               let addressDetail = utilities.getCachedAddressDetail(),
               let provinceId = utilities.getCachedProvinceId(),
               let districtId = utilities.getCachedDistrictId(),
               let wardId = utilities.getCachedWardId(),
               let countryId = utilities.getCachedCountryId() {
                cachedAddress = Address(
                    id: addressId,
                    userId: 0,
                    contactPersonName: utilities.getCachedContactPersonName() ?? "",
                    contactPersonNumber: utilities.getCachedContactPersonNumber() ?? "",
                    address: utilities.getCachedAddress() ?? addressDetail,
                    addressDetail: addressDetail,
                    addressType: utilities.getCachedAddressType() ?? "shipping",
                    zoneId: nil,
                    countryId: countryId,
                    provinceId: provinceId,
                    districtId: districtId,
                    wardId: wardId,
                    longitude: utilities.getCachedLongitude() ?? "",
                    latitude: utilities.getCachedLatitude() ?? "",
                    shippingFee: nil,
                    isDefault: true
                )
            }
        }
        
        // Create Card Configuration
        let screenHeight = view.bounds.height
        let cardHeight = screenHeight - 120
        let cardConfig = CardConfiguration(
            expandedHeight: cardHeight,
            collapsedHeight: cardHeight,
            presentationMode: .onDemand,
            enableGesture: true
        )
        
        // Create Card Controller
        let cardController = DefaultCardController(configuration: cardConfig)
        
        // Create Card View Controller
        let cardVC = CardViewController.create(with: cardController)
        
        // Attach to current view controller
        cardVC.attach(to: self)
        
        // Store reference
        locationListCardViewController = cardVC
        
        // Create LocationListViewController as content
        let appDIContainer = AppDIContainer()
        let locationListDIContainer = appDIContainer.makeLocationListDIContainer()
        let locationListVC = locationListDIContainer.makeLocationListViewController()
        
        // Setup callback when address is selected
        if let locationListController = locationListVC.controller as? DefaultLocationListController {
            // If we have cached address, add it to the list first
            if let cached = cachedAddress {
                locationListController.addresses.value = [cached]
            }
            
            // Fetch from API (will replace or append to list)
            locationListController.viewDidLoad()
            
            // Observe addresses to merge cache with API results
            locationListController.addresses.observe(on: self) { [weak self] addresses in
                guard let self = self, let cached = cachedAddress else { return }
                // If API returned addresses and we have cached address, ensure cached is in the list
                if !addresses.contains(where: { $0.id == cached.id }) {
                    var updatedAddresses = addresses
                    updatedAddresses.insert(cached, at: 0) // Add cached address at the beginning
                    locationListController.addresses.value = updatedAddresses
                }
            }
            
            locationListController.onAddressSelected = { [weak self, weak cardVC] address in
                // Select address in checkout
                self?.checkoutController.didSelectAddress(address)
                cardVC?.dismiss()
                // Clear reference when dismissed
                if cardVC === self?.locationListCardViewController {
                    self?.locationListCardViewController = nil
                }
            }
        }
        
        // Set LocationListViewController as content of CardViewController
        cardVC.setContent(locationListVC)
        
        // Show card
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            cardVC.show()
        }
    }
    
    private func showNotePopup() {
        // Create and show note popup
        let popup = NoteToSellerPopup()
        popup.configure(
            initialNote: checkoutController.noteToSeller.value,
            onSave: { [weak self] note in
                // Note is now optional, can be nil if empty
                self?.checkoutController.didSaveNoteToSeller(note ?? "")
                popup.dismiss()
            },
            onCancel: {
                popup.dismiss()
            }
        )
        popup.show(in: view)
    }
    
    private func showPricingPopup() {
        let popup = PricingCaculationPopup()
        if let summary = checkoutController.orderSummary.value {
            popup.orderBreakdownValueLabel.text = String(format: "USD %.2f", summary.subtotal)
            popup.shippingValueLabel.text = String(format: "USD %.2f", summary.shippingFee)
            popup.subTotalValue.text = String(format: "USD %.2f", summary.total)
        }
        popup.show(in: view)
    }
    
    private func showPaymentSheetIfReady() {
        // Lấy thông tin từ controller thông qua một cách an toàn
        // Vì các properties là private, chúng ta cần thêm output observables hoặc methods
        guard let defaultController = checkoutController as? DefaultCheckoutController else { return }
        
        // Kiểm tra xem đã có đủ thông tin chưa
        guard defaultController.readyForPayment.value else {
            return
        }
        
        // Gọi method để lấy payment info
        defaultController.getPaymentInfo { [weak self] clientSecret, customerId, ephemeralKey in
            guard let self = self,
                  let clientSecret = clientSecret,
                  let customerId = customerId,
                  let ephemeralKey = ephemeralKey else {
                return
            }
            
            self.preparePaymentSheet(clientSecret: clientSecret, customerId: customerId, ephemeralKey: ephemeralKey)
        }
    }
    
    private func showPaymentSheet() {
        showPaymentSheetIfReady()
    }
    
    private func preparePaymentSheet(clientSecret: String, customerId: String, ephemeralKey: String) {
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "My Shop"
        
        configuration.customer = .init(
            id: customerId,
            ephemeralKeySecret: ephemeralKey
        )
        
        configuration.allowsDelayedPaymentMethods = false
        
        paymentSheet = PaymentSheet(
            paymentIntentClientSecret: clientSecret,
            configuration: configuration
        )
        
        paymentSheet?.present(from: self) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .completed:
                // Notify backend success
                self.notifyBackendSuccess()
                
            case .canceled: break
                // User canceled, không cần làm gì
                
            case .failed(let error):
                self.showAlert(title: "Payment Failed", message: error.localizedDescription)
            }
        }
    }
    
    private func notifyBackendSuccess() {
        guard let defaultController = checkoutController as? DefaultCheckoutController,
              let paymentIntentId = defaultController.getPaymentIntentId() else {
            return
        }
        
        // Call confirm payment API
        defaultController.confirmPayment(paymentIntentId: paymentIntentId) { [weak self] success in
            if success {
                // Navigate to success screen
                // TODO: Navigate to success screen
            } else {
                self?.showAlert(title: "error".localized(), message: "failed_to_confirm_payment".localized())
            }
        }
    }
    
    // MARK: - Navigation
    
    private func navigateToPaymentMethod(
        order: Order,
        clientSecret: String,
        paymentIntentId: String,
        customerId: String?,
        ephemeralKey: String?
    ) {
        guard let navigationController = navigationController else { return }
        
        // Create DIContainer
        let appDIContainer = AppDIContainer.shared
        let checkoutDIContainer = appDIContainer.makeCheckoutSceneDIContainer()
        let paymentMethodVC = checkoutDIContainer.makePaymentMethodViewController(
            order: order,
            clientSecret: clientSecret,
            paymentIntentId: paymentIntentId,
            customerId: customerId,
            ephemeralKey: ephemeralKey
        )
        
        // Pass purchased product IDs to PaymentMethodController for removal after payment success
        if let defaultCheckoutController = checkoutController as? DefaultCheckoutController {
            let productIds = defaultCheckoutController.getPurchasedProductIds()
            if let defaultPaymentController = paymentMethodVC.paymentMethodController as? DefaultPaymentMethodController {
                defaultPaymentController.setPurchasedProductIds(productIds)
            }
        }
        
        navigationController.pushViewController(paymentMethodVC, animated: true)
    }
}

