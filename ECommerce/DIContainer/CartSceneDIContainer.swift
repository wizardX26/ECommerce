//
//  CartSceneDIContainer.swift
//  ECommerce
//
//  Created by wizard.os25 on 17/1/26.
//

import UIKit

final class CartSceneDIContainer: CartCoordinatingControllerDependencies {
    
    // Shared cart controller instance to maintain cart state across app
    private lazy var sharedCartController: CartController = {
        let controller = DefaultCartController()
        print("🛒 [CartSceneDIContainer] ========================================")
        print("🛒 [CartSceneDIContainer] Creating shared CartController")
        print("   Controller type: \(type(of: controller))")
        print("   Controller instance ID: \(ObjectIdentifier(controller))")
        print("🛒 [CartSceneDIContainer] ========================================")
        return controller
    }()
    
    // MARK: - Cart Scene
    
    func makeCartViewController() -> CartViewController {
        print("🛒 [CartSceneDIContainer] makeCartViewController called")
        print("   Using sharedCartController instance")
        print("   Controller type: \(type(of: sharedCartController))")
        return CartViewController.create(
            with: sharedCartController
        )
    }
    
    func makeCartController() -> CartController {
        print("🛒 [CartSceneDIContainer] makeCartController called")
        print("   Returning sharedCartController instance")
        print("   Controller type: \(type(of: sharedCartController))")
        print("   Current cart items count: \(sharedCartController.cartItems.value.count)")
        return sharedCartController
    }
    
    // MARK: - Flow Coordinators
    
    func makeCartCoordinatingController(navigationController: UINavigationController) -> CartCoordinatingController {
        CartCoordinatingController(
            navigationController: navigationController,
            dependencies: self
        )
    }
}
