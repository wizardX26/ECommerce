//
//  OrderDeliveryDIContainer.swift
//  ECommerce
//
//  Created by wizard.os25 on 16/1/26.
//

import UIKit

final class OrderDeliveryDIContainer {
    
    struct Dependencies {
        let orderManageUseCase: OrderManageUseCase
    }
    
    private let dependencies: Dependencies
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    // MARK: - Controllers
    
    func makeOrderDeliveryController() -> OrderDeliveryController {
        DefaultOrderDeliveryController(
            orderManageUseCase: dependencies.orderManageUseCase
        )
    }
    
    // MARK: - View Controllers
    
    func makeOrderDeliveryViewController() -> OrderDeliveryViewController {
        OrderDeliveryViewController.create(
            with: makeOrderDeliveryController()
        )
    }
}
