//
//  SignUpCoordinatingController.swift
//  ECommerce
//
//  Created by wizard.os25 on 9/1/26.
//

import UIKit

protocol SignUpCoordinatingControllerDependencies {
    func makeSignUpViewController() -> SignUpViewController
}

final class SignUpCoordinatingController {
    
    private weak var navigationController: UINavigationController?
    private let dependencies: SignUpCoordinatingControllerDependencies
    
    init(navigationController: UINavigationController,
         dependencies: SignUpCoordinatingControllerDependencies) {
        self.navigationController = navigationController
        self.dependencies = dependencies
    }
    
    func start() {
        let vc = dependencies.makeSignUpViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
}
