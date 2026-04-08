//
//  PaymentCardController.swift
//  ECommerce
//
//  Created by wizard.os25 on 14/1/26.
//

import Foundation
import UIKit

protocol PaymentCardControllerInput {
    func didLoadView()
    func didTapAddNewCard()
    func didTapSaveCard()
    func didTapDeleteCard(at index: Int)
    func didTapSetDefaultCard(at index: Int)
}

protocol PaymentCardControllerOutput {
    var paymentCards: Observable<[PaymentCard]> { get }
    var isAddingNewCard: Observable<Bool> { get }
    var isCardInputEnabled: Observable<Bool> { get }
    var screenTitle: Observable<String> { get }
    var successMessage: Observable<String?> { get }
}

typealias PaymentCardController = PaymentCardControllerInput & PaymentCardControllerOutput & EcoController

final class DefaultPaymentCardController: PaymentCardController {
    
    private let paymentCardUseCase: PaymentCardUseCase
    private let mainQueue: DispatchQueueType
    
    private var model = PaymentCardModel()
    private var paymentCardsLoadTask: Cancellable? { willSet { paymentCardsLoadTask?.cancel() } }
    private var createCustomerTask: Cancellable? { willSet { createCustomerTask?.cancel() } }
    private var attachCardTask: Cancellable? { willSet { attachCardTask?.cancel() } }
    private var deleteCardTask: Cancellable? { willSet { deleteCardTask?.cancel() } }
    
    // MARK: - OUTPUT (PaymentCard-specific)
    
    let paymentCards: Observable<[PaymentCard]> = Observable([])
    let isAddingNewCard: Observable<Bool> = Observable(false)
    let isCardInputEnabled: Observable<Bool> = Observable(false)
    let screenTitle: Observable<String> = Observable("payment_card".localized())
    let successMessage: Observable<String?> = Observable(nil)
    
    // MARK: - EcoController Output (common to all controllers)
    
    let loading: Observable<Bool> = Observable(false)
    let error: Observable<Error?> = Observable(nil)
    let navigationState: Observable<EcoNavigationState> = Observable(.init())
    
    // MARK: - Navigation Bar Configuration
    
    var navigationBarTitle: String? {
        return "Payment Card"
    }
    
    var navigationBarLeftItem: EcoNavItem? {
        return EcoNavItem.back { [weak self] in
            self?.onNavigationBarLeftItemTap?()
        }
    }
    
    var navigationBarInitialHeight: CGFloat {
        return 140
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
        paymentCardUseCase: PaymentCardUseCase,
        mainQueue: DispatchQueueType = DispatchQueue.main
    ) {
        self.paymentCardUseCase = paymentCardUseCase
        self.mainQueue = mainQueue
    }
    
    // MARK: - Setup
    
    // MARK: - PaymentCardControllerInput
    
    func didLoadView() {
        loadPaymentCards()
        ensureCustomerExists()
    }
    
    func didTapAddNewCard() {
        model.isAddingNewCard = true
        model.isCardInputEnabled = true
        isAddingNewCard.value = true
        isCardInputEnabled.value = true
        screenTitle.value = "save".localized()
    }
    
    func didTapSaveCard() {
        // This will be called from view controller after creating payment method with Stripe SDK
        // The actual save happens in didSavePaymentMethod
    }
    
    func didSavePaymentMethod(paymentMethodId: String) {
        loading.value = true
        error.value = nil
        
        attachCardTask = paymentCardUseCase.attachPaymentMethod(paymentMethodId: paymentMethodId) { [weak self] result in
            guard let self = self else { return }
            self.mainQueue.async {
                self.loading.value = false
                
                switch result {
                case .success((_, let backendMessage)):
                    // Reload payment cards
                    self.loadPaymentCards()
                    // Reset UI state
                    self.model.isAddingNewCard = false
                    self.model.isCardInputEnabled = false
                    self.isAddingNewCard.value = false
                    self.isCardInputEnabled.value = false
                    self.screenTitle.value = "payment_card".localized()
                    // Show success message
                    self.successMessage.value = backendMessage
                case .failure(let error):
                    let parsed = APIErrorParser.parseErrorMessage(from: error)
                    self.error.value = NSError(domain: "PaymentCardError", code: 0, userInfo: [NSLocalizedDescriptionKey: parsed])
                }
            }
        }
    }
    
    func didTapDeleteCard(at index: Int) {
        guard index < model.paymentCards.count else { return }
        let paymentCard = model.paymentCards[index]
        
        loading.value = true
        error.value = nil
        
        deleteCardTask = paymentCardUseCase.deletePaymentMethod(id: paymentCard.id) { [weak self] result in
            guard let self = self else { return }
            self.mainQueue.async {
                self.loading.value = false
                
                switch result {
                case .success(let backendMessage):
                    // Reload payment cards
                    self.loadPaymentCards()
                    self.successMessage.value = backendMessage
                case .failure(let error):
                    let parsed = APIErrorParser.parseErrorMessage(from: error)
                    self.error.value = NSError(domain: "PaymentCardError", code: 0, userInfo: [NSLocalizedDescriptionKey: parsed])
                }
            }
        }
    }
    
    func didTapSetDefaultCard(at index: Int) {
        guard index < model.paymentCards.count else { return }
        let paymentCard = model.paymentCards[index]
        
        loading.value = true
        error.value = nil
        
        let task = paymentCardUseCase.setDefaultPaymentMethod(paymentMethodId: paymentCard.id) { [weak self] result in
            guard let self = self else { return }
            self.mainQueue.async {
                self.loading.value = false
                
                switch result {
                case .success:
                    // Reload payment cards
                    self.loadPaymentCards()
                case .failure(let error):
                    self.error.value = error
                }
            }
        }
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
        // Refresh payment cards when view appears
        loadPaymentCards()
    }
    
    func onViewDidDisappear() {
        // Cancel any ongoing tasks if needed
    }
    
    // MARK: - Private Helpers
    
    private func ensureCustomerExists() {
        // Create customer if doesn't exist (backend handles this)
        createCustomerTask = paymentCardUseCase.createCustomer { [weak self] result in
            // Customer creation is handled by backend, we just ensure it exists
            if case .failure(let error) = result {
            }
        }
    }
    
    private func loadPaymentCards() {
        loading.value = true
        error.value = nil
        
        paymentCardsLoadTask = paymentCardUseCase.getPaymentMethods { [weak self] result in
            guard let self = self else { return }
            self.mainQueue.async {
                self.loading.value = false
                
                switch result {
                case .success(let cards):
                    self.model.paymentCards = cards
                    self.paymentCards.value = cards
                case .failure(let error):
                    self.error.value = error
                    // Set empty array on error
                    self.model.paymentCards = []
                    self.paymentCards.value = []
                }
            }
        }
    }
}