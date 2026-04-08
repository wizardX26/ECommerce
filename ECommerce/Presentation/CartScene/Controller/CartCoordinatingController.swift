//
//  CartCoordinatingController.swift
//  ECommerce
//
//  Created by wizard.os25 on 17/1/26.
//

import UIKit

protocol CartCoordinatingControllerDependencies {
    func makeCartViewController() -> CartViewController
}

final class CartCoordinatingController {
    
    private weak var navigationController: UINavigationController?
    private let dependencies: CartCoordinatingControllerDependencies
    
    init(
        navigationController: UINavigationController,
        dependencies: CartCoordinatingControllerDependencies
    ) {
        self.navigationController = navigationController
        self.dependencies = dependencies
    }
    
    func start() {
        let vc = dependencies.makeCartViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
}
