//
//  MainSceneDIContainer.swift
//  ECommerce
//
//  Created by wizard.os25 on 18/11/25.
//

import UIKit

final class MainSceneDIContainer: MainCoordinatingControllerDependencies {
    
    struct Dependencies {
        let sideMenuSceneDIContainer: SideMenuSceneDIContainer
        let appDIContainer: AppDIContainer
    }
    
    private let dependencies: Dependencies
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    // MARK: - Main View Controller
    
    func makeMainViewController() -> MainViewController {
        MainViewController.create(with: makeMainController())
    }
    
    func makeMainController() -> MainController {
        let controller = DefaultMainController(delegate: self)
        return controller
    }
    
    // MARK: - Main Container View Controller
    
    func makeMainContainerViewController() -> MainContainerViewController {
        // MainContainerViewController doesn't need controller pattern, create directly
        return MainContainerViewController()
    }
    
    // MARK: - Side Menu
    
    // Use shared instance to ensure same SideMenuController is used everywhere
    private lazy var sharedSideMenuDIContainer: SideMenuSceneDIContainer = {
        return dependencies.sideMenuSceneDIContainer
    }()
    
    func makeSideMenuSceneDIContainer() -> SideMenuSceneDIContainer {
        return sharedSideMenuDIContainer
    }
    
    // MARK: - App DI Container
    
    func getAppDIContainer() -> AppDIContainer {
        return dependencies.appDIContainer
    }
    
    // MARK: - Flow Coordinators
    
    func makeMainCoordinatingController(
        navigationController: UINavigationController
    ) -> MainCoordinatingController {
        MainCoordinatingController(
            navigationController: navigationController,
            dependencies: self
        )
    }
}

// MARK: - MainControllerDelegate

extension MainSceneDIContainer: MainControllerDelegate {
    
    func didSelectMenuItem(at index: Int) {
        // Handle menu item selection
        // This can be forwarded to a higher level coordinator if needed
    }
}


