//
//  OrderCancelController.swift
//  ECommerce
//
//  Created by wizard.os25 on 16/1/26.
//

import Foundation
import UIKit

protocol OrderCancelControllerInput {
    func didLoad()
    func didSelectItem(at index: Int)
}

protocol OrderCancelControllerOutput {
    var items: Observable<[OrderCancelItemModel]> { get }
    var isEmpty: Bool { get }
    var screenTitle: String { get }
    var emptyDataTitle: String { get }
    var errorTitle: String { get }
    
    var onSelectOrderItem: ((OrderCancelItemModel) -> Void)? { get set }
}

typealias OrderCancelController = OrderCancelControllerInput & OrderCancelControllerOutput & EcoController

final class DefaultOrderCancelController: OrderCancelController {
    
    private let orderManageUseCase: OrderManageUseCase
    private let mainQueue: DispatchQueueType
    
    private var allOrders: [OrderManage] = []
    
    // MARK: - OUTPUT
    
    let items: Observable<[OrderCancelItemModel]> = Observable([])
    var isEmpty: Bool { return items.value.isEmpty }
    var screenTitle: String { "order_cancel".localized() }
    let emptyDataTitle = "No canceled orders"
    var errorTitle: String { "error".localized() }
    
    var onSelectOrderItem: ((OrderCancelItemModel) -> Void)?
    
    // MARK: - EcoController Output
    
    let loading: Observable<Bool> = Observable(false)
    let error: Observable<Error?> = Observable(nil)
    let navigationState: Observable<EcoNavigationState> = Observable(.init())
    
    // MARK: - Init
    
    init(
        orderManageUseCase: OrderManageUseCase,
        mainQueue: DispatchQueueType = DispatchQueue.main
    ) {
        self.orderManageUseCase = orderManageUseCase
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
        return 93 // Reduced by 1/3 from 140 (140 * 2/3 ≈ 93)
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
    
    var navigationBarTitleFont: UIFont? {
        return UIFont.boldSystemFont(ofSize: 19) // Slightly larger title
    }
    
    // MARK: - Input
    
    func onViewDidLoad() {
        updateNavigationState()
    }
    
    func onViewWillAppear() {}
    func onViewDidDisappear() {}
    
    func didLoad() {
        loadOrders()
    }
    
    func didSelectItem(at index: Int) {
        guard index >= 0 && index < items.value.count else { return }
        let item = items.value[index]
        onSelectOrderItem?(item)
    }
    
    // MARK: - Private
    
    private func loadOrders() {
        loading.value = true
        error.value = nil
        
        orderManageUseCase.execute { [weak self] result in
            guard let self = self else { return }
            
            self.mainQueue.async(execute: {
                self.loading.value = false
                
                switch result {
                case .success(let orders):
                    self.allOrders = orders
                    self.filterCancelOrders()
                case .failure(let err):
                    self.error.value = err
                }
            })
        }
    }
    
    private func filterCancelOrders() {
        let cancelOrders = allOrders.filter { $0.orderStatus == "canceled" }
        items.value = cancelOrders.map { OrderCancelItemModel(orderManage: $0) }
    }
    
    func updateOrders(_ orders: [OrderManage]) {
        allOrders = orders
        filterCancelOrders()
    }
    
    private func updateNavigationState() {
        var state = EcoNavigationState()
        state.title = screenTitle
        state.titleFont = navigationBarTitleFont
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
