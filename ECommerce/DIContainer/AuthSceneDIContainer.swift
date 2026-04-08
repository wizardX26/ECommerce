//
//  AuthSceneDIContainer.swift
//  ECommerce
//
//  Created by wizard.os25 on 9/1/26.
//

import UIKit

final class AuthSceneDIContainer: SignUpCoordinatingControllerDependencies, LoginCoordinatingControllerDependencies {
    
    struct Dependencies {
        let apiDataTransferService: DataTransferService
        let appDIContainer: AppDIContainer
    }
    
    private let dependencies: Dependencies
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    // MARK: - Repositories
    
    func makeAuthRepository() -> AuthRepository {
        DefaultAuthRepository(
            dataTransferService: dependencies.apiDataTransferService
        )
    }
    
    // MARK: - Use Cases
    
    func makeSignUpUseCase() -> SignUpUseCase {
        DefaultSignUpUseCase(
            authRepository: makeAuthRepository()
        )
    }
    
    func makeLoginUseCase() -> LoginUseCase {
        DefaultLoginUseCase(
            authRepository: makeAuthRepository()
        )
    }
    
    // MARK: - Sign Up
    
    func makeSignUpViewController() -> SignUpViewController {
        SignUpViewController.create(
            with: makeSignUpController()
        )
    }
    
    func makeSignUpController() -> SignUpController {
        DefaultSignUpController(
            signUpUseCase: makeSignUpUseCase()
        )
    }
    
    // MARK: - Login
    
    func makeLoginViewController() -> LoginViewController {
        LoginViewController.create(
            with: makeLoginController()
        )
    }
    
    func makeLoginController() -> LoginController {
        DefaultLoginController(
            loginUseCase: makeLoginUseCase()
        )
    }
    
    // MARK: - Flow Coordinators
    
    func makeSignUpCoordinatingController(navigationController: UINavigationController) -> SignUpCoordinatingController {
        SignUpCoordinatingController(
            navigationController: navigationController,
            dependencies: self
        )
    }
    
    func makeLoginCoordinatingController(navigationController: UINavigationController) -> LoginCoordinatingController {
        LoginCoordinatingController(
            navigationController: navigationController,
            dependencies: self
        )
    }
    
    // MARK: - Main Scene (for navigation after login)
    
    func makeMainSceneDIContainer() -> MainSceneDIContainer {
        return dependencies.appDIContainer.makeMainSceneDIContainer()
    }
}
