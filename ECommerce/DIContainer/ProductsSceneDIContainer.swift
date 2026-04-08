//
//  ProductsSceneDIContainer.swift
//  ExampleMVVM
//
//  Created by wizard.os25 on 14/11/25.
//

import UIKit

final class ProductsSceneDIContainer: ProductCoordinatingControllerDependencies {
    
    struct Dependencies {
        let productsDataTransferService: DataTransferService
    }
    
    private let dependencies: Dependencies
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    // MARK: - Cache Storage
    func makeProductsResponseStorage() -> ProductsResponseStorage {
        CoreDataProductsResponseStorage()
    }
    
    // MARK: - Repositories
    func makeProductsRepository() -> ProductsRepository {
        DefaultProductsRepository(
            dataTransferService: dependencies.productsDataTransferService,
            cacheStorage: makeProductsResponseStorage()
        )
    }
    
    // MARK: - Products List
    func makeProductsViewController() -> ProductsViewController {
        ProductsViewController.create(
            with: makeProductsController()
        )
    }
    
    func makeProductsController() -> ProductsController {
        DefaultProductsController(
            productsRepository: makeProductsRepository()
        )
    }
    
    // MARK: - Flow Coordinators
    func makeProductCoordinatingController(navigationController: UINavigationController) -> ProductCoordinatingController {
        ProductCoordinatingController(
            navigationController: navigationController,
            dependencies: self
        )
    }
}

