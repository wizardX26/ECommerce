//
//  PaymentCardCoordinatingController.swift
//  ECommerce
//
//  Created by wizard.os25 on 14/1/26.
//

import UIKit

protocol PaymentCardCoordinatingControllerDependencies {
    func makePaymentCardViewController() -> PaymentCardViewController
}

final class PaymentCardCoordinatingController {
    
    private weak var navigationController: UINavigationController?
    private let dependencies: PaymentCardCoordinatingControllerDependencies
    
    init(
        navigationController: UINavigationController,
        dependencies: PaymentCardCoordinatingControllerDependencies
    ) {
        self.navigationController = navigationController
        self.dependencies = dependencies
    }
    
    func start() {
        let viewController = dependencies.makePaymentCardViewController()
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    func makePaymentCardViewController() -> PaymentCardViewController {
        return dependencies.makePaymentCardViewController()
    }
}
