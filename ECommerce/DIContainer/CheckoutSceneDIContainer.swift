//
//  CheckoutSceneDIContainer.swift
//  ECommerce
//
//  Created by wizard.os25 on 15/1/26.
//

import UIKit

final class CheckoutSceneDIContainer: CheckoutCoordinatingControllerDependencies {
    
    struct Dependencies {
        let orderDataTransferService: DataTransferService
        let paymentCardDataTransferService: DataTransferService
        let addressDIContainer: AddressDIContainer
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
    
    // MARK: - Checkout Scene
    
    func makeCheckoutViewController(cartItems: [CartItem], product: ProductDetailModel?) -> CheckoutViewController {
        CheckoutViewController.create(
            with: makeCheckoutController(cartItems: cartItems, product: product)
        )
    }
    
    func makeCheckoutViewController(cartItems: [CartItem], productMap: [Int: ProductDetailModel]) -> CheckoutViewController {
        CheckoutViewController.create(
            with: makeCheckoutController(cartItems: cartItems, product: nil, productMap: productMap)
        )
    }
    
    func makeCheckoutController(cartItems: [CartItem], product: ProductDetailModel?, productMap: [Int: ProductDetailModel]? = nil) -> CheckoutController {
        DefaultCheckoutController(
            orderUseCase: makeOrderUseCase(),
            paymentCardUseCase: makePaymentCardUseCase(),
            cartItems: cartItems,
            product: product,
            productMap: productMap
        )
    }
    
    // MARK: - Payment Method Scene
    
    func makePaymentMethodViewController(
        order: Order,
        clientSecret: String,
        paymentIntentId: String,
        customerId: String?,
        ephemeralKey: String?
    ) -> PaymentMethodViewController {
        PaymentMethodViewController.create(
            with: makePaymentMethodController(
                order: order,
                clientSecret: clientSecret,
                paymentIntentId: paymentIntentId,
                customerId: customerId,
                ephemeralKey: ephemeralKey
            )
        )
    }
    
    func makePaymentMethodController(
        order: Order,
        clientSecret: String,
        paymentIntentId: String,
        customerId: String?,
        ephemeralKey: String?
    ) -> PaymentMethodController {
        DefaultPaymentMethodController(
            paymentCardUseCase: makePaymentCardUseCase(),
            order: order,
            clientSecret: clientSecret,
            paymentIntentId: paymentIntentId,
            customerId: customerId,
            ephemeralKey: ephemeralKey
        )
    }
    
    // MARK: - Flow Coordinators
    
    func makeCheckoutCoordinatingController(navigationController: UINavigationController) -> CheckoutCoordinatingController {
        CheckoutCoordinatingController(
            navigationController: navigationController,
            dependencies: self
        )
    }
}
