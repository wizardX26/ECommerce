//
//  AddressCoordinatingController.swift
//  ECommerce
//
//  Created by wizard.os25 on 12/1/26.
//

import UIKit

protocol AddressCoordinatingControllerDependencies {
    func makeAddressViewController() -> AddressViewController
}

final class AddressCoordinatingController {
    
    private weak var navigationController: UINavigationController?
    private let dependencies: AddressCoordinatingControllerDependencies
    
    init(
        navigationController: UINavigationController,
        dependencies: AddressCoordinatingControllerDependencies
    ) {
        self.navigationController = navigationController
        self.dependencies = dependencies
    }
    
    func start() {
        let viewController = dependencies.makeAddressViewController()
        navigationController?.pushViewController(viewController, animated: true)
    }
}
