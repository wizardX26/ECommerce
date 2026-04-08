//
//  CategorySceneDIContainer.swift
//  ECommerce
//
//  Created by wizard.os25 on 7/1/26.
//

import UIKit

final class CategorySceneDIContainer: CategoryCoordinatingControllerDependencies {
    
    struct Dependencies {
        let productsDataTransferService: DataTransferService
    }
    
    private let dependencies: Dependencies
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    // MARK: - Repositories
    func makeCategoriesRepository() -> CategoriesRepository {
        DefaultCategoriesRepository(
            dataTransferService: dependencies.productsDataTransferService
        )
    }
    
    // MARK: - Use Cases
    func makeCategoryUseCase() -> CategoryUseCase {
        DefaultCategoryUseCase(
            categoriesRepository: makeCategoriesRepository()
        )
    }
    
    // MARK: - Category List
    func makeCategoryViewController() -> CategoryViewController {
        CategoryViewController.create(
            with: makeCategoryController()
        )
    }
    
    func makeCategoryController() -> CategoryController {
        DefaultCategoryController(
            categoryUseCase: makeCategoryUseCase()
        )
    }
    
    // MARK: - Flow Coordinators
    func makeCategoryCoordinatingController(navigationController: UINavigationController) -> CategoryCoordinatingController {
        CategoryCoordinatingController(
            navigationController: navigationController,
            dependencies: self
        )
    }
}
