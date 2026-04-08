//
//  OnboardSceneDIContainer.swift
//  ECommerce
//
//  Created by wizard.os25 on 9/1/26.
//

import UIKit

final class OnboardSceneDIContainer: SplashCoordinatingControllerDependencies {
    
    struct Dependencies {
        let authSceneDIContainer: AuthSceneDIContainer
        let mainSceneDIContainer: MainSceneDIContainer
    }
    
    private let dependencies: Dependencies
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    // MARK: - Splash
    
    func makeSplashViewController() -> SplashViewController {
        SplashViewController.create(
            with: makeSplashController()
        )
    }
    
    func makeSplashController() -> SplashController {
        DefaultSplashController()
    }
    
    // MARK: - Flow Coordinators
    
    func makeSplashCoordinatingController(
        navigationController: UINavigationController?,
        window: UIWindow?
    ) -> SplashCoordinatingController {
        SplashCoordinatingController(
            navigationController: navigationController,
            window: window,
            dependencies: self
        )
    }
    
    // MARK: - Dependencies for SplashCoordinatingControllerDependencies
    
    func makeAuthSceneDIContainer() -> AuthSceneDIContainer {
        return dependencies.authSceneDIContainer
    }
    
    func makeMainSceneDIContainer() -> MainSceneDIContainer {
        return dependencies.mainSceneDIContainer
    }
}
