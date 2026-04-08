//
//  LocationListDIContainer.swift
//  ECommerce
//
//  Created by wizard.os25 on 13/1/26.
//

import UIKit

final class LocationListDIContainer {
    
    struct Dependencies {
        let apiDataTransferService: DataTransferService
    }
    
    private let dependencies: Dependencies
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    // MARK: - Repositories
    
    func makeLocationListRepository() -> LocationListRepository {
        DefaultLocationListRepository(
            dataTransferService: dependencies.apiDataTransferService
        )
    }
    
    // MARK: - Use Cases
    
    func makeGetAddressesUseCase() -> GetAddressesUseCase {
        DefaultGetAddressesUseCase(
            locationListRepository: makeLocationListRepository()
        )
    }
    
    // MARK: - LocationList Scene
    
    func makeLocationListViewController() -> LocationListViewController {
        LocationListViewController.create(
            with: makeLocationListController()
        )
    }
    
    func makeLocationListController() -> LocationListController {
        DefaultLocationListController(
            getAddressesUseCase: makeGetAddressesUseCase()
        )
    }
}
