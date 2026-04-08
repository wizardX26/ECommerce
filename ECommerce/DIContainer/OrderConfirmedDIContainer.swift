//
//  OrderConfirmedDIContainer.swift
//  ECommerce
//
//  Created by wizard.os25 on 16/1/26.
//

import UIKit

final class OrderConfirmedDIContainer {
    
    struct Dependencies {
        let orderManageUseCase: OrderManageUseCase
    }
    
    private let dependencies: Dependencies
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    // MARK: - Controllers
    
    func makeOrderConfirmedController() -> OrderConfirmedController {
        DefaultOrderConfirmedController(
            orderManageUseCase: dependencies.orderManageUseCase
        )
    }
    
    // MARK: - View Controllers
    
    func makeOrderConfirmedViewController() -> OrderConfirmedViewController {
        OrderConfirmedViewController.create(
            with: makeOrderConfirmedController()
        )
    }
}
