//
//  AddressDIContainer.swift
//  ECommerce
//
//  Created by wizard.os25 on 11/1/26.
//

import UIKit

final class AddressDIContainer: AddressCoordinatingControllerDependencies {
    
    struct Dependencies {
        let apiDataTransferService: DataTransferService
    }
    
    private let dependencies: Dependencies
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    // MARK: - Repositories
    
    func makeAddressRepository() -> AddressRepository {
        DefaultAddressRepository(
            dataTransferService: dependencies.apiDataTransferService
        )
    }
    
    // MARK: - Use Cases
    
    func makeCreateAddressUseCase() -> CreateAddressUseCase {
        DefaultCreateAddressUseCase(
            addressRepository: makeAddressRepository()
        )
    }
    
    func makeUpdateAddressUseCase() -> UpdateAddressUseCase {
        DefaultUpdateAddressUseCase(
            addressRepository: makeAddressRepository()
        )
    }
    
    func makeDeleteAddressUseCase() -> DeleteAddressUseCase {
        DefaultDeleteAddressUseCase(
            addressRepository: makeAddressRepository()
        )
    }
    
    // MARK: - Address Scene
    
    func makeAddressViewController() -> AddressViewController {
        AddressViewController.create(
            with: makeAddressController()
        )
    }
    
    func makeAddressController() -> AddressController {
        DefaultAddressController(
            createAddressUseCase: makeCreateAddressUseCase(),
            updateAddressUseCase: makeUpdateAddressUseCase(),
            deleteAddressUseCase: makeDeleteAddressUseCase()
        )
    }
    
    
    // MARK: - Flow Coordinators
    
    func makeAddressCoordinatingController(navigationController: UINavigationController) -> AddressCoordinatingController {
        AddressCoordinatingController(
            navigationController: navigationController,
            dependencies: self
        )
    }
}
