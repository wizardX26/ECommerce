//
//  OrderCancelDIContainer.swift
//  ECommerce
//
//  Created by wizard.os25 on 16/1/26.
//

import UIKit

final class OrderCancelDIContainer {
    
    struct Dependencies {
        let orderManageUseCase: OrderManageUseCase
    }
    
    private let dependencies: Dependencies
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    // MARK: - Controllers
    
    func makeOrderCancelController() -> OrderCancelController {
        DefaultOrderCancelController(
            orderManageUseCase: dependencies.orderManageUseCase
        )
    }
    
    // MARK: - View Controllers
    
    func makeOrderCancelViewController() -> OrderCancelViewController {
        OrderCancelViewController.create(
            with: makeOrderCancelController()
        )
    }
}
