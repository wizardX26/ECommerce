//
//  EditProfileController.swift
//  ECommerce
//
//  Created by wizard.os25 on 13/1/26.
//

import Foundation
import UIKit

protocol EditProfileControllerInput {
    func viewDidLoad()
    func didTapSave(value: String)
}

protocol EditProfileControllerOutput {
    var fieldType: ProfileFieldType { get }
    var screenTitle: String { get }
    var placeholder: String { get }
    var currentValue: String { get }
    var isSaveSuccess: Observable<Bool> { get }
    var successMessage: Observable<String?> { get }
}

typealias EditProfileController = EditProfileControllerInput & EditProfileControllerOutput & EcoController

final class DefaultEditProfileController: EditProfileController {
    
    private let updateProfileUseCase: UpdateProfileUseCase?
    private let changePasswordUseCase: ChangePasswordUseCase?
    private let mainQueue: DispatchQueueType
    
    private var saveTask: Cancellable? { willSet { saveTask?.cancel() } }
    
    // MARK: - OUTPUT
    
    let fieldType: ProfileFieldType
    let screenTitle: String
    let placeholder: String
    let currentValue: String
    let isSaveSuccess: Observable<Bool> = Observable(false)
    let successMessage: Observable<String?> = Observable(nil)
    
    // Callback for account icon tap
    var onAccountIconTap: (() -> Void)?
    
    // MARK: - EcoController Output
    
    let loading: Observable<Bool> = Observable(false)
    let error: Observable<Error?> = Observable(nil)
    let navigationState: Observable<EcoNavigationState> = Observable(.init())
    
    // MARK: - Navigation Bar Configuration
    
    var navigationBarTitle: String? {
        return self.screenTitle
    }
    
    var navigationBarRightItems: [EcoNavItem] {
        return [] // No right bar button
    }
    
    var navigationBarBackground: EcoNavigationBackground {
        return .solid(.white)
    }
    
    var navigationBarBackgroundColor: UIColor? {
        return .white
    }
    
    var navigationBarButtonTintColor: UIColor? {
        return Colors.tokenRainbowBlueEnd
    }
    
    var navigationBarTitleColor: UIColor? {
        return .black
    }
    
    var navigationBarInitialHeight: CGFloat {
        return 80
    }
    
    var navigationBarCollapsedHeight: CGFloat {
        return 80
    }
    
    var navigationBarScrollBehavior: EcoNavigationScrollBehavior {
        return .sticky
    }
    
    // MARK: - Init
    
    init(
        fieldType: ProfileFieldType,
        screenTitle: String,
        currentValue: String,
        updateProfileUseCase: UpdateProfileUseCase?,
        changePasswordUseCase: ChangePasswordUseCase?,
        mainQueue: DispatchQueueType = DispatchQueue.main
    ) {
        self.fieldType = fieldType
        self.screenTitle = screenTitle
        self.placeholder = screenTitle // Use screenTitle as placeholder
        self.currentValue = currentValue
        self.updateProfileUseCase = updateProfileUseCase
        self.changePasswordUseCase = changePasswordUseCase
        self.mainQueue = mainQueue
    }
    
    // MARK: - Private
    
    private func handle(error: Error) {
        let errorMessage = APIErrorParser.parseErrorMessage(from: error)
        let userFriendlyError = NSError(
            domain: "EditProfileError",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: errorMessage]
        )
        self.error.value = userFriendlyError
    }
    
    private func handleSaveSuccess(_ updatedUser: User? = nil) {
        // Update UserDefaults if user info was updated
        if let user = updatedUser {
            let utilities = Utilities()
            utilities.saveUser(user: user)
        }
        
        isSaveSuccess.value = true
        successMessage.value = "Profile updated successfully"
    }
}

// MARK: - INPUT Implementation

extension DefaultEditProfileController {
    
    func viewDidLoad() {
        // Setup navigation state
    }
    
    func didTapSave(value: String) {
        guard !value.isEmpty else {
            let error = NSError(
                domain: "EditProfileError",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Please enter a value"]
            )
            handle(error: error)
            return
        }
        
        loading.value = true
        error.value = nil
        
        switch fieldType {
        case .fullName:
            saveFullName(value)
        case .email:
            saveEmail(value)
        case .phone:
            savePhone(value)
        case .changePassword:
            // Change password requires different handling (current password + new password)
            // This will be handled separately in view controller
            break
        }
    }
    
    private func saveFullName(_ value: String) {
        guard let updateProfileUseCase = updateProfileUseCase else {
            handle(error: NSError(domain: "EditProfileError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Update profile use case not available"]))
            return
        }
        
        saveTask = updateProfileUseCase.execute(
            fName: value,
            email: nil,
            phone: nil
        ) { [weak self] result in
            self?.mainQueue.async {
                self?.loading.value = false
                
                switch result {
                case .success(let user):
                    self?.handleSaveSuccess(user)
                case .failure(let error):
                    self?.handle(error: error)
                }
            }
        }
    }
    
    private func saveEmail(_ value: String) {
        guard let updateProfileUseCase = updateProfileUseCase else {
            handle(error: NSError(domain: "EditProfileError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Update profile use case not available"]))
            return
        }
        
        saveTask = updateProfileUseCase.execute(
            fName: nil,
            email: value,
            phone: nil
        ) { [weak self] result in
            self?.mainQueue.async {
                self?.loading.value = false
                
                switch result {
                case .success(let user):
                    self?.handleSaveSuccess(user)
                case .failure(let error):
                    self?.handle(error: error)
                }
            }
        }
    }
    
    private func savePhone(_ value: String) {
        guard let updateProfileUseCase = updateProfileUseCase else {
            handle(error: NSError(domain: "EditProfileError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Update profile use case not available"]))
            return
        }
        
        saveTask = updateProfileUseCase.execute(
            fName: nil,
            email: nil,
            phone: value
        ) { [weak self] result in
            self?.mainQueue.async {
                self?.loading.value = false
                
                switch result {
                case .success(let user):
                    self?.handleSaveSuccess(user)
                case .failure(let error):
                    self?.handle(error: error)
                }
            }
        }
    }
    
    func savePassword(currentPassword: String, newPassword: String, newPasswordConfirmation: String) {
        guard let changePasswordUseCase = changePasswordUseCase else {
            handle(error: NSError(domain: "EditProfileError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Change password use case not available"]))
            return
        }
        
        loading.value = true
        error.value = nil
        
        saveTask = changePasswordUseCase.execute(
            currentPassword: currentPassword,
            newPassword: newPassword,
            newPasswordConfirmation: newPasswordConfirmation
        ) { [weak self] result in
            self?.mainQueue.async {
                self?.loading.value = false
                
                switch result {
                case .success:
                    // Change password returns Void, not User
                    self?.handleSaveSuccess()
                case .failure(let error):
                    self?.handle(error: error)
                }
            }
        }
    }
}

// MARK: - EcoController Implementation

extension DefaultEditProfileController {
    
    func onViewDidLoad() {
        navigationState.value = EcoNavigationState(
            title: navigationBarTitle,
            titleFont: navigationBarTitleFont,
            titleColor: navigationBarTitleColor,
            showsSearch: false,
            searchState: nil,
            leftItem: nil,
            rightItems: navigationBarRightItems,
            background: navigationBarBackground,
            backgroundColor: navigationBarBackgroundColor,
            buttonTintColor: navigationBarButtonTintColor,
            height: navigationBarInitialHeight,
            collapsedHeight: navigationBarCollapsedHeight,
            backButtonStyle: .simple,
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
