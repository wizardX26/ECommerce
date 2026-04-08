//
//  OrderDetailController.swift
//  ECommerce
//
//  Created by wizard.os25 on 16/1/26.
//

import Foundation
import UIKit

protocol OrderDetailControllerInput {
    func didLoad()
    func didCancelOrder()
}

protocol OrderDetailControllerOutput {
    var orderDetail: Observable<OrderDetail?> { get }
    var isEmpty: Bool { get }
    var screenTitle: String { get }
    var errorTitle: String { get }
    var cancelOrderMessage: Observable<String?> { get }
    var cancelOrderSuccess: Observable<Bool> { get }
}

typealias OrderDetailController = OrderDetailControllerInput & OrderDetailControllerOutput & EcoController

final class DefaultOrderDetailController: OrderDetailController {
    
    private let orderDetailUseCase: OrderDetailUseCase
    private let mainQueue: DispatchQueueType
    private let orderId: Int
    
    // MARK: - OUTPUT
    
    let orderDetail: Observable<OrderDetail?> = Observable(nil)
    var isEmpty: Bool { return orderDetail.value == nil }
    var screenTitle: String { "order_detail".localized() }
    var errorTitle: String { "error".localized() }
    let cancelOrderMessage: Observable<String?> = Observable(nil)
    let cancelOrderSuccess: Observable<Bool> = Observable(false)
    
    // MARK: - EcoController Output
    
    let loading: Observable<Bool> = Observable(false)
    let error: Observable<Error?> = Observable(nil)
    let navigationState: Observable<EcoNavigationState> = Observable(.init())
    
    // MARK: - Init
    
    init(
        orderId: Int,
        orderDetailUseCase: OrderDetailUseCase,
        mainQueue: DispatchQueueType = DispatchQueue.main
    ) {
        self.orderId = orderId
        self.orderDetailUseCase = orderDetailUseCase
        self.mainQueue = mainQueue
    }
    
    // MARK: - Navigation Bar Configuration
    
    var navigationBarTitle: String? {
        return screenTitle
    }
    
    var navigationBarShowsSearch: Bool {
        return false
    }
    
    var navigationBarBackground: EcoNavigationBackground {
        return .solid(.white)
    }
    
    var navigationBarBackgroundColor: UIColor? {
        return .white
    }
    
    var navigationBarTitleColor: UIColor? {
        return .black
    }
    
    var navigationBarInitialHeight: CGFloat {
        return 140
    }
    
    var navigationBarButtonTintColor: UIColor? {
        return .black
    }
    
    var navigationBarLeftItem: EcoNavItem? {
        return EcoNavItem.back { [weak self] in
            self?.onBack?()
        }
    }
    
    // MARK: - Callbacks
    
    var onBack: (() -> Void)?
    var onCancelOrderSuccess: ((Int) -> Void)? // orderId callback để remove từ container
    
    // MARK: - Input
    
    func onViewDidLoad() {
        updateNavigationState()
    }
    
    func onViewWillAppear() {}
    func onViewDidDisappear() {}
    
    func didLoad() {
        loadOrderDetail()
    }
    
    func didCancelOrder() {
        loading.value = true
        error.value = nil
        cancelOrderMessage.value = nil
        cancelOrderSuccess.value = false
        
        orderDetailUseCase.cancelOrder(orderId: orderId) { [weak self] result in
            guard let self = self else { return }
            
            self.mainQueue.async(execute: {
                self.loading.value = false
                
                switch result {
                case .success(let message):
                    // Set success flag trước, sau đó mới set message để observer có thể check đúng
                    self.cancelOrderSuccess.value = true
                    self.cancelOrderMessage.value = message
                    // Notify parent to remove order from list
                    self.onCancelOrderSuccess?(self.orderId)
                case .failure(let err):
                    // Set success flag trước, sau đó mới set message
                    self.cancelOrderSuccess.value = false
                    self.error.value = err
                    self.cancelOrderMessage.value = err.localizedDescription
                }
            })
        }
    }
    
    // MARK: - Private
    
    private func loadOrderDetail() {
        loading.value = true
        error.value = nil
        
        orderDetailUseCase.execute(orderId: orderId) { [weak self] result in
            guard let self = self else { return }
            
            self.mainQueue.async(execute: {
                self.loading.value = false
                
                switch result {
                case .success(let detail):
                    self.orderDetail.value = detail
                case .failure(let err):
                    self.error.value = err
                }
            })
        }
    }
    
    private func updateNavigationState() {
        var state = EcoNavigationState()
        state.title = screenTitle
        state.background = navigationBarBackground
        state.backgroundColor = navigationBarBackgroundColor
        state.titleColor = navigationBarTitleColor
        state.height = navigationBarInitialHeight
        state.buttonTintColor = navigationBarButtonTintColor
        state.leftItem = navigationBarLeftItem
        state.backButtonStyle = .simple
        navigationState.value = state
    }
}
