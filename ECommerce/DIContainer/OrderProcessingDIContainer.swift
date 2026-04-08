//
//  OrderProcessingDIContainer.swift
//  ECommerce
//
//  Created by wizard.os25 on 16/1/26.
//

import UIKit

final class OrderProcessingDIContainer {
    
    struct Dependencies {
        let orderManageUseCase: OrderManageUseCase
    }
    
    private let dependencies: Dependencies
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    // MARK: - Controllers
    
    func makeOrderProcessingController() -> OrderProcessingController {
        DefaultOrderProcessingController(
            orderManageUseCase: dependencies.orderManageUseCase
        )
    }
    
    // MARK: - View Controllers
    
    func makeOrderProcessingViewController() -> OrderProcessingViewController {
        OrderProcessingViewController.create(
            with: makeOrderProcessingController()
        )
    }
}
