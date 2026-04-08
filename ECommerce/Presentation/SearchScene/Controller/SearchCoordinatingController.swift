//
//  SearchCoordinatingController.swift
//  ECommerce
//
//  Created by wizard.os25 on 9/1/26.
//

import UIKit

protocol SearchCoordinatingControllerDependencies {
    func makeSearchViewController() -> SearchViewController
    func makeProductsViewController() -> ProductsViewController
}

final class SearchCoordinatingController {
    
    private weak var navigationController: UINavigationController?
    private let dependencies: SearchCoordinatingControllerDependencies
    
    init(
        navigationController: UINavigationController,
        dependencies: SearchCoordinatingControllerDependencies
    ) {
        self.navigationController = navigationController
        self.dependencies = dependencies
    }
    
    func start() {
        let vc = dependencies.makeSearchViewController()
        setupSearchCallbacks(vc)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func setupSearchCallbacks(_ searchViewController: SearchViewController) {
        guard var searchController = searchViewController.controller as? SearchController else {
            return
        }
        
        searchController.onSearchResult = { [weak self] productPage, query in
            guard let self = self, let navigationController = self.navigationController else {
                return
            }
            
            // Create ProductsViewController
            let productsViewController = self.dependencies.makeProductsViewController()
            
            // Push ProductsViewController
            navigationController.pushViewController(productsViewController, animated: true)
            
            // Load products from search result and set title
            if let productsController = productsViewController.controller as? DefaultProductsController {
                // Set flag để đánh dấu được push từ search
                productsController.setPushedFromOtherScreen(true)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // Cancel any default loading
                    productsController.didCancelSearch()
                    
                    // Load products from search result
                    productsController.loadProductsFromPage(productPage, query: query)
                    
                    // Set navigation bar title to "Result for {query}"
                    var currentState = productsController.navigationState.value
                    currentState.title = "Result for \(query)"
                    productsController.navigationState.value = currentState
                }
            }
        }
    }
}
