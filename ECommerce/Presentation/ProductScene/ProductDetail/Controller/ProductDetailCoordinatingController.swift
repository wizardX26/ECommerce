//
//  ProductDetailCoordinatingController.swift
//  ECommerce
//
//  Created by wizard.os25 on 14/1/26.
//

import UIKit

final class ProductDetailCoordinatingController {
    
    private weak var navigationController: UINavigationController?
    private let dependencies: ProductDetailCoordinatingControllerDependencies
    
    init(
        navigationController: UINavigationController,
        dependencies: ProductDetailCoordinatingControllerDependencies
    ) {
        self.navigationController = navigationController
        self.dependencies = dependencies
    }
    
    func start(productItem: ProductItemModel) {
        
        let viewController = dependencies.makeProductDetailViewController(productItem: productItem)
        
        guard let navController = navigationController else {
            return
        }
        
        navController.pushViewController(viewController, animated: true)
    }
}
