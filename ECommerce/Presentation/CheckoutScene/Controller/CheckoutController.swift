//
//  CheckoutController.swift
//  ECommerce
//
//  Created by wizard.os25 on 15/1/26.
//

import Foundation
import UIKit

protocol CheckoutControllerInput {
    func didLoadView()
    func didTapAddAddress()
    func didTapPlaceOrder()
    func didSelectPaymentMethod(_ method: PaymentMethod)
    func didUpdateCartItemQuantity(productId: Int, quantity: Int)
    func didTapAddNoteToSeller()
    func didSaveNoteToSeller(_ note: String)
    func didToggleUseDefaultAddress(_ isDefault: Bool)
    func didSelectAddress(_ address: Address)
    func confirmPayment(paymentIntentId: String, completion: @escaping (Bool) -> Void)
    func didTapAddNewCard()
    func didTapChooseCard()
}

protocol CheckoutControllerOutput {
    var cartItems: Observable<[CheckoutCartItem]> { get }
    var selectedAddress: Observable<Address?> { get }
    var useDefaultAddress: Observable<Bool> { get }
    var paymentMethods: Observable<[PaymentMethod]> { get }
    var selectedPaymentMethod: Observable<PaymentMethod?> { get }
    var paymentCards: Observable<[PaymentCard]> { get }
    var defaultPaymentCard: Observable<PaymentCard?> { get }
    var readyForPayment: Observable<Bool> { get }
    var orderSummary: Observable<OrderSummary?> { get }
    var noteToSeller: Observable<String?> { get }
    var currentStep: Observable<CheckoutStep> { get }
    var screenTitle: String { get }
    var onNavigateToPaymentMethod: ((Order, String, String, String?, String?) -> Void)? { get set } // order, clientSecret, paymentIntentId, customerId, ephemeralKey
}

typealias CheckoutController = CheckoutControllerInput & CheckoutControllerOutput & EcoController

// Models are defined in CheckoutModel.swift

final class DefaultCheckoutController: CheckoutController {
    
    private let orderUseCase: OrderUseCase
    private let paymentCardUseCase: PaymentCardUseCase
    private let utilities: Utilities
    private let mainQueue: DispatchQueueType
    
    private var placeOrderTask: Cancellable? { willSet { placeOrderTask?.cancel() } }
    private var createCustomerTask: Cancellable? { willSet { createCustomerTask?.cancel() } }
    private var createPaymentIntentTask: Cancellable? { willSet { createPaymentIntentTask?.cancel() } }
    
    // Store order data
    private var placedOrder: Order?
    private var customerId: String?
    private var ephemeralKey: String?
    private var paymentIntentClientSecret: String?
    private var paymentIntentId: String?
    
    // MARK: - OUTPUT
    
    let cartItems: Observable<[CheckoutCartItem]> = Observable([])
    let selectedAddress: Observable<Address?> = Observable(nil)
    let useDefaultAddress: Observable<Bool> = Observable(false)
    let paymentMethods: Observable<[PaymentMethod]> = Observable([.addNewCard, .chooseCard])
    let selectedPaymentMethod: Observable<PaymentMethod?> = Observable(.addNewCard)
    let paymentCards: Observable<[PaymentCard]> = Observable([])
    let defaultPaymentCard: Observable<PaymentCard?> = Observable(nil)
    let readyForPayment: Observable<Bool> = Observable(false) // Khi đã có đủ thông tin để hiển thị PaymentSheet
    let orderSummary: Observable<OrderSummary?> = Observable(nil)
    let noteToSeller: Observable<String?> = Observable(nil)
    let currentStep: Observable<CheckoutStep> = Observable(.placeOrder)
    var screenTitle: String { "checkout".localized() }
    
    var onNavigateToPaymentMethod: ((Order, String, String, String?, String?) -> Void)?
    
    // MARK: - EcoController Output
    
    let loading: Observable<Bool> = Observable(false)
    let error: Observable<Error?> = Observable(nil)
    let navigationState: Observable<EcoNavigationState> = Observable(.init())
    
    // MARK: - Navigation Bar Configuration
    
    var navigationBarTitle: String? {
        return screenTitle
    }
    
    var navigationBarLeftItem: EcoNavItem? {
        return EcoNavItem.back { [weak self] in
            self?.onNavigationBarLeftItemTap?()
        }
    }
    
    var navigationBarBackground: EcoNavigationBackground {
        return .solid(.white)
    }
    
    var navigationBarBackgroundColor: UIColor? {
        return .white
    }
    
    var navigationBarButtonTintColor: UIColor? {
        return Colors.tokenDark100
    }
    
    var navigationBarTitleColor: UIColor? {
        return .black
    }
    
    // MARK: - Init
    
    init(
        orderUseCase: OrderUseCase,
        paymentCardUseCase: PaymentCardUseCase,
        cartItems: [CartItem],
        product: ProductDetailModel?,
        productMap: [Int: ProductDetailModel]? = nil, // Map productId -> ProductDetailModel for multiple items
        utilities: Utilities = Utilities(),
        mainQueue: DispatchQueueType = DispatchQueue.main
    ) {
        self.orderUseCase = orderUseCase
        self.paymentCardUseCase = paymentCardUseCase
        self.utilities = utilities
        self.mainQueue = mainQueue
        
        // Convert CartItem to CheckoutCartItem với product details
        // Priority: productMap > product > fallback
        if let productMap = productMap {
            // Nếu có productMap, sử dụng thông tin riêng cho từng item
            self.cartItems.value = cartItems.compactMap { item in
                guard let product = productMap[item.id] else {
                    return nil
                }
                return CheckoutCartItem(
                    productId: item.id,
                    productName: product.name,
                    productImageUrl: product.imageUrl,
                    price: product.price,
                    quantity: item.quantity
                )
            }
        } else if let product = product {
            // Nếu có single product details, sử dụng thông tin từ đó (backward compatibility)
            self.cartItems.value = cartItems.map { item in
                CheckoutCartItem(
                    productId: item.id,
                    productName: product.name,
                    productImageUrl: product.imageUrl,
                    price: product.price,
                    quantity: item.quantity
                )
            }
        } else {
            // Fallback nếu không có product details
            self.cartItems.value = cartItems.map { item in
                CheckoutCartItem(
                    productId: item.id,
                    productName: "Product \(item.id)",
                    productImageUrl: nil,
                    price: "$0.00",
                    quantity: item.quantity
                )
            }
        }
        
        // Check if address exists
        checkAddressStatus()
    }
    
    // Store product IDs for removal after successful payment
    private var purchasedProductIds: [Int] = []
    
    func setPurchasedProductIds(_ productIds: [Int]) {
        purchasedProductIds = productIds
    }
    
    func getPurchasedProductIds() -> [Int] {
        return purchasedProductIds
    }
    
    // MARK: - Private
    
    private func checkAddressStatus() {
        // For now, we'll check if address exists in cache
        // In a real app, you might want to load from API
        let addressString = utilities.getCachedAddress()
        if addressString != nil && !addressString!.isEmpty {
            // Create a basic Address from cached data
            // In real app, you'd load full address from API
            let address = Address(
                id: 0,
                userId: 0,
                contactPersonName: "",
                contactPersonNumber: "",
                address: addressString ?? "",
                addressDetail: addressString ?? "",
                addressType: "shipping",
                zoneId: nil,
                countryId: 1,
                provinceId: 2,
                districtId: 0,
                wardId: 0,
                longitude: utilities.getCachedLongitude() ?? "",
                latitude: utilities.getCachedLatitude() ?? "",
                shippingFee: nil,
                isDefault: false
            )
            selectedAddress.value = address
        }
    }
    
    private func calculateOrderSummary() {
        // Calculate subtotal: tổng price của các sản phẩm
        let subtotal = cartItems.value.reduce(0.0) { total, item in
            let price = item.price.convertMoneyToNumber()
            return total + (price * Double(item.quantity))
        }
        
        // Calculate shipping fee: số lượng sản phẩm * shipping_fee từ address
        let totalQuantity = cartItems.value.reduce(0) { $0 + $1.quantity }
        var shippingFee: Double = 0.0
        
        if let address = selectedAddress.value,
           let shippingFeeString = address.shippingFee,
           !shippingFeeString.isEmpty,
           let shippingFeePerItem = Double(shippingFeeString) {
            shippingFee = shippingFeePerItem * Double(totalQuantity)
        }
        
        let total = subtotal + shippingFee
        
        orderSummary.value = OrderSummary(
            subtotal: subtotal,
            shippingFee: shippingFee,
            total: total
        )
    }
    
    private func handle(error: Error) {
        let errorMessage = APIErrorParser.parseErrorMessage(from: error)
        let userFriendlyError = NSError(
            domain: "CheckoutError",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: errorMessage]
        )
        self.error.value = userFriendlyError
    }
}

// MARK: - INPUT Implementation

extension DefaultCheckoutController {
    
    func didLoadView() {
        calculateOrderSummary()
        loadPaymentCards()
    }
    
    private func loadPaymentCards() {
        paymentCardUseCase.getPaymentMethods { [weak self] result in
            self?.mainQueue.async {
                switch result {
                case .success(let cards):
                    self?.paymentCards.value = cards
                    if let defaultCard = cards.first(where: { $0.isDefault }) {
                        self?.defaultPaymentCard.value = defaultCard
                    }
                case .failure:
                    // Ignore error for payment cards loading
                    self?.paymentCards.value = []
                    self?.defaultPaymentCard.value = nil
                }
            }
        }
    }
    
    func didTapAddAddress() {
        // This will be handled in ViewController to show AddressViewController
    }
    
    func didTapPlaceOrder() {
        guard let address = selectedAddress.value else {
            let error = NSError(
                domain: "CheckoutError",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Please add an address first"]
            )
            handle(error: error)
            return
        }
        
        loading.value = true
        currentStep.value = .placeOrder
        
        // Convert cart items
        let cart = cartItems.value.map { CartItem(id: $0.productId, quantity: $0.quantity) }
        
        // Determine if we should use delivery_address_id or address_detail
        // If address has an ID (saved address), use delivery_address_id
        // Otherwise, use address_detail with location details
        let deliveryAddressId: Int? = address.id > 0 ? address.id : nil
        let addressDetail: String? = address.id > 0 ? nil : address.addressDetail
        let countryId: Int? = address.id > 0 ? nil : address.countryId
        let provinceId: Int? = address.id > 0 ? nil : address.provinceId
        let districtId: Int? = address.id > 0 ? nil : address.districtId
        let wardId: Int? = address.id > 0 ? nil : address.wardId
        let contactPersonName: String? = address.id > 0 ? nil : address.contactPersonName
        let contactPersonNumber: String? = address.id > 0 ? nil : address.contactPersonNumber
        
        placeOrderTask = orderUseCase.placeOrder(
            cart: cart,
            orderNote: noteToSeller.value,
            deliveryAddressId: deliveryAddressId,
            addressDetail: addressDetail,
            countryId: countryId,
            provinceId: provinceId,
            districtId: districtId,
            wardId: wardId,
            contactPersonName: contactPersonName,
            contactPersonNumber: contactPersonNumber
        ) { [weak self] result in
            self?.mainQueue.async {
                self?.loading.value = false
                
                switch result {
                case .success(let order):
                    self?.placedOrder = order
                    // Tạo payment intent sau khi place order thành công
                    self?.createPaymentIntent()
                case .failure(let error):
                    self?.handle(error: error)
                }
            }
        }
    }
    
    private func createPaymentIntent() {
        guard let order = placedOrder else { return }
        
        loading.value = true
        
        // Convert total amount to cents
        let amountInCents = Int(order.totalAmount)
        
        createPaymentIntentTask = paymentCardUseCase.createPaymentIntent(
            orderId: order.orderId,
            amount: amountInCents,
            paymentMethodId: nil
        ) { [weak self] result in
            self?.mainQueue.async {
                self?.loading.value = false
                
                switch result {
                case .success(let paymentIntent):
                    self?.paymentIntentClientSecret = paymentIntent.clientSecret
                    self?.paymentIntentId = paymentIntent.paymentIntentId
                    // Lấy customerId và ephemeralKey từ paymentIntent nếu có (optional)
                    if let customerId = paymentIntent.customerId {
                        self?.customerId = customerId
                    }
                    if let ephemeralKey = paymentIntent.ephemeralKey {
                        self?.ephemeralKey = ephemeralKey
                    }
                    // Push sang PaymentMethodViewController với order và payment intent info
                    if let order = self?.placedOrder,
                       let clientSecret = self?.paymentIntentClientSecret,
                       let paymentIntentId = self?.paymentIntentId {
                        self?.onNavigateToPaymentMethod?(
                            order,
                            clientSecret,
                            paymentIntentId,
                            self?.customerId,
                            self?.ephemeralKey
                        )
                    }
                case .failure(let error):
                    self?.handle(error: error)
                }
            }
        }
    }
    
    func didSelectPaymentMethod(_ method: PaymentMethod) {
        selectedPaymentMethod.value = method
    }
    
    func didUpdateCartItemQuantity(productId: Int, quantity: Int) {
        var items = cartItems.value
        if let index = items.firstIndex(where: { $0.productId == productId }) {
            items[index].quantity = quantity
            cartItems.value = items
            calculateOrderSummary()
        }
    }
    
    func didTapAddNoteToSeller() {
        // This will be handled in ViewController to show popup
    }
    
    func didSaveNoteToSeller(_ note: String) {
        // Allow empty note (optional field) - convert empty string to nil
        noteToSeller.value = note.isEmpty ? nil : note
    }
    
    func didToggleUseDefaultAddress(_ isDefault: Bool) {
        useDefaultAddress.value = isDefault
    }
    
    func didSelectAddress(_ address: Address) {
        selectedAddress.value = address
        
        // Save full location information to cache for use in Order screen
        utilities.saveLocation(address: address)
        
        // Recalculate order summary with new address shipping fee
        calculateOrderSummary()
    }
    
    func confirmPayment(paymentIntentId: String, completion: @escaping (Bool) -> Void) {
        paymentCardUseCase.confirmPayment(paymentIntentId: paymentIntentId) { [weak self] result in
            self?.mainQueue.async {
                switch result {
                case .success:
                    completion(true)
                case .failure:
                    completion(false)
                }
            }
        }
    }
    
    func getPaymentInfo(completion: @escaping (String?, String?, String?) -> Void) {
        completion(paymentIntentClientSecret, customerId, ephemeralKey)
    }
    
    func getPaymentIntentId() -> String? {
        return paymentIntentId
    }
    
    func didTapAddNewCard() {
        // Khi tap "Add a new card", cần setup payment để mở PaymentSheet
        // Nếu chưa có customer và payment intent, cần tạo trước
        setupPaymentForAddCard()
    }
    
    func didTapChooseCard() {
        // Khi tap "Choose Card", cần setup payment để mở PaymentSheet
        // Nếu chưa có customer và payment intent, cần tạo trước
        setupPaymentForAddCard()
    }
    
    private func setupPaymentForAddCard() {
        // Nếu đã có đủ thông tin, trigger readyForPayment
        if let clientSecret = paymentIntentClientSecret,
           let customerId = customerId,
           let ephemeralKey = ephemeralKey {
            readyForPayment.value = true
            return
        }
        
        // Nếu chưa có customer, tạo customer trước
        if customerId == nil {
            createCustomerForAddCard()
            return
        }
        
        // Nếu đã có customer nhưng chưa có payment intent
        // Cần có order để tạo payment intent
        // Nếu chưa có order, tạo một setup payment intent với amount nhỏ để add card
        if placedOrder == nil {
            // Tạo setup payment intent với amount = 1 cent để add card
            createSetupPaymentIntentForAddCard()
            return
        }
        
        // Nếu đã có order nhưng chưa có payment intent, tạo payment intent
        createPaymentIntent()
    }
    
    private func createCustomerForAddCard() {
        loading.value = true
        
        createCustomerTask = paymentCardUseCase.createCustomer { [weak self] result in
            self?.mainQueue.async {
                self?.loading.value = false
                
                switch result {
                case .success(let customerId):
                    self?.customerId = customerId
                    // Tiếp tục setup payment intent
                    self?.setupPaymentForAddCard()
                case .failure(let error):
                    self?.handle(error: error)
                }
            }
        }
    }
    
    private func createSetupPaymentIntentForAddCard() {
        // Tạo một setup payment intent với amount nhỏ (50 cents - minimum) để có thể add card
        // Order ID tạm thời = 0 (backend có thể không validate order_id khi add card)
        loading.value = true
        
        // Sử dụng amount = 50 cents (minimum theo Stripe) để setup payment intent
        let setupAmount = 50 // 50 cents (minimum)
        
        createPaymentIntentTask = paymentCardUseCase.createPaymentIntent(
            orderId: 0, // Setup order ID - có thể backend không validate khi chỉ add card
            amount: setupAmount,
            paymentMethodId: nil
        ) { [weak self] result in
            self?.mainQueue.async {
                self?.loading.value = false
                
                switch result {
                case .success(let paymentIntent):
                    self?.paymentIntentClientSecret = paymentIntent.clientSecret
                    self?.paymentIntentId = paymentIntent.paymentIntentId
                    // Lấy customerId và ephemeralKey từ paymentIntent nếu có
                    if let customerId = paymentIntent.customerId {
                        self?.customerId = customerId
                    }
                    if let ephemeralKey = paymentIntent.ephemeralKey {
                        self?.ephemeralKey = ephemeralKey
                    }
                    // Đánh dấu sẵn sàng để hiển thị PaymentSheet
                    self?.readyForPayment.value = true
                case .failure(let error):
                    // Nếu không thể tạo payment intent (có thể do backend yêu cầu order_id hợp lệ)
                    // Hiển thị message yêu cầu user place order trước
                    let errorMessage = APIErrorParser.parseErrorMessage(from: error)
                    // Có thể hiển thị alert yêu cầu user place order trước
                    self?.handle(error: error)
                }
            }
        }
    }
}

// MARK: - EcoController Implementation

extension DefaultCheckoutController {
    
    func onViewDidLoad() {
        navigationState.value = EcoNavigationState(
            title: navigationBarTitle,
            titleFont: navigationBarTitleFont,
            titleColor: navigationBarTitleColor,
            showsSearch: false,
            searchState: nil,
            leftItem: navigationBarLeftItem,
            rightItems: navigationBarRightItems,
            background: navigationBarBackground,
            backgroundColor: navigationBarBackgroundColor,
            buttonTintColor: navigationBarButtonTintColor,
            height: navigationBarInitialHeight,
            collapsedHeight: navigationBarCollapsedHeight,
            backButtonStyle: .simple,
            scrollBehavior: navigationBarScrollBehavior
        )
    }
    
    func onViewWillAppear() {}
    func onViewDidDisappear() {}
}

