//
//  EditProfileViewController.swift
//  ECommerce
//
//  Created by wizard.os25 on 13/1/26.
//

import UIKit

final class EditProfileViewController: EcoViewController {
    
    // MARK: - UI Components
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let textField = EcoTextField()
    private let currentPasswordTextField = EcoTextField()
    private let newPasswordTextField = EcoTextField()
    private let confirmPasswordTextField = EcoTextField()
    
    private var saveButton: EcoButton!
    
    private var editProfileController: EditProfileController! {
        get { controller as? EditProfileController }
    }
    
    // MARK: - Lifecycle
    
    static func create(
        with editProfileController: EditProfileController
    ) -> EditProfileViewController {
        let view = EditProfileViewController.instantiateViewController()
        view.controller = editProfileController
        return view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        bindEditProfileSpecific()
        editProfileController.viewDidLoad()
    }
    
    // MARK: - Common Binding Override
    
    override func bindCommon() {
        super.bindCommon()
        bindEditProfileSpecific()
    }
    
    override func applyNavigation(_ state: EcoNavigationState) {
        super.applyNavigation(state)
        // No right bar button - removed Save button
    }
    
    // MARK: - EditProfile-Specific Binding
    
    private func bindEditProfileSpecific() {
        editProfileController.isSaveSuccess.observe(on: self) { [weak self] isSuccess in
            if isSuccess {
                // Success state is handled via successMessage Observable
            }
        }
        
        editProfileController.successMessage.observe(on: self) { [weak self] message in
            guard let self = self, let message = message, !message.isEmpty else { return }
            // Show success alert (card dismiss will be handled by ProfileViewController)
            self.showSuccessAlert(message: message)
        }
        
        editProfileController.error.observe(on: self) { [weak self] error in
            guard let self = self, let error = error else { return }
            self.showAlert(title: "Error", message: error.localizedDescription)
        }
        
        editProfileController.loading.observe(on: self) { [weak self] isLoading in
            guard let self = self, let saveButton = self.saveButton else { return }
            saveButton.setLoading(isLoading)
        }
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        view.backgroundColor = .systemBackground
        
        // Scroll View
        scrollView.keyboardDismissMode = .onDrag
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        // Content View
        contentView.backgroundColor = .clear
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Constraints
        let navBarHeight = editProfileController.navigationBarInitialHeight
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: navBarHeight),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        setupFormFields()
    }
    
    private func setupFormFields() {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = Spacing.tokenSpacing16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)
        
        // Setup text field based on field type
        if editProfileController.fieldType == .changePassword {
            // Change password requires 3 fields
            setupPasswordFields(stackView: stackView)
        } else {
            // Single field for other types
            setupSingleField(stackView: stackView)
        }
        
        // Save Button
        saveButton = EcoButton.authButton(title: "save".localized())
        saveButton.ecoDelegate = self
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(saveButton)
        
        // Stack View Constraints
        var constraints: [NSLayoutConstraint] = [
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Spacing.tokenSpacing22),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.tokenSpacing22),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.tokenSpacing22),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Spacing.tokenSpacing40),
            saveButton.heightAnchor.constraint(equalToConstant: Sizing.tokenSizing56)
        ]
        
        // Add field-specific constraints
        if editProfileController.fieldType == .changePassword {
            constraints.append(contentsOf: [
                currentPasswordTextField.heightAnchor.constraint(equalToConstant: Sizing.tokenSizing56),
                newPasswordTextField.heightAnchor.constraint(equalToConstant: Sizing.tokenSizing56),
                confirmPasswordTextField.heightAnchor.constraint(equalToConstant: Sizing.tokenSizing56)
            ])
        } else {
            constraints.append(
                textField.heightAnchor.constraint(equalToConstant: Sizing.tokenSizing56)
            )
        }
        
        NSLayoutConstraint.activate(constraints)
    }
    
    private func setupSingleField(stackView: UIStackView) {
        textField.type = .baseline
        textField.placeholder = editProfileController.placeholder
        textField.text = editProfileController.currentValue
        textField.cornerRadius = BorderRadius.tokenBorderRadius12
        textField.backgroundColorColor = Colors.tokenDark02
        textField.borderColor = Colors.tokenDark10
        textField.selectedBorderColor = Colors.tokenRainbowBlueEnd
        textField.errorBorderColor = Colors.tokenRed100
        textField.borderWidth = Sizing.tokenSizing01
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        // Set keyboard type based on field type
        switch editProfileController.fieldType {
        case .email:
            textField.keyboardType = .emailAddress
        case .phone:
            textField.keyboardType = .phonePad
        default:
            textField.keyboardType = .default
        }
        
        stackView.addArrangedSubview(textField)
    }
    
    private func setupPasswordFields(stackView: UIStackView) {
        // Current Password
        currentPasswordTextField.type = .secure
        currentPasswordTextField.placeholder = "current_password".localized()
        currentPasswordTextField.setLeftIcon("lock.fill", tintColor: Colors.tokenDark60)
        currentPasswordTextField.cornerRadius = BorderRadius.tokenBorderRadius12
        currentPasswordTextField.backgroundColorColor = Colors.tokenDark02
        currentPasswordTextField.borderColor = Colors.tokenDark10
        currentPasswordTextField.selectedBorderColor = Colors.tokenRainbowBlueEnd
        currentPasswordTextField.errorBorderColor = Colors.tokenRed100
        currentPasswordTextField.borderWidth = Sizing.tokenSizing01
        currentPasswordTextField.autocapitalizationType = .none
        currentPasswordTextField.autocorrectionType = .no
        currentPasswordTextField.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(currentPasswordTextField)
        
        // New Password
        newPasswordTextField.type = .secure
        newPasswordTextField.placeholder = "new_password".localized()
        newPasswordTextField.setLeftIcon("lock.fill", tintColor: Colors.tokenDark60)
        newPasswordTextField.cornerRadius = BorderRadius.tokenBorderRadius12
        newPasswordTextField.backgroundColorColor = Colors.tokenDark02
        newPasswordTextField.borderColor = Colors.tokenDark10
        newPasswordTextField.selectedBorderColor = Colors.tokenRainbowBlueEnd
        newPasswordTextField.errorBorderColor = Colors.tokenRed100
        newPasswordTextField.borderWidth = Sizing.tokenSizing01
        newPasswordTextField.autocapitalizationType = .none
        newPasswordTextField.autocorrectionType = .no
        newPasswordTextField.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(newPasswordTextField)
        
        // Confirm Password
        confirmPasswordTextField.type = .secure
        confirmPasswordTextField.placeholder = "confirm_password".localized()
        confirmPasswordTextField.setLeftIcon("lock.fill", tintColor: Colors.tokenDark60)
        confirmPasswordTextField.cornerRadius = BorderRadius.tokenBorderRadius12
        confirmPasswordTextField.backgroundColorColor = Colors.tokenDark02
        confirmPasswordTextField.borderColor = Colors.tokenDark10
        confirmPasswordTextField.selectedBorderColor = Colors.tokenRainbowBlueEnd
        confirmPasswordTextField.errorBorderColor = Colors.tokenRed100
        confirmPasswordTextField.borderWidth = Sizing.tokenSizing01
        confirmPasswordTextField.autocapitalizationType = .none
        confirmPasswordTextField.autocorrectionType = .no
        confirmPasswordTextField.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(confirmPasswordTextField)
    }
    
    // MARK: - Actions
    
    private func handleSave() {
        if editProfileController.fieldType == .changePassword {
            let currentPassword = currentPasswordTextField.text ?? ""
            let newPassword = newPasswordTextField.text ?? ""
            let confirmPassword = confirmPasswordTextField.text ?? ""
            
            guard !currentPassword.isEmpty, !newPassword.isEmpty, !confirmPassword.isEmpty else {
                showAlert(title: "error".localized(), message: "please_fill_all_password_fields".localized())
                return
            }
            
            guard newPassword == confirmPassword else {
                showAlert(title: "error".localized(), message: "password_mismatch".localized())
                return
            }
            
            if let defaultController = editProfileController as? DefaultEditProfileController {
                defaultController.savePassword(
                    currentPassword: currentPassword,
                    newPassword: newPassword,
                    newPasswordConfirmation: confirmPassword
                )
            }
        } else {
            let value = textField.text ?? ""
            editProfileController.didTapSave(value: value)
        }
    }
    
    private func showSuccessAlert(message: String) {
        // Show success alert
        // Card dismiss and data refresh will be handled by ProfileViewController
        showAlert(
            title: "success".localized(),
            message: message
        )
    }
}

// MARK: - EcoButtonDelegate

extension EditProfileViewController: EcoButtonDelegate {
    
    func buttonDidTap(_ button: EcoButton) {
        guard button == saveButton else { return }
        handleSave()
    }
}
