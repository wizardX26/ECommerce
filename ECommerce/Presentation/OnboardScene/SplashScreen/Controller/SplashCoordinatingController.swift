//
//  SplashCoordinatingController.swift
//  ECommerce
//
//  Created by wizard.os25 on 9/1/26.
//

import UIKit

protocol SplashCoordinatingControllerDependencies {
    func makeSplashViewController() -> SplashViewController
    func makeAuthSceneDIContainer() -> AuthSceneDIContainer
    func makeMainSceneDIContainer() -> MainSceneDIContainer
}

final class SplashCoordinatingController {
    
    private weak var navigationController: UINavigationController?
    private let dependencies: SplashCoordinatingControllerDependencies
    private var window: UIWindow? // Keep strong reference to prevent deallocation
    
    init(
        navigationController: UINavigationController?,
        window: UIWindow?,
        dependencies: SplashCoordinatingControllerDependencies
    ) {
        self.navigationController = navigationController
        self.window = window
        self.dependencies = dependencies
    }
    
    func start() {
        let viewController = dependencies.makeSplashViewController()
        
        // Set coordinating controller BEFORE setting as root to ensure it's set before viewDidLoad
        viewController.setCoordinatingController(self)
        
        // Set SplashViewController as root
        if let window = window {
            // Make window key and visible first
            window.makeKeyAndVisible()
            window.rootViewController = viewController
        } else if let navigationController = navigationController {
            navigationController.setViewControllers([viewController], animated: false)
        } else {
        }
    }
    
    // MARK: - Navigation
    
    func navigateToMain() {
        let mainSceneDIContainer = dependencies.makeMainSceneDIContainer()
        let mainContainerViewController = mainSceneDIContainer.makeMainContainerViewController()
        
        transitionToRootViewController(mainContainerViewController)
    }
    
    func navigateToLogin() {
        let authSceneDIContainer = dependencies.makeAuthSceneDIContainer()
        let navigationController = UINavigationController()
        let loginCoordinatingController = authSceneDIContainer.makeLoginCoordinatingController(
            navigationController: navigationController
        )
        
        // LoginCoordinatingController is now kept alive via associated object in navigationController
        // Start LoginCoordinatingController which will set coordinatingController and push LoginViewController
        loginCoordinatingController.start()
        
        transitionToRootViewController(navigationController)
    }
    
    // MARK: - Private Helpers
    
    private func transitionToRootViewController(_ viewController: UIViewController) {
        guard let window = window ?? navigationController?.view.window else {
            return
        }
        
        
        UIView.transition(
            with: window,
            duration: 0.4,
            options: .transitionCrossDissolve,
            animations: {
                window.rootViewController = viewController
            },
            completion: { finished in
            }
        )
    }
}
