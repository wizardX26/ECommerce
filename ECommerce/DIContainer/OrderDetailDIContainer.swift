//
//  OrderDetailDIContainer.swift
//  ECommerce
//
//  Created by wizard.os25 on 16/1/26.
//

import UIKit

final class OrderDetailDIContainer {
    
    struct Dependencies {
        let orderDetailUseCase: OrderDetailUseCase
    }
    
    private let dependencies: Dependencies
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    // MARK: - Controllers
    
    func makeOrderDetailController(orderId: Int) -> OrderDetailController {
        DefaultOrderDetailController(
            orderId: orderId,
            orderDetailUseCase: dependencies.orderDetailUseCase
        )
    }
    
    // MARK: - View Controllers
    
    func makeOrderDetailViewController(orderId: Int) -> OrderDetailViewController {
        OrderDetailViewController.create(
            with: makeOrderDetailController(orderId: orderId)
        )
    }
}
