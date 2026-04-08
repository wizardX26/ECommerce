//
//  OrderContainerController.swift
//  ECommerce
//
//  Created by wizard.os25 on 16/1/26.
//

import Foundation
import UIKit

protocol OrderContainerControllerInput {
    func didLoad()
    func removeOrder(orderId: Int)
}

protocol OrderContainerControllerOutput {
    var orders: Observable<[OrderManage]> { get }
    var loading: Observable<Bool> { get }
    var error: Observable<Error?> { get }
}

typealias OrderContainerController = OrderContainerControllerInput & OrderContainerControllerOutput & EcoController

final class DefaultOrderContainerController: OrderContainerController {
    
    private let orderManageUseCase: OrderManageUseCase
    private let mainQueue: DispatchQueueType
    
    // MARK: - OUTPUT
    
    let orders: Observable<[OrderManage]> = Observable([])
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
    
    // MARK: - Input
    
    func onViewDidLoad() {
        // No navigation bar needed for container
    }
    
    func onViewWillAppear() {}
    func onViewDidDisappear() {}
    
    func didLoad() {
        loadOrders()
    }
    
    func removeOrder(orderId: Int) {
        var currentOrders = orders.value
        currentOrders.removeAll { $0.id == orderId }
        orders.value = currentOrders
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
                    self.orders.value = orders
                case .failure(let err):
                    self.error.value = err
                }
            })
        }
    }
}
