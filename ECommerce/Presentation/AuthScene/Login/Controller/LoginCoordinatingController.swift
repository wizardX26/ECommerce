//
//  LoginCoordinatingController.swift
//  ECommerce
//
//  Created by wizard.os25 on 9/1/26.
//

import UIKit
import ObjectiveC

protocol LoginCoordinatingControllerDependencies {
    func makeLoginViewController() -> LoginViewController
    func makeSignUpViewController() -> SignUpViewController
    func makeMainSceneDIContainer() -> MainSceneDIContainer
}

// Associated object key for storing LoginCoordinatingController reference
private var loginCoordinatingControllerKey: UInt8 = 0

extension UINavigationController {
    var loginCoordinatingController: LoginCoordinatingController? {
        get {
            return objc_getAssociatedObject(self, &loginCoordinatingControllerKey) as? LoginCoordinatingController
        }
        set {
            objc_setAssociatedObject(self, &loginCoordinatingControllerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

final class LoginCoordinatingController {
    
    private weak var navigationController: UINavigationController?
    private let dependencies: LoginCoordinatingControllerDependencies
    
    init(navigationController: UINavigationController,
         dependencies: LoginCoordinatingControllerDependencies) {
        self.navigationController = navigationController
        self.dependencies = dependencies
        
        // Attach self to navigationController to keep strong reference
        navigationController.loginCoordinatingController = self
    }
    
    func start() {
        let vc = dependencies.makeLoginViewController()
        vc.setCoordinatingController(self)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: - Navigation
    
    func navigateToSignUp() {
        let signUpVC = dependencies.makeSignUpViewController()
        navigationController?.pushViewController(signUpVC, animated: true)
    }
    
    func navigateToMain() {
        // Create MainContainerViewController and transition to Main screen
        // This matches the pattern used in SplashCoordinatingController
        let mainSceneDIContainer = dependencies.makeMainSceneDIContainer()
        let mainContainerViewController = mainSceneDIContainer.makeMainContainerViewController()
        
        // Transition to Main screen as root view controller
        transitionToRootViewController(mainContainerViewController)
    }
    
    // MARK: - Private Helpers
    
    private func transitionToRootViewController(_ viewController: UIViewController) {
        guard let window = navigationController?.view.window ?? UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else {
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
