//
//  ProductCoordinatingController.swift
//  ExampleMVVM
//
//  Created by wizard.os25 on 14/11/25.
//

import UIKit

protocol ProductCoordinatingControllerDependencies {
    func makeProductsViewController() -> ProductsViewController
}

final class ProductCoordinatingController {
    
    private weak var navigationController: UINavigationController?
    private let dependencies: ProductCoordinatingControllerDependencies
    
    init(navigationController: UINavigationController,
         dependencies: ProductCoordinatingControllerDependencies) {
        self.navigationController = navigationController
        self.dependencies = dependencies
    }
    
    func start() {
        let vc = dependencies.makeProductsViewController()
        //DispatchQueue.main.async {
            self.navigationController?.pushViewController(vc, animated: true)
        //}
    }
}
