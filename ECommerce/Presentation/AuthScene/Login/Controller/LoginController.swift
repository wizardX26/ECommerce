//
//  LoginController.swift
//  ECommerce
//
//  Created by wizard.os25 on 9/1/26.
//

import Foundation
import UIKit

protocol LoginControllerInput {
    func didTapLogin(phone: String, password: String)
}

protocol LoginControllerOutput {
    var isLoginSuccess: Observable<Bool> { get }
    var successMessage: Observable<String?> { get }
    var screenTitle: String { get }
}

typealias LoginController = LoginControllerInput & LoginControllerOutput & EcoController

final class DefaultLoginController: LoginController {
    
    private let loginUseCase: LoginUseCase
    private let mainQueue: DispatchQueueType
    private let utilities: Utilities
    
    private var loginTask: Cancellable? { willSet { loginTask?.cancel() } }
    
    // MARK: - OUTPUT
    
    let isLoginSuccess: Observable<Bool> = Observable(false)
    let successMessage: Observable<String?> = Observable(nil)
    var screenTitle: String { "login".localized() }
    
    // MARK: - EcoController Output (common to all controllers)
    
    let loading: Observable<Bool> = Observable(false)
    let error: Observable<Error?> = Observable(nil)
    let navigationState: Observable<EcoNavigationState> = Observable(.init())
    
    // MARK: - Navigation Bar Configuration
    
    var navigationBarTitle: String? {
        return self.screenTitle
    }
    
    var navigationBarLeftItem: EcoNavItem? {
        return nil // Hide left button bar on Login screen
    }

    /// Right bar: language switcher (EN/VI) for Login and Sign-up.
    var navigationBarRightItems: [EcoNavItem] {
        [.text(LanguageSwitcher.barButtonTitle(), action: { LanguageSwitcher.presentAndApply() })]
    }
    
    // MARK: - Init
    
    init(
        loginUseCase: LoginUseCase,
        utilities: Utilities = Utilities(),
        mainQueue: DispatchQueueType = DispatchQueue.main
    ) {
        self.loginUseCase = loginUseCase
        self.utilities = utilities
        self.mainQueue = mainQueue
    }
    
    // MARK: - Private
    
    private func handle(error: Error) {
        // Parse error message from API response
        let errorMessage = APIErrorParser.parseErrorMessage(from: error)
        let userFriendlyError = NSError(
            domain: "LoginError",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: errorMessage]
        )
        self.error.value = userFriendlyError
    }
    
    private func handleLoginSuccess(_ authResult: AuthResult) {
        // Save session and user info to UserDefaults
        utilities.saveSession(
            accessToken: authResult.session.accessToken,
            refreshToken: authResult.session.refreshToken,
            expiresAt: authResult.session.expiredAt
        )
        utilities.saveUser(user: authResult.user)
        utilities.saveLogging(true)
        
        // Update success state first
        isLoginSuccess.value = true
        
        // Trigger success message - View will observe and show alert using default alertable
        successMessage.value = "login_success".localized()
        
        // Send device token to server after successful login
        // Delay một chút để đảm bảo session đã được lưu hoàn toàn vào Keychain
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            AppDelegate.sendDeviceTokenToServerIfLoggedIn()
        }
    }
}

// MARK: - INPUT. View event methods

extension DefaultLoginController {
    
    func didTapLogin(phone: String, password: String) {
        // Validation errors
        if phone.isEmpty || password.isEmpty {
            error.value = NSError(domain: "LoginValidation", code: 1, userInfo: [NSLocalizedDescriptionKey: "validation_fill_all".localized()])
            return
        }
        
        if !isValidPhone(phone) {
            error.value = NSError(domain: "LoginValidation", code: 2, userInfo: [NSLocalizedDescriptionKey: "validation_valid_phone".localized()])
            return
        }
        
        if password.count < 6 {
            error.value = NSError(domain: "LoginValidation", code: 3, userInfo: [NSLocalizedDescriptionKey: "validation_password_min".localized()])
            return
        }
        
        loading.value = true
        error.value = nil
        
        loginTask = loginUseCase.execute(
            phone: phone,
            password: password
        ) { [weak self] result in
            self?.mainQueue.async {
                self?.loading.value = false
                switch result {
                case .success(let authResult):
                    self?.handleLoginSuccess(authResult)
                case .failure(let error):
                    self?.handle(error: error)
                }
            }
        }
    }
    
    private func isValidPhone(_ phone: String) -> Bool {
        let phoneRegex = "^[0-9]{10,11}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: phone)
    }
}

// MARK: - EcoController Implementation

extension DefaultLoginController {
    
    var onNavigationBarLeftItemTap: (() -> Void)? {
        { [weak self] in
            // Handle back button tap - navigation will be handled by coordinator
        }
    }
    
    func onViewDidLoad() {
        // Initialize navigation state
        let leftItem = navigationBarLeftItem
        
        navigationState.value = EcoNavigationState(
            title: navigationBarTitle,
            titleFont: navigationBarTitleFont,
            titleColor: navigationBarTitleColor,
            showsSearch: navigationBarShowsSearch,
            searchState: nil,
            leftItem: leftItem,
            rightItems: navigationBarRightItems,
            background: navigationBarBackground,
            backgroundColor: navigationBarBackgroundColor,
            buttonTintColor: navigationBarButtonTintColor,
            height: navigationBarInitialHeight,
            collapsedHeight: navigationBarCollapsedHeight,
            scrollBehavior: navigationBarScrollBehavior
        )
    }
    
    func onViewWillAppear() {
        // Handle view will appear if needed
    }
    
    func onViewDidDisappear() {
        // Handle view did disappear if needed
    }
}