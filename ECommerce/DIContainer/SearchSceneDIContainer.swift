//
//  SearchSceneDIContainer.swift
//  ECommerce
//
//  Created by wizard.os25 on 9/1/26.
//

import UIKit

final class SearchSceneDIContainer: SearchCoordinatingControllerDependencies {
    
    struct Dependencies {
        let apiDataTransferService: DataTransferService
    }
    
    private let dependencies: Dependencies
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    // MARK: - Repositories
    
    func makeProductsRepository() -> ProductsRepository {
        DefaultProductsRepository(
            dataTransferService: dependencies.apiDataTransferService,
            cacheStorage: nil // Search doesn't use cache
        )
    }
    
    func makeProductsQueriesRepository() -> ProductsQueriesRepository {
        DefaultProductsQueriesRepository()
    }
    
    // MARK: - Use Cases
    
    func makeSearchProductsUseCase() -> SearchProductsUseCase {
        DefaultSearchProductsUseCase(
            productsRepository: makeProductsRepository()
        )
    }
    
    // MARK: - Search Scene
    
    func makeSearchViewController() -> SearchViewController {
        SearchViewController.create(
            with: makeSearchController()
        )
    }
    
    func makeSearchController() -> SearchController {
        DefaultSearchController(
            searchProductsUseCase: makeSearchProductsUseCase(),
            productsQueriesRepository: makeProductsQueriesRepository()
        )
    }
    
    // MARK: - Products Scene (for navigation)
    
    func makeProductsViewController() -> ProductsViewController {
        let productsSceneDIContainer = makeProductsSceneDIContainer()
        return productsSceneDIContainer.makeProductsViewController()
    }
    
    private func makeProductsSceneDIContainer() -> ProductsSceneDIContainer {
        ProductsSceneDIContainer(
            dependencies: ProductsSceneDIContainer.Dependencies(
                productsDataTransferService: dependencies.apiDataTransferService
            )
        )
    }
    
    // MARK: - Flow Coordinators
    
    func makeSearchCoordinatingController(navigationController: UINavigationController) -> SearchCoordinatingController {
        SearchCoordinatingController(
            navigationController: navigationController,
            dependencies: self
        )
    }
}
