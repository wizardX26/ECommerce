//
//  LoginFormView.swift
//  ECommerce
//
//  Created by wizard.os25 on 9/1/26.
//

import UIKit

protocol LoginFormViewDelegate: AnyObject {
    func loginFormViewDidTapLogin(_ view: LoginFormView, phone: String, password: String)
    func loginFormViewDidChange(_ view: LoginFormView, phone: String?, password: String?)
}

final class LoginFormView: EcoBaseViewController {
    
    // MARK: - UI Components
    
    let phoneTextField = EcoTextField()
    let passwordTextField = EcoTextField()
    let errorLabel = UILabel()
    private var loginButton: EcoButton!
    
    // MARK: - Properties
    
    weak var delegate: LoginFormViewDelegate?
    
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
        
        // Login Button - Use authButton convenience method
        loginButton = EcoButton.authButton(title: "login".localized())
        loginButton.ecoDelegate = self
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loginButton)
        
        // Constraints
        NSLayoutConstraint.activate([
            // Phone Text Field
            phoneTextField.topAnchor.constraint(equalTo: view.topAnchor),
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
            
            // Login Button
            loginButton.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: Sizing.tokenSizing24),
            loginButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Sizing.tokenSizing24),
            loginButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Sizing.tokenSizing24),
            loginButton.heightAnchor.constraint(equalToConstant: Sizing.tokenSizing56),
            loginButton.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - State Updates
    
    private func updateLoadingState() {
        guard let loginButton = loginButton else { return }
        loginButton.setLoading(isLoading)
    }
    
    private func updateErrorState() {
        if let errorMessage = errorMessage, !errorMessage.isEmpty {
            errorLabel.text = errorMessage
            errorLabel.isHidden = false
            // Only show error on errorLabel, not on text fields to avoid duplicate red lines
        } else {
            errorLabel.isHidden = true
            phoneTextField.clearError()
            passwordTextField.clearError()
        }
    }
    
    // MARK: - Public Methods
    
    func clearFields() {
        phoneTextField.text = ""
        passwordTextField.text = ""
        errorMessage = nil
    }
    
    func setSuccess() {
        guard let loginButton = loginButton else { return }
        loginButton.setSuccess(true)
    }
    
    func setError(_ message: String?) {
        errorMessage = message
    }
}

// MARK: - EcoTextFieldDelegate

extension LoginFormView: EcoTextFieldDelegate {
    
    func textFieldDidChange(_ textField: EcoTextField) {
        delegate?.loginFormViewDidChange(
            self,
            phone: phoneTextField.text,
            password: passwordTextField.text
        )
    }
    
    func textFieldDidBeginEditing(_ textField: EcoTextField) {
        // Clear error when user starts editing
        if !errorLabel.isHidden {
            errorMessage = nil
        }
    }
    
    func textFieldDidEndEditing(_ textField: EcoTextField) {}
    
    func textFieldShouldReturn(_ textField: EcoTextField) -> Bool {
        if textField == phoneTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            textField.resignFirstResponder()
            handleLogin()
        }
        return true
    }
}

// MARK: - EcoButtonDelegate

extension LoginFormView: EcoButtonDelegate {
    
    func buttonDidTap(_ button: EcoButton) {
        handleLogin()
    }
    
    private func handleLogin() {
        guard let phone = phoneTextField.text,
              let password = passwordTextField.text,
              !phone.isEmpty,
              !password.isEmpty else {
            errorMessage = "validation_fill_all".localized()
            return
        }
        
        delegate?.loginFormViewDidTapLogin(
            self,
            phone: phone.trimmingCharacters(in: .whitespacesAndNewlines),
            password: password
        )
    }
}
