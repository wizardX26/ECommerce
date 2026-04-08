//
//  SignUpFormView.swift
//  ECommerce
//
//  Created by wizard.os25 on 9/1/26.
//

import UIKit

protocol SignUpFormViewDelegate: AnyObject {
    func signUpFormViewDidTapSignUp(
        _ view: SignUpFormView,
        fullName: String,
        email: String,
        phone: String,
        password: String
    )
    func signUpFormViewDidChange(_ view: SignUpFormView)
}

final class SignUpFormView: EcoBaseViewController {
    
    // MARK: - UI Components
    
    let fullNameTextField = EcoTextField()
    let emailTextField = EcoTextField()
    let phoneTextField = EcoTextField()
    let passwordTextField = EcoTextField()
    let errorLabel = UILabel()
    private var signUpButton: EcoButton!
    
    // MARK: - Properties
    
    weak var delegate: SignUpFormViewDelegate?
    
    var isLoading: Bool = false {
        didSet {
            updateLoadingState()
        }
    }
    
    var errorMessage: String? {
        didSet {
            updateErrorState()
        }
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        view.backgroundColor = .clear
        
        // Full Name Text Field
        fullNameTextField.type = .baseline
        fullNameTextField.placeholder = "full_name".localized()
        fullNameTextField.setLeftIcon("person.fill", tintColor: Colors.tokenDark60)
        fullNameTextField.autocapitalizationType = .words
        fullNameTextField.autocorrectionType = .no
        fullNameTextField.cornerRadius = BorderRadius.tokenBorderRadius12
        fullNameTextField.backgroundColorColor = Colors.tokenDark02
        fullNameTextField.borderColor = Colors.tokenDark10
        fullNameTextField.selectedBorderColor = Colors.tokenRainbowBlueEnd
        fullNameTextField.errorBorderColor = Colors.tokenRed100
        fullNameTextField.borderWidth = Sizing.tokenSizing01
        fullNameTextField.ecoDelegate = self
        fullNameTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(fullNameTextField)
        
        // Email Text Field
        emailTextField.type = .baseline
        emailTextField.placeholder = "email".localized()
        emailTextField.setLeftIcon("envelope.fill", tintColor: Colors.tokenDark60)
        emailTextField.keyboardType = .emailAddress
        emailTextField.autocapitalizationType = .none
        emailTextField.autocorrectionType = .no
        emailTextField.cornerRadius = BorderRadius.tokenBorderRadius12
        emailTextField.backgroundColorColor = Colors.tokenDark02
        emailTextField.borderColor = Colors.tokenDark10
        emailTextField.selectedBorderColor = Colors.tokenRainbowBlueEnd
        emailTextField.errorBorderColor = Colors.tokenRed100
        emailTextField.borderWidth = Sizing.tokenSizing01
        emailTextField.ecoDelegate = self
        emailTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emailTextField)
        
        // Phone Text Field
        phoneTextField.type = .baseline
        phoneTextField.placeholder = "phone_number".localized()
        phoneTextField.setLeftIcon("phone.fill", tintColor: Colors.tokenDark60)
        phoneTextField.keyboardType = .phonePad
        phoneTextField.autocapitalizationType = .none
        phoneTextField.autocorrectionType = .no
        phoneTextField.cornerRadius = BorderRadius.tokenBorderRadius12
        phoneTextField.backgroundColorColor = Colors.tokenDark02
        phoneTextField.borderColor = Colors.tokenDark10
        phoneTextField.selectedBorderColor = Colors.tokenRainbowBlueEnd
        phoneTextField.errorBorderColor = Colors.tokenRed100
        phoneTextField.borderWidth = Sizing.tokenSizing01
        phoneTextField.ecoDelegate = self
        phoneTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(phoneTextField)
        
        // Password Text Field
        passwordTextField.type = .secure
        passwordTextField.placeholder = "password".localized()
        passwordTextField.setLeftIcon("lock.fill", tintColor: Colors.tokenDark60)
        passwordTextField.autocapitalizationType = .none
        passwordTextField.autocorrectionType = .no
        passwordTextField.showsClearButton = true // Enable clear button for password field
        passwordTextField.cornerRadius = BorderRadius.tokenBorderRadius12
        passwordTextField.backgroundColorColor = Colors.tokenDark02
        passwordTextField.borderColor = Colors.tokenDark10
        passwordTextField.selectedBorderColor = Colors.tokenRainbowBlueEnd
        passwordTextField.errorBorderColor = Colors.tokenRed100
        passwordTextField.borderWidth = Sizing.tokenSizing01
        passwordTextField.ecoDelegate = self
        passwordTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(passwordTextField)
        
        // Error Label
        errorLabel.textColor = Colors.tokenRed100
        errorLabel.font = Typography.fontMedium14
        errorLabel.numberOfLines = 0
        errorLabel.textAlignment = .center
        errorLabel.isHidden = true
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(errorLabel)
        
        // Sign Up Button - Use authButton convenience method
        signUpButton = EcoButton.authButton(title: "sign_up".localized())
        signUpButton.ecoDelegate = self
        signUpButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(signUpButton)
        
        // Constraints
        NSLayoutConstraint.activate([
            // Full Name Text Field
            fullNameTextField.topAnchor.constraint(equalTo: view.topAnchor),
            fullNameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Sizing.tokenSizing24),
            fullNameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Sizing.tokenSizing24),
            fullNameTextField.heightAnchor.constraint(equalToConstant: Sizing.tokenSizing56),
            
            // Email Text Field
            emailTextField.topAnchor.constraint(equalTo: fullNameTextField.bottomAnchor, constant: Sizing.tokenSizing16),
            emailTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Sizing.tokenSizing24),
            emailTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Sizing.tokenSizing24),
            emailTextField.heightAnchor.constraint(equalToConstant: Sizing.tokenSizing56),
            
            // Phone Text Field
            phoneTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: Sizing.tokenSizing16),
            phoneTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Sizing.tokenSizing24),
            phoneTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Sizing.tokenSizing24),
            phoneTextField.heightAnchor.constraint(equalToConstant: Sizing.tokenSizing56),
            
            // Password Text Field
            passwordTextField.topAnchor.constraint(equalTo: phoneTextField.bottomAnchor, constant: Sizing.tokenSizing16),
            passwordTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Sizing.tokenSizing24),
            passwordTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Sizing.tokenSizing24),
            passwordTextField.heightAnchor.constraint(equalToConstant: Sizing.tokenSizing56),
            
            // Error Label
            errorLabel.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: Sizing.tokenSizing08),
            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Sizing.tokenSizing24),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Sizing.tokenSizing24),
            
            // Sign Up Button
            signUpButton.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: Sizing.tokenSizing24),
            signUpButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Sizing.tokenSizing24),
            signUpButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Sizing.tokenSizing24),
            signUpButton.heightAnchor.constraint(equalToConstant: Sizing.tokenSizing56),
            signUpButton.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - State Updates
    
    private func updateLoadingState() {
        guard let signUpButton = signUpButton else { return }
        signUpButton.setLoading(isLoading)
    }
    
    private func updateErrorState() {
        if let errorMessage = errorMessage, !errorMessage.isEmpty {
            errorLabel.text = errorMessage
            errorLabel.isHidden = false
            // Only show error on errorLabel, not on text fields to avoid duplicate red lines
        } else {
            errorLabel.isHidden = true
            fullNameTextField.clearError()
            emailTextField.clearError()
            phoneTextField.clearError()
            passwordTextField.clearError()
        }
    }
    
    // MARK: - Public Methods
    
    func clearFields() {
        fullNameTextField.text = ""
        emailTextField.text = ""
        phoneTextField.text = ""
        passwordTextField.text = ""
        errorMessage = nil
    }
    
    func setSuccess() {
        guard let signUpButton = signUpButton else { return }
        signUpButton.setSuccess(true)
    }
    
    func setError(_ message: String?) {
        errorMessage = message
    }
}

// MARK: - EcoTextFieldDelegate

extension SignUpFormView: EcoTextFieldDelegate {
    
    func textFieldDidChange(_ textField: EcoTextField) {
        delegate?.signUpFormViewDidChange(self)
    }
    
    func textFieldDidBeginEditing(_ textField: EcoTextField) {
        // Clear error when user starts editing
        if !errorLabel.isHidden {
            errorMessage = nil
        }
    }
    
    func textFieldDidEndEditing(_ textField: EcoTextField) {}
    
    func textFieldShouldReturn(_ textField: EcoTextField) -> Bool {
        switch textField {
        case fullNameTextField:
            emailTextField.becomeFirstResponder()
        case emailTextField:
            phoneTextField.becomeFirstResponder()
        case phoneTextField:
            passwordTextField.becomeFirstResponder()
        case passwordTextField:
            textField.resignFirstResponder()
            handleSignUp()
        default:
            textField.resignFirstResponder()
        }
        return true
    }
}

// MARK: - EcoButtonDelegate

extension SignUpFormView: EcoButtonDelegate {
    
    func buttonDidTap(_ button: EcoButton) {
        handleSignUp()
    }
    
    private func handleSignUp() {
        guard let fullName = fullNameTextField.text,
              let email = emailTextField.text,
              let phone = phoneTextField.text,
              let password = passwordTextField.text,
              !fullName.isEmpty,
              !email.isEmpty,
              !phone.isEmpty,
              !password.isEmpty else {
            errorMessage = "validation_fill_all".localized()
            return
        }
        
        delegate?.signUpFormViewDidTapSignUp(
            self,
            fullName: fullName.trimmingCharacters(in: .whitespacesAndNewlines),
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            phone: phone.trimmingCharacters(in: .whitespacesAndNewlines),
            password: password
        )
    }
}
