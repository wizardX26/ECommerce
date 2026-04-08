//
//  OrderContainerDIContainer.swift
//  ECommerce
//
//  Created by wizard.os25 on 16/1/26.
//

import UIKit

final class OrderContainerDIContainer {
    
    struct Dependencies {
        let orderDataTransferService: DataTransferService
    }
    
    private let dependencies: Dependencies
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    // MARK: - Repositories
    
    func makeOrderManageRepository() -> OrderManageRepository {
        DefaultOrderManageRepository(
            dataTransferService: dependencies.orderDataTransferService
        )
    }
    
    // MARK: - Use Cases
    
    func makeOrderManageUseCase() -> OrderManageUseCase {
        DefaultOrderManageUseCase(
            orderManageRepository: makeOrderManageRepository()
        )
    }
    
    // MARK: - Sub DIContainers
    
    func makeOrderPendingDIContainer() -> OrderPendingDIContainer {
        OrderPendingDIContainer(
            dependencies: OrderPendingDIContainer.Dependencies(
                orderManageUseCase: makeOrderManageUseCase()
            )
        )
    }
    
    func makeOrderProcessingDIContainer() -> OrderProcessingDIContainer {
        OrderProcessingDIContainer(
            dependencies: OrderProcessingDIContainer.Dependencies(
                orderManageUseCase: makeOrderManageUseCase()
            )
        )
    }
    
    func makeOrderConfirmedDIContainer() -> OrderConfirmedDIContainer {
        OrderConfirmedDIContainer(
            dependencies: OrderConfirmedDIContainer.Dependencies(
                orderManageUseCase: makeOrderManageUseCase()
            )
        )
    }
    
    func makeOrderCancelDIContainer() -> OrderCancelDIContainer {
        OrderCancelDIContainer(
            dependencies: OrderCancelDIContainer.Dependencies(
                orderManageUseCase: makeOrderManageUseCase()
            )
        )
    }
    
    func makeOrderDeliveryDIContainer() -> OrderDeliveryDIContainer {
        OrderDeliveryDIContainer(
            dependencies: OrderDeliveryDIContainer.Dependencies(
                orderManageUseCase: makeOrderManageUseCase()
            )
        )
    }
    
    func makeOrderDeliveredDIContainer() -> OrderDeliveredDIContainer {
        OrderDeliveredDIContainer(
            dependencies: OrderDeliveredDIContainer.Dependencies(
                orderManageUseCase: makeOrderManageUseCase()
            )
        )
    }
    
    // MARK: - Controllers
    
    func makeOrderContainerController() -> OrderContainerController {
        DefaultOrderContainerController(
            orderManageUseCase: makeOrderManageUseCase()
        )
    }
    
    // MARK: - View Controllers
    
    func makeOrderContainerViewController() -> OrderContainerViewController {
        let viewController = OrderContainerViewController()
        
        let containerController = makeOrderContainerController()
        let pendingController = makeOrderPendingDIContainer().makeOrderPendingController()
        let processingController = makeOrderProcessingDIContainer().makeOrderProcessingController()
        let confirmedController = makeOrderConfirmedDIContainer().makeOrderConfirmedController()
        let cancelController = makeOrderCancelDIContainer().makeOrderCancelController()
        let deliveryController = makeOrderDeliveryDIContainer().makeOrderDeliveryController()
        let deliveredController = makeOrderDeliveredDIContainer().makeOrderDeliveredController()
        
        viewController.configure(
            with: containerController,
            pendingController: pendingController,
            processingController: processingController,
            confirmedController: confirmedController,
            cancelController: cancelController,
            deliveryController: deliveryController,
            deliveredController: deliveredController
        )
        
        return viewController
    }
}
