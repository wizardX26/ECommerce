//
//  SignUpController.swift
//  ECommerce
//
//  Created by wizard.os25 on 9/1/26.
//

import Foundation
import UIKit

protocol SignUpControllerInput {
    func didTapSignUp(fullName: String, email: String, phone: String, password: String)
}

protocol SignUpControllerOutput {
    var isSignUpSuccess: Observable<Bool> { get }
    var successMessage: Observable<String?> { get }
    var screenTitle: String { get }
}

typealias SignUpController = SignUpControllerInput & SignUpControllerOutput & EcoController

final class DefaultSignUpController: SignUpController {
    
    private let signUpUseCase: SignUpUseCase
    private let mainQueue: DispatchQueueType
    private let utilities: Utilities
    
    private var signUpTask: Cancellable? { willSet { signUpTask?.cancel() } }
    
    // MARK: - OUTPUT
    
    let isSignUpSuccess: Observable<Bool> = Observable(false)
    let successMessage: Observable<String?> = Observable(nil)
    var screenTitle: String { "sign_up".localized() }
    
    // MARK: - EcoController Output (common to all controllers)
    
    let loading: Observable<Bool> = Observable(false)
    let error: Observable<Error?> = Observable(nil)
    let navigationState: Observable<EcoNavigationState> = Observable(.init())
    
    // MARK: - Navigation Bar Configuration
    
    var navigationBarTitle: String? {
        return self.screenTitle
    }
    
    var navigationBarLeftItem: EcoNavItem? {
        return nil // Hide left button bar on Sign-up screen
    }
    
    /// Override button tint color to black for back button
    var navigationBarButtonTintColor: UIColor? {
        return Colors.tokenDark100
    }

    /// Right bar: language switcher (EN/VI) for Login and Sign-up.
    var navigationBarRightItems: [EcoNavItem] {
        [.text(LanguageSwitcher.barButtonTitle(), action: { LanguageSwitcher.presentAndApply() })]
    }
    
    // MARK: - Init
    
    init(
        signUpUseCase: SignUpUseCase,
        utilities: Utilities = Utilities(),
        mainQueue: DispatchQueueType = DispatchQueue.main
    ) {
        self.signUpUseCase = signUpUseCase
        self.utilities = utilities
        self.mainQueue = mainQueue
    }
    
    // MARK: - Private
    
    private func handle(error: Error) {
        // Parse error message from API response
        let errorMessage = APIErrorParser.parseErrorMessage(from: error)
        let userFriendlyError = NSError(
            domain: "SignUpError",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: errorMessage]
        )
        self.error.value = userFriendlyError
    }
    
    private func handleSignUpSuccess(_ authResult: AuthResult) {
        // Save session and user info to UserDefaults
        utilities.saveSession(
            accessToken: authResult.session.accessToken,
            refreshToken: authResult.session.refreshToken,
            expiresAt: authResult.session.expiredAt
        )
        utilities.saveUser(user: authResult.user)
        utilities.saveLogging(true)
        
        // Update success state first
        isSignUpSuccess.value = true
        
        // Trigger success message - View will observe and show alert using default alertable
        successMessage.value = "sign_up_success".localized()
        
        // Send device token to server after successful signup
        // Delay một chút để đảm bảo session đã được lưu hoàn toàn vào Keychain
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            AppDelegate.sendDeviceTokenToServerIfLoggedIn()
        }
    }
}

// MARK: - INPUT. View event methods

extension DefaultSignUpController {
    
    func didTapSignUp(fullName: String, email: String, phone: String, password: String) {
        // Validation errors
        if fullName.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty {
            error.value = NSError(domain: "SignUpValidation", code: 1, userInfo: [NSLocalizedDescriptionKey: "validation_fill_all".localized()])
            return
        }
        
        if !isValidEmail(email) {
            error.value = NSError(domain: "SignUpValidation", code: 2, userInfo: [NSLocalizedDescriptionKey: "validation_valid_email".localized()])
            return
        }
        
        if !isValidPhone(phone) {
            error.value = NSError(domain: "SignUpValidation", code: 3, userInfo: [NSLocalizedDescriptionKey: "validation_valid_phone".localized()])
            return
        }
        
        if password.count < 6 {
            error.value = NSError(domain: "SignUpValidation", code: 4, userInfo: [NSLocalizedDescriptionKey: "validation_password_min".localized()])
            return
        }
        
        loading.value = true
        error.value = nil
        
        signUpTask = signUpUseCase.execute(
            fullName: fullName,
            email: email,
            phone: phone,
            password: password
        ) { [weak self] result in
            self?.mainQueue.async {
                self?.loading.value = false
                switch result {
                case .success(let authResult):
                    self?.handleSignUpSuccess(authResult)
                case .failure(let error):
                    self?.handle(error: error)
                }
            }
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func isValidPhone(_ phone: String) -> Bool {
        let phoneRegex = "^[0-9]{10,11}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: phone)
    }
}

// MARK: - EcoController Implementation

extension DefaultSignUpController {
    
    var onNavigationBarLeftItemTap: (() -> Void)? {
        { [weak self] in
            // Pop back to previous screen
            // This will be called when back button is tapped
            // The actual pop is handled by SignUpViewController's applyNavigation override
            // which sets navBarController.onLeftItemTap to perform the pop
        }
    }
    
    func onViewDidLoad() {
        // Initialize navigation state with back button
        // Ensure leftItem is set properly
        let leftItem = EcoNavItem.back { [weak self] in
            // This will be overridden by SignUpViewController
            self?.onNavigationBarLeftItemTap?()
        }
        
        
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