//
//  PaymentMethodController.swift
//  ECommerce
//
//  Created by wizard.os25 on 15/1/26.
//

import UIKit
import StripePaymentSheet

protocol PaymentMethodControllerInput {
    func didLoadView()
    func didTapAddNewCard()
    func didSelectCard(_ card: PaymentCard)
    func didTapPay()
    func handlePaymentSheetResult(_ result: PaymentSheetResult, paymentMethodId: String?)
    func confirmPayment(paymentIntentId: String, completion: @escaping (Bool) -> Void)
    func setDefaultCard(paymentMethodId: String, completion: @escaping (Bool) -> Void)
    func createPaymentIntentWithoutMethod(completion: @escaping (Result<PaymentIntent, Error>) -> Void)
}

protocol PaymentMethodControllerOutput {
    var paymentCards: Observable<[PaymentCard]> { get }
    var selectedCard: Observable<PaymentCard?> { get }
    var loading: Observable<Bool> { get }
    var error: Observable<Error?> { get }
    var screenTitle: String { get }
    var onShowPaymentSheet: (() -> Void)? { get set } // Callback to show PaymentSheet
    var onPaymentSuccess: (() -> Void)? { get set } // Callback when payment is confirmed
    func setPurchasedProductIds(_ productIds: [Int])
    func getPurchasedProductIds() -> [Int]
}

typealias PaymentMethodController = PaymentMethodControllerInput & PaymentMethodControllerOutput & EcoController

final class DefaultPaymentMethodController: PaymentMethodController {
    
    private let paymentCardUseCase: PaymentCardUseCase
    private let order: Order
    private let customerId: String
    private let mainQueue: DispatchQueueType
    
    private var loadPaymentCardsTask: Cancellable? { willSet { loadPaymentCardsTask?.cancel() } }
    private var attachPaymentMethodTask: Cancellable? { willSet { attachPaymentMethodTask?.cancel() } }
    private var createPaymentIntentTask: Cancellable? { willSet { createPaymentIntentTask?.cancel() } }
    private var setDefaultPaymentMethodTask: Cancellable? { willSet { setDefaultPaymentMethodTask?.cancel() } }
    
    private var paymentIntentClientSecret: String?
    private var paymentIntentId: String?
    private var ephemeralKey: String?
    private var isAddingCard: Bool = false // Flag to distinguish between adding card and paying
    
    // MARK: - OUTPUT
    
    let paymentCards: Observable<[PaymentCard]> = Observable([])
    let selectedCard: Observable<PaymentCard?> = Observable(nil)
    let loading: Observable<Bool> = Observable(false)
    let error: Observable<Error?> = Observable(nil)
    var screenTitle: String { "confirm_payment".localized() }
    
    var onShowPaymentSheet: (() -> Void)?
    var onPaymentSuccess: (() -> Void)?
    
    // Store product IDs for removal after successful payment
    private var purchasedProductIds: [Int] = []
    
    func setPurchasedProductIds(_ productIds: [Int]) {
        purchasedProductIds = productIds
    }
    
    func getPurchasedProductIds() -> [Int] {
        return purchasedProductIds
    }
    
    // MARK: - EcoController Output
    
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
    
    var navigationBarRightItems: [EcoNavItem]? {
        return nil
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
    
    var navigationBarTitleFont: UIFont? {
        return Typography.fontBold18
    }
    
    var navigationBarInitialHeight: CGFloat {
        return 180
    }
    
    var navigationBarCollapsedHeight: CGFloat {
        return 180
    }
    
    var navigationBarScrollBehavior: EcoNavigationScrollBehavior {
        return .default
    }
    
    var onNavigationBarLeftItemTap: (() -> Void)?
    
    // MARK: - Init
    
    init(
        paymentCardUseCase: PaymentCardUseCase,
        order: Order,
        clientSecret: String,
        paymentIntentId: String,
        customerId: String? = nil,
        ephemeralKey: String? = nil,
        mainQueue: DispatchQueueType = DispatchQueue.main
    ) {
        self.paymentCardUseCase = paymentCardUseCase
        self.order = order
        self.paymentIntentClientSecret = clientSecret
        self.paymentIntentId = paymentIntentId
        /// `CustomerId`no need
        self.customerId = customerId ?? "hi"
        self.ephemeralKey = ephemeralKey
        self.mainQueue = mainQueue
    }
}

// MARK: - INPUT Implementation

extension DefaultPaymentMethodController {
    
    func didLoadView() {
        // Load payment cards will be called in viewWillAppear
    }
    
    func loadPaymentCards() {
        loading.value = true
        error.value = nil
        
        loadPaymentCardsTask = paymentCardUseCase.getPaymentMethods { [weak self] result in
            guard let self = self else { return }
            self.mainQueue.async {
                self.loading.value = false
                
                switch result {
                case .success(let cards):
                    self.paymentCards.value = cards
                    // Set default card if available
                    if let defaultCard = cards.first(where: { $0.isDefault }) {
                        self.selectedCard.value = defaultCard
                    }
                case .failure(let error):
                    self.error.value = error
                    self.paymentCards.value = []
                }
            }
        }
    }
    
    func didTapAddNewCard() {
        isAddingCard = true
        // Sử dụng payment intent đã có sẵn (từ CheckoutViewController) để mở PaymentSheet
        // Không cần tạo payment intent mới
        if paymentIntentClientSecret != nil {
            // Payment intent đã có sẵn, hiển thị PaymentSheet ngay
            onShowPaymentSheet?()
        } else {
            // Nếu chưa có payment intent, tạo setup payment intent
            createSetupPaymentIntentForAddCard()
        }
    }
    
    private func createSetupPaymentIntentForAddCard() {
        loading.value = true
        
        // Create setup payment intent with minimum amount (50 cents)
        let setupAmount = 50 // 50 cents (minimum)
        
        createPaymentIntentTask = paymentCardUseCase.createPaymentIntent(
            orderId: order.orderId, // Use existing order ID
            amount: setupAmount,
            paymentMethodId: nil
        ) { [weak self] result in
            guard let self = self else { return }
            self.mainQueue.async {
                self.loading.value = false
                
                switch result {
                case .success(let paymentIntent):
                    self.paymentIntentClientSecret = paymentIntent.clientSecret
                    self.paymentIntentId = paymentIntent.paymentIntentId
                    if let ephemeralKey = paymentIntent.ephemeralKey {
                        self.ephemeralKey = ephemeralKey
                    }
                    // Trigger callback to show PaymentSheet
                    self.onShowPaymentSheet?()
                case .failure(let error):
                    self.error.value = error
                }
            }
        }
    }
    
    func didSelectCard(_ card: PaymentCard) {
        selectedCard.value = card
    }
    
    func didTapPay() {
        // Flow mới: Chọn thẻ đã lưu → Face ID → API create-payment-intent → STPPaymentHandler
        // Không gọi onShowPaymentSheet nữa, xử lý trong ViewController
        // ViewController sẽ gọi processPayment() trực tiếp
    }
    
    func setDefaultCard(paymentMethodId: String, completion: @escaping (Bool) -> Void) {
        setDefaultPaymentMethodTask = paymentCardUseCase.setDefaultPaymentMethod(paymentMethodId: paymentMethodId) { [weak self] result in
            guard let self = self else { return }
            self.mainQueue.async {
                switch result {
                case .success:
                    completion(true)
                case .failure:
                    completion(false)
                }
            }
        }
    }
    
    func handlePaymentSheetResult(_ result: PaymentSheetResult, paymentMethodId: String?) {
        switch result {
        case .completed:
            if isAddingCard {
                // Adding card completed - PaymentSheet automatically attached it to customer
                // Reload payment cards to get the new card
                loadPaymentCards()
                isAddingCard = false
            } else {
                // Payment completed successfully
                // Confirm payment with backend
                if let paymentIntentId = paymentIntentId {
                    confirmPayment(paymentIntentId: paymentIntentId) { [weak self] success in
                        if success {
                            self?.onPaymentSuccess?()
                        }
                    }
                }
            }
        case .canceled:
            // User canceled
            isAddingCard = false
            break
        case .failed(let error):
            self.error.value = error
            isAddingCard = false
        }
    }
    
    func confirmPayment(paymentIntentId: String, completion: @escaping (Bool) -> Void) {
        loading.value = true
        
        loading.value = true
        
        // Call confirm payment API
        paymentCardUseCase.confirmPayment(paymentIntentId: paymentIntentId) { [weak self] result in
            guard let self = self else { return }
            self.mainQueue.async {
                self.loading.value = false
                
                switch result {
                case .success:
                    // Payment confirmed successfully
                    completion(true)
                case .failure(let error):
                    self.error.value = error
                    completion(false)
                }
            }
        }
    }
    
    private func attachPaymentMethod(paymentMethodId: String, completion: @escaping (Bool) -> Void) {
        loading.value = true
        
        attachPaymentMethodTask = paymentCardUseCase.attachPaymentMethod(paymentMethodId: paymentMethodId) { [weak self] result in
            guard let self = self else { return }
            self.mainQueue.async {
                self.loading.value = false
                
                switch result {
                case .success:
                    // Reload payment cards to get the new card
                    self.loadPaymentCards()
                    completion(true)
                case .failure(let error):
                    self.error.value = error
                    completion(false)
                }
            }
        }
    }
    
    private func createPaymentIntent(paymentMethodId: String?) {
        loading.value = true
        
        // Convert total amount to cents
        let amountInCents = Int(order.totalAmount)
        
        createPaymentIntentTask = paymentCardUseCase.createPaymentIntent(
            orderId: order.orderId,
            amount: amountInCents,
            paymentMethodId: paymentMethodId
        ) { [weak self] result in
            guard let self = self else { return }
            self.mainQueue.async {
                self.loading.value = false
                
                switch result {
                case .success(let paymentIntent):
                    self.paymentIntentClientSecret = paymentIntent.clientSecret
                    self.paymentIntentId = paymentIntent.paymentIntentId
                    if let customerId = paymentIntent.customerId {
                        // customerId already set
                    }
                    if let ephemeralKey = paymentIntent.ephemeralKey {
                        self.ephemeralKey = ephemeralKey
                    }
                    // Trigger callback to show PaymentSheet
                    self.onShowPaymentSheet?()
                case .failure(let error):
                    self.error.value = error
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
    
    func getOrderTotalAmount() -> Double {
        return order.totalAmount
    }
    
    /// Tạo payment intent với paymentMethodId (cho saved card - đã lưu)
    func createPaymentIntentWithMethod(
        paymentMethodId: String,
        completion: @escaping (Result<PaymentIntent, Error>) -> Void
    ) {
        loading.value = true
        
        // VND không dùng cents - amount trực tiếp (ví dụ: 13348 = 13,348 VND)
        // Backend trả về totalAmount dưới dạng VND trực tiếp (13348.0 = 13,348 VND)
        // KHÔNG nhân 100, KHÔNG chia 100 - dùng trực tiếp
        let totalAmount = order.totalAmount
        let amount = Int(totalAmount)  // VND: amount trực tiếp
        
        
        createPaymentIntentTask = paymentCardUseCase.createPaymentIntent(
            orderId: order.orderId,
            amount: amount,  // VND: amount trực tiếp, không nhân 100
            paymentMethodId: paymentMethodId
        ) { [weak self] result in
            guard let self = self else { return }
            self.mainQueue.async {
                self.loading.value = false
                
                switch result {
                case .success(let paymentIntent):
                    // Lưu thông tin payment intent
                    self.paymentIntentClientSecret = paymentIntent.clientSecret
                    self.paymentIntentId = paymentIntent.paymentIntentId
                    if let ephemeralKey = paymentIntent.ephemeralKey {
                        self.ephemeralKey = ephemeralKey
                    }
                    completion(.success(paymentIntent))
                    
                case .failure(let error):
                    self.error.value = error
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Tạo payment intent KHÔNG có paymentMethodId (cho thẻ mới - chưa attach vào customer)
    func createPaymentIntentWithoutMethod(
        completion: @escaping (Result<PaymentIntent, Error>) -> Void
    ) {
        loading.value = true
        
        // VND không dùng cents - amount trực tiếp
        let totalAmount = order.totalAmount
        let amount = Int(totalAmount)  // VND: amount trực tiếp
        
        
        createPaymentIntentTask = paymentCardUseCase.createPaymentIntent(
            orderId: order.orderId,
            amount: amount,  // VND: amount trực tiếp, không nhân 100
            paymentMethodId: nil  // ⚠️ QUAN TRỌNG: nil cho thẻ mới
        ) { [weak self] result in
            guard let self = self else { return }
            self.mainQueue.async {
                self.loading.value = false
                
                switch result {
                case .success(let paymentIntent):
                    // Lưu thông tin payment intent
                    self.paymentIntentClientSecret = paymentIntent.clientSecret
                    self.paymentIntentId = paymentIntent.paymentIntentId
                    if let ephemeralKey = paymentIntent.ephemeralKey {
                        self.ephemeralKey = ephemeralKey
                    }
                    completion(.success(paymentIntent))
                    
                case .failure(let error):
                    self.error.value = error
                    completion(.failure(error))
                }
            }
        }
    }
}

// MARK: - EcoController Implementation

extension DefaultPaymentMethodController {
    
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
    
    func onViewWillAppear() {
        loadPaymentCards()
    }
    
    func onViewDidDisappear() {}
}
