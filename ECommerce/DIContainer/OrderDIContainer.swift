//
//  OrderDIContainer.swift
//  ECommerce
//
//  Created by wizard.os25 on 14/1/26.
//

import UIKit

final class OrderDIContainer {
    
    struct Dependencies {
        let orderDataTransferService: DataTransferService
        let paymentCardDataTransferService: DataTransferService
    }
    
    private let dependencies: Dependencies
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    // MARK: - Repositories
    
    func makeOrderRepository() -> OrderRepository {
        DefaultOrderRepository(
            dataTransferService: dependencies.orderDataTransferService
        )
    }
    
    func makePaymentCardRepository() -> PaymentCardRepository {
        DefaultPaymentCardRepository(
            dataTransferService: dependencies.paymentCardDataTransferService
        )
    }
    
    // MARK: - Use Cases
    
    func makeOrderUseCase() -> OrderUseCase {
        DefaultOrderUseCase(
            orderRepository: makeOrderRepository()
        )
    }
    
    func makePaymentCardUseCase() -> PaymentCardUseCase {
        DefaultPaymentCardUseCase(
            paymentCardRepository: makePaymentCardRepository()
        )
    }
    
    // MARK: - Order Scene
    
    func makeOrderViewController(cartItems: [CartItem], product: ProductDetailModel?, isAddToCardMode: Bool = false) -> OrderViewController {
        let orderVC = OrderViewController.create(
            with: makeOrderController(cartItems: cartItems, product: product)
        )
        orderVC.isAddToCardMode = isAddToCardMode
        return orderVC
    }
    
    func makeOrderController(cartItems: [CartItem], product: ProductDetailModel?) -> OrderController {
        DefaultOrderController(
            orderUseCase: makeOrderUseCase(),
            paymentCardUseCase: makePaymentCardUseCase(),
            cartItems: cartItems,
            product: product
        )
    }
}
