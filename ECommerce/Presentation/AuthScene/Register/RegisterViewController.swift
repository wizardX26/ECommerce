//
//  RegisterController.swift
//  MyKiot
//
//  Created by Nguyen Duc Hung on 3/6/25.
//

import UIKit

class RegisterController: UIViewController {
    
    // MARK: - UI Components
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let nameTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "Full Name"
        textField.borderStyle = .roundedRect
        textField.autocapitalizationType = .words
        textField.autocorrectionType = .no
        return textField
    }()
    
    private let emailTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "Email"
        textField.keyboardType = .emailAddress
        textField.borderStyle = .roundedRect
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        return textField
    }()
    
    private let phoneTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "Phone Number"
        textField.keyboardType = .phonePad
        textField.borderStyle = .roundedRect
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        return textField
    }()
    
    private let passwordTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "Password"
        textField.isSecureTextEntry = true
        textField.borderStyle = .roundedRect
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        return textField
    }()
    
    private let confirmPasswordTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "Confirm Password"
        textField.isSecureTextEntry = true
        textField.borderStyle = .roundedRect
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        return textField
    }()
    
    private let registerButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Register", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowOpacity = 0.1
        button.layer.shadowRadius = 4
        return button
    }()
    
    private let errorLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .systemRed
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        setupActions()
    }
    
    // MARK: - Setup
    private func setupNavigationBar() {
        title = "Sign Up"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // Large title configuration
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
            appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
            
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(nameTextField)
        contentView.addSubview(emailTextField)
        contentView.addSubview(phoneTextField)
        contentView.addSubview(passwordTextField)
        contentView.addSubview(confirmPasswordTextField)
        contentView.addSubview(registerButton)
        contentView.addSubview(errorLabel)
        contentView.addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // ContentView
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Name TextField
            nameTextField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            nameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            nameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            nameTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // Email TextField
            emailTextField.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 16),
            emailTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            emailTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            emailTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // Phone TextField
            phoneTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 16),
            phoneTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            phoneTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            phoneTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // Password TextField
            passwordTextField.topAnchor.constraint(equalTo: phoneTextField.bottomAnchor, constant: 16),
            passwordTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            passwordTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            passwordTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // Confirm Password TextField
            confirmPasswordTextField.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 16),
            confirmPasswordTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            confirmPasswordTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            confirmPasswordTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // Error Label
            errorLabel.topAnchor.constraint(equalTo: confirmPasswordTextField.bottomAnchor, constant: 12),
            errorLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            errorLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Register Button
            registerButton.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 24),
            registerButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            registerButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            registerButton.heightAnchor.constraint(equalToConstant: 50),
            registerButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),
            
            // Loading Indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: registerButton.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: registerButton.centerYAnchor)
        ])
    }
    
    private func setupActions() {
        registerButton.addTarget(self, action: #selector(registerButtonTapped), for: .touchUpInside)
        
        // Dismiss keyboard on tap
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Validation
    private func validateInputs() -> (isValid: Bool, errorMessage: String?) {
        guard let name = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !name.isEmpty else {
            return (false, "Please enter your full name")
        }
        
        guard name.count >= 2 else {
            return (false, "Name must be at least 2 characters")
        }
        
        guard let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !email.isEmpty else {
            return (false, "Please enter your email")
        }
        
        guard isValidEmail(email) else {
            return (false, "Please enter a valid email address")
        }
        
        guard let phone = phoneTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !phone.isEmpty else {
            return (false, "Please enter your phone number")
        }
        
        guard phone.count >= 10 else {
            return (false, "Phone number must be at least 10 digits")
        }
        
        guard let password = passwordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !password.isEmpty else {
            return (false, "Please enter your password")
        }
        
        guard password.count >= 6 else {
            return (false, "Password must be at least 6 characters")
        }
        
        guard let confirmPassword = confirmPasswordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !confirmPassword.isEmpty else {
            return (false, "Please confirm your password")
        }
        
        guard password == confirmPassword else {
            return (false, "Passwords do not match")
        }
        
        return (true, nil)
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func showError(_ message: String) {
        errorLabel.text = message
        errorLabel.isHidden = false
    }
    
    private func hideError() {
        errorLabel.isHidden = true
        errorLabel.text = nil
    }
    
    // MARK: - Actions
    @objc private func registerButtonTapped() {
        view.endEditing(true)
        hideError()
        
        // Validate inputs
        let validation = validateInputs()
        guard validation.isValid else {
            showError(validation.errorMessage ?? "Invalid input")
            return
        }
        
        // Start loading
        //setLoading(true)
        
        //        // Call API
        //        Task {
        //            do {
        //                let name = nameTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        //                let email = emailTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        //                let phone = phoneTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        //                let password = passwordTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        //
        //                let response = try await NetworkManager.shared.register(
        //                    fName: name,
        //                    email: email,
        //                    phone: phone,
        //                    password: password
        //                )
        //
        //                await MainActor.run {
        //                    self.setLoading(false)
        //
        //                    if response.success, let data = response.data {
        //                        // Save user info qua Utilities (không set login state vì user chưa đăng nhập)
        //                        Utilities().saveUserInfo(userData: data)
        //
        //                        // Show success message
        //                        self.showSuccessAndNavigateToLogin()
        //                    } else {
        //                        // Show error from API
        //                        let errorMessage = response.errors?.first?.message ?? response.message
        //                        self.showError(errorMessage ?? "Registration failed")
        //                    }
        //                }
        //            } catch {
        //                await MainActor.run {
        //                    self.setLoading(false)
        //                    self.showError("Network error. Please try again.")
        //                    print("❌ Register error: \(error)")
        //                }
        //            }
        //        }
    }
    
    private func showSuccessAndNavigateToLogin() {
        // Show success alert
        let alert = UIAlertController(
            title: "Success",
            message: "Registration successful! Please login to continue.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            // Navigate to LoginController
            //let loginVC = Storyboard.instantiateTab(of: LoginController.self, context: nil)
            //let navController = UINavigationController(rootViewController: loginVC)
            
            //            guard let window = (UIApplication.shared.delegate as? AppDelegate)?.window else { return }
            //
            //            UIView.transition(with: window,
            //                            duration: 0.3,
            //                            options: .transitionCrossDissolve,
            //                            animations: {
            //                window.rootViewController = navController
            //            }, completion: nil)
            //
            //        window.makeKeyAndVisible()
            //        })
            //
            //        present(alert, animated: true)
            //    }
            //
            //    private func setLoading(_ isLoading: Bool) {
            //        registerButton.isEnabled = !isLoading
            //        registerButton.alpha = isLoading ? 0.6 : 1.0
            //
            //        if isLoading {
            //            loadingIndicator.startAnimating()
            //        } else {
            //            loadingIndicator.stopAnimating()
            //        }
            //    }
            //}
        })
    }
}
