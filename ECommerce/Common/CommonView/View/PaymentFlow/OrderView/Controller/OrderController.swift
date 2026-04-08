//
//  OrderController.swift
//  ECommerce
//
//  Created by wizard.os25 on 14/1/26.
//

import Foundation
import UIKit

protocol OrderControllerInput {
    func didLoadView()
    func didTapPlaceOrder(
        address: String,
        longitude: String,
        latitude: String,
        contactPersonName: String,
        contactPersonNumber: String,
        orderNote: String?
    )
    func didTapAddNewCard()
    func didSelectPaymentCard(_ card: PaymentCard?)
    func updateCartItems(_ cartItems: [CartItem])
}

protocol OrderControllerOutput {
    var cartItems: Observable<[CartItem]> { get }
    var product: Observable<ProductDetailModel?> { get }
    var defaultAddress: Observable<Address?> { get }
    var paymentCards: Observable<[PaymentCard]> { get }
    var selectedPaymentCard: Observable<PaymentCard?> { get }
    var isOrderPlaced: Observable<Bool> { get }
    var orderResult: Observable<Order?> { get }
    var screenTitle: String { get }
}

typealias OrderController = OrderControllerInput & OrderControllerOutput & EcoController

final class DefaultOrderController: OrderController {
    
    private let orderUseCase: OrderUseCase
    private let paymentCardUseCase: PaymentCardUseCase
    private let mainQueue: DispatchQueueType
    
    private var model = OrderModel()
    private var placeOrderTask: Cancellable? { willSet { placeOrderTask?.cancel() } }
    private var paymentCardsLoadTask: Cancellable? { willSet { paymentCardsLoadTask?.cancel() } }
    
    // MARK: - OUTPUT (Order-specific)
    
    let cartItems: Observable<[CartItem]> = Observable([])
    let product: Observable<ProductDetailModel?> = Observable(nil)
    let defaultAddress: Observable<Address?> = Observable(nil)
    let paymentCards: Observable<[PaymentCard]> = Observable([])
    let selectedPaymentCard: Observable<PaymentCard?> = Observable(nil)
    let isOrderPlaced: Observable<Bool> = Observable(false)
    let orderResult: Observable<Order?> = Observable(nil)
    var screenTitle: String { "place_order".localized() }
    
    // MARK: - EcoController Output (common to all controllers)
    
    let loading: Observable<Bool> = Observable(false)
    let error: Observable<Error?> = Observable(nil)
    let navigationState: Observable<EcoNavigationState> = Observable(.init())
    
    // MARK: - Navigation Bar Configuration
    
    var navigationBarTitle: String? {
        return self.screenTitle
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
        mainQueue: DispatchQueueType = DispatchQueue.main
    ) {
        self.orderUseCase = orderUseCase
        self.paymentCardUseCase = paymentCardUseCase
        self.mainQueue = mainQueue
        self.model.cartItems = cartItems
        self.cartItems.value = cartItems
        self.product.value = product
    }
    
    // MARK: - OrderControllerInput
    
    func didLoadView() {
        loadPaymentCards()
    }
    
    func didTapPlaceOrder(
        address: String,
        longitude: String,
        latitude: String,
        contactPersonName: String,
        contactPersonNumber: String,
        orderNote: String?
    ) {
        guard !address.isEmpty,
              !contactPersonName.isEmpty,
              !contactPersonNumber.isEmpty else {
            let error = NSError(
                domain: "OrderError",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Please fill in all required fields"]
            )
            self.error.value = error
            return
        }
        
        guard !model.cartItems.isEmpty else {
            let error = NSError(
                domain: "OrderError",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Cart is empty"]
            )
            self.error.value = error
            return
        }
        
        loading.value = true
        error.value = nil
        
        // Determine if we should use delivery_address_id or address_detail
        // For now, we'll use address_detail with empty location details since we don't have saved address
        // TODO: Get address details from user's saved addresses if available
        placeOrderTask = orderUseCase.placeOrder(
            cart: model.cartItems,
            orderNote: orderNote,
            deliveryAddressId: nil,
            addressDetail: address,
            countryId: nil,
            provinceId: nil,
            districtId: nil,
            wardId: nil,
            contactPersonName: contactPersonName,
            contactPersonNumber: contactPersonNumber
        ) { [weak self] result in
            guard let self = self else { return }
            self.mainQueue.async {
                self.loading.value = false
                
                switch result {
                case .success(let order):
                    self.orderResult.value = order
                    self.isOrderPlaced.value = true
                case .failure(let error):
                    let parsed = APIErrorParser.parseErrorMessage(from: error)
                    self.error.value = NSError(
                        domain: "OrderError",
                        code: 0,
                        userInfo: [NSLocalizedDescriptionKey: parsed]
                    )
                }
            }
        }
    }
    
    func didTapAddNewCard() {
        // This will be handled in ViewController to show PaymentSheet
    }
    
    func didSelectPaymentCard(_ card: PaymentCard?) {
        model.selectedPaymentCard = card
        selectedPaymentCard.value = card
    }
    
    func updateCartItems(_ cartItems: [CartItem]) {
        model.cartItems = cartItems
        self.cartItems.value = cartItems
    }
    
    // MARK: - EcoController
    
    func onViewDidLoad() {
        self.didLoadView()
        self.navigationState.value = EcoNavigationState(
            title: navigationBarTitle,
            titleFont: navigationBarTitleFont,
            titleColor: navigationBarTitleColor,
            showsSearch: false,
            searchState: nil,
            leftItem: navigationBarLeftItem,
            rightItems: [],
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
        // No-op
    }
    
    func onViewDidDisappear() {
        // No-op
    }
    
    // MARK: - Private
    
    private func loadPaymentCards() {
        paymentCardsLoadTask = paymentCardUseCase.getPaymentMethods { [weak self] result in
            guard let self = self else { return }
            self.mainQueue.async {
                switch result {
                case .success(let cards):
                    self.model.paymentCards = cards
                    self.paymentCards.value = cards
                    
                    // Set default card if available
                    if let defaultCard = cards.first(where: { $0.isDefault }) {
                        self.model.defaultPaymentCard = defaultCard
                        self.model.selectedPaymentCard = defaultCard
                        self.selectedPaymentCard.value = defaultCard
                    }
                case .failure:
                    // Ignore error for payment cards loading
                    self.model.paymentCards = []
                    self.paymentCards.value = []
                }
            }
        }
    }
}