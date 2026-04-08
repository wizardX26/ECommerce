//
//  PaymentCardDIContainer.swift
//  ECommerce
//
//  Created by wizard.os25 on 14/1/26.
//

import UIKit

final class PaymentCardDIContainer: PaymentCardCoordinatingControllerDependencies {
    
    struct Dependencies {
        let paymentCardDataTransferService: DataTransferService
    }
    
    private let dependencies: Dependencies
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    // MARK: - Repositories
    
    func makePaymentCardRepository() -> PaymentCardRepository {
        DefaultPaymentCardRepository(
            dataTransferService: dependencies.paymentCardDataTransferService
        )
    }
    
    // MARK: - Use Cases
    
    func makePaymentCardUseCase() -> PaymentCardUseCase {
        DefaultPaymentCardUseCase(
            paymentCardRepository: makePaymentCardRepository()
        )
    }
    
    // MARK: - Payment Card Scene
    
    func makePaymentCardViewController() -> PaymentCardViewController {
        PaymentCardViewController.create(
            with: makePaymentCardController()
        )
    }
    
    func makePaymentCardController() -> PaymentCardController {
        DefaultPaymentCardController(
            paymentCardUseCase: makePaymentCardUseCase()
        )
    }
    
    // MARK: - Flow Coordinators
    
    func makePaymentCardCoordinatingController(
        navigationController: UINavigationController
    ) -> PaymentCardCoordinatingController {
        PaymentCardCoordinatingController(
            navigationController: navigationController,
            dependencies: self
        )
    }
}

