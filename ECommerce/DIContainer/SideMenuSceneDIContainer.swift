//
//  SideMenuSceneDIContainer.swift
//  ECommerce
//
//  Created by wizard.os25 on 17/11/25.
//

import UIKit

final class SideMenuSceneDIContainer: SideMenuCoordinatingControllerDependencies {
    
    struct Dependencies {
        let addressDIContainer: AddressDIContainer
        let paymentCardDIContainer: PaymentCardDIContainer
    }
    
    private let dependencies: Dependencies
    
    // Shared instance to ensure same controller is used
    private lazy var sharedController: SideMenuController = {
        DefaultSideMenuController()
    }()
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    // MARK: - Side Menu
    
    func makeSideMenuViewController() -> SideMenuViewController {
        SideMenuViewController.create(
            with: makeSideMenuController()
        )
    }
    
    func makeSideMenuController() -> SideMenuController {
        // Return shared instance so coordinating controller can observe it
        return sharedController
    }
    
    // MARK: - Address Scene
    
    func makeAddressViewController() -> AddressViewController {
        dependencies.addressDIContainer.makeAddressViewController()
    }
    
    func makeAddressController() -> AddressController {
        dependencies.addressDIContainer.makeAddressController()
    }
    
    // MARK: - Payment Card Scene
    
    func makePaymentCardViewController() -> PaymentCardViewController {
        dependencies.paymentCardDIContainer.makePaymentCardViewController()
    }
    
    func makePaymentCardController() -> PaymentCardController {
        dependencies.paymentCardDIContainer.makePaymentCardController()
    }
    
    // MARK: - Flow Coordinators
    
    func makeSideMenuCoordinatingController() -> SideMenuCoordinatingController {
        SideMenuCoordinatingController(
            dependencies: self
        )
    }
}

