//
//  CategoryCoordinatingController.swift
//  ECommerce
//
//  Created by wizard.os25 on 7/1/26.
//

import UIKit

protocol CategoryCoordinatingControllerDependencies {
    func makeCategoryViewController() -> CategoryViewController
}

final class CategoryCoordinatingController {
    
    private weak var navigationController: UINavigationController?
    private let dependencies: CategoryCoordinatingControllerDependencies
    
    init(navigationController: UINavigationController,
         dependencies: CategoryCoordinatingControllerDependencies) {
        self.navigationController = navigationController
        self.dependencies = dependencies
    }
    
    func start() {
        let vc = dependencies.makeCategoryViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
