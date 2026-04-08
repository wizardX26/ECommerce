//
//  SideMenuCoordinatingController.swift
//  ECommerce
//
//  Created by wizard.os25 on 17/11/25.
//

import UIKit

protocol SideMenuCoordinatingControllerDependencies {
    func makeSideMenuViewController() -> SideMenuViewController
    func makeSideMenuController() -> SideMenuController
}

final class SideMenuCoordinatingController {
    
    private let dependencies: SideMenuCoordinatingControllerDependencies
    
    init(
        dependencies: SideMenuCoordinatingControllerDependencies
    ) {
        self.dependencies = dependencies
    }
    
    // MARK: - Public
    
    func makeSideMenuViewController() -> SideMenuViewController {
        let controller = dependencies.makeSideMenuController()
        let viewController = SideMenuViewController.create(with: controller)
        return viewController
    }
}
