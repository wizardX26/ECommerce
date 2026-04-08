//
//  CheckoutCoordinatingController.swift
//  ECommerce
//
//  Created by wizard.os25 on 15/1/26.
//

import UIKit

protocol CheckoutCoordinatingControllerDependencies {
    func makeCheckoutViewController(cartItems: [CartItem], product: ProductDetailModel?) -> CheckoutViewController
}

final class CheckoutCoordinatingController {
    
    private weak var navigationController: UINavigationController?
    private let dependencies: CheckoutCoordinatingControllerDependencies
    
    init(
        navigationController: UINavigationController,
        dependencies: CheckoutCoordinatingControllerDependencies
    ) {
        self.navigationController = navigationController
        self.dependencies = dependencies
    }
    
    func start(cartItems: [CartItem], product: ProductDetailModel?) {
        let vc = dependencies.makeCheckoutViewController(cartItems: cartItems, product: product)
        navigationController?.pushViewController(vc, animated: true)
    }
}
