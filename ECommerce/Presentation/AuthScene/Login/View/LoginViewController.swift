//
//  LoginViewController.swift
//  ECommerce
//
//  Created by wizard.os25 on 9/1/26.
//

import UIKit

final class LoginViewController: EcoViewController {
    
    // MARK: - UI Components
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Child Views
    private let headerView = LoginHeaderView()
    private let formView = LoginFormView()
    private let footerView = LoginFooterView()
    
    private var loginController: LoginController! {
        get { controller as? LoginController }
    }
    
    private weak var coordinatingController: LoginCoordinatingController?
    
    // MARK: - Lifecycle
    
    static func create(
        with loginController: LoginController
    ) -> LoginViewController {
        let view = LoginViewController.instantiateViewController()
        // Inject controller for EcoViewController - DI pattern
        view.controller = loginController
        return view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupChildViews()
        bindLoginSpecific()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Ensure system navigation bar is hidden
        navigationController?.isNavigationBarHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Ensure navigation bar is on top and can receive touches
        if let navBarView = navigationBarViewController?.view {
            view.bringSubviewToFront(navBarView)
            navBarView.isUserInteractionEnabled = true
        }
    }
    
    // MARK: - Common Binding Override
    
    override func bindCommon() {
        super.bindCommon()
        bindLoginSpecific()
    }
    
    // MARK: - Login-Specific Binding
    
    private func bindLoginSpecific() {
        loginController.isLoginSuccess.observe(on: self) { [weak self] isSuccess in
            if isSuccess {
                // Success state is handled via successMessage Observable
            }
        }
        
        loginController.successMessage.observe(on: self) { [weak self] message in
            guard let message = message, !message.isEmpty else { return }
            self?.showSuccessAlert(message: message)
        }
        
        // Bind error to show in error label
        loginController.error.observe(on: self) { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.formView.setError(error.localizedDescription)
            } else {
                self.formView.setError(nil)
            }
        }
        
        // Bind loading state
        loginController.loading.observe(on: self) { [weak self] isLoading in
            guard let self = self else { return }
            self.formView.isLoading = isLoading
        }
    }
    
    // MARK: - Setup Views
    
    private func setupViews() {
        title = loginController.screenTitle
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
        // ScrollView starts from safeArea, content will have top padding for navigation bar
        NSLayoutConstraint.activate([
            // Scroll View - Start from safeArea
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content View
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    private func setupChildViews() {
        // Get navigation bar initial height for top padding
        let navBarHeight = loginController.navigationBarInitialHeight
        
        // Header View - Add top padding equal to navigation bar height
        add(headerView, to: contentView)
        headerView.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headerView.view.topAnchor.constraint(equalTo: contentView.topAnchor, constant: navBarHeight),
            headerView.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            headerView.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
        
        // Form View
        formView.delegate = self
        add(formView, to: contentView)
        formView.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            formView.view.topAnchor.constraint(equalTo: headerView.view.bottomAnchor),
            formView.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            formView.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
        
        // Footer View
        footerView.delegate = self
        add(footerView, to: contentView)
        footerView.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            footerView.view.topAnchor.constraint(equalTo: formView.view.bottomAnchor, constant: Spacing.tokenSpacing12),
            footerView.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            footerView.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            footerView.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Sizing.tokenSizing40)
        ])
    }
    
    // MARK: - Error Handler Override
    
    override func handleError(_ error: Error?) {
        guard let error else { return }
        // Use default error handling from EcoViewController
        showAlert(title: "error".localized(), message: error.localizedDescription)
    }
    
    // MARK: - Private Helpers
    
    private func showSuccessAlert(message: String) {
        // Reset successMessage to nil to prevent showing again
        loginController.successMessage.value = nil
        
        // Use default alertable from EcoViewController
        showAlert(
            title: "success".localized(),
            message: message,
            completion: { [weak self] in
                // Navigate to Main screen after login success
                self?.formView.setSuccess()
                self?.navigateToMain()
            }
        )
    }
    
    private func navigateToMain() {
        guard let coordinatingController = coordinatingController else {
            return
        }
        coordinatingController.navigateToMain()
    }
    
    // MARK: - Coordinating Controller
    
    func setCoordinatingController(_ coordinatingController: LoginCoordinatingController) {
        self.coordinatingController = coordinatingController
    }
}

// MARK: - LoginFormViewDelegate

extension LoginViewController: LoginFormViewDelegate {
    
    func loginFormViewDidTapLogin(_ view: LoginFormView, phone: String, password: String) {
        loginController.didTapLogin(phone: phone, password: password)
    }
    
    func loginFormViewDidChange(_ view: LoginFormView, phone: String?, password: String?) {
        // Clear error when user changes input
        if !view.errorLabel.isHidden {
            view.setError(nil)
        }
    }
}

// MARK: - LoginFooterViewDelegate

extension LoginViewController: LoginFooterViewDelegate {
    
    func loginFooterViewDidTapSignUp(_ view: LoginFooterView) {
        guard let coordinatingController = coordinatingController else {
            return
        }
        coordinatingController.navigateToSignUp()
    }
}
