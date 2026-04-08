//
//  OrderDeliveredDIContainer.swift
//  ECommerce
//
//  Created by wizard.os25 on 16/1/26.
//

import UIKit

final class OrderDeliveredDIContainer {
    
    struct Dependencies {
        let orderManageUseCase: OrderManageUseCase
    }
    
    private let dependencies: Dependencies
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    // MARK: - Controllers
    
    func makeOrderDeliveredController() -> OrderDeliveredController {
        DefaultOrderDeliveredController(
            orderManageUseCase: dependencies.orderManageUseCase
        )
    }
    
    // MARK: - View Controllers
    
    func makeOrderDeliveredViewController() -> OrderDeliveredViewController {
        OrderDeliveredViewController.create(
            with: makeOrderDeliveredController()
        )
    }
}
