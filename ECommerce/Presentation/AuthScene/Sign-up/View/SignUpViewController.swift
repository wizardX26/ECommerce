//
//  SignUpViewController.swift
//  ECommerce
//
//  Created by wizard.os25 on 9/1/26.
//

import UIKit

final class SignUpViewController: EcoViewController {
    
    // MARK: - UI Components
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Child Views
    private let headerView = SignUpHeaderView()
    private let formView = SignUpFormView()
    
    private var signUpController: SignUpController! {
        get { controller as? SignUpController }
    }
    
    // MARK: - Lifecycle
    
    static func create(
        with signUpController: SignUpController
    ) -> SignUpViewController {
        let view = SignUpViewController.instantiateViewController()
        // Inject controller for EcoViewController
        view.controller = signUpController
        return view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Enable swipe back gesture
        isSwipeBackEnabled = true
        setupViews()
        setupChildViews()
        bindSignUpSpecific()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Ensure swipe back gesture is enabled
        isSwipeBackEnabled = true
        // Ensure navigation bar is on top and can receive touches
        if let navBarView = navigationBarViewController?.view {
            view.bringSubviewToFront(navBarView)
            navBarView.isUserInteractionEnabled = true
        }
    }
    
    // MARK: - Common Binding Override
    
    override func bindCommon() {
        super.bindCommon()
        bindSignUpSpecific()
    }
    
    override func applyNavigation(_ state: EcoNavigationState) {
        super.applyNavigation(state)
        // Override left item tap callback to pop back to previous screen
        // Update callback after navigation bar is attached/updated
        // This ensures back button works both when navigation bar is first attached and when it's updated
        DispatchQueue.main.async { [weak self] in
            if let navBarController = self?.navigationBarViewController?.controller as? DefaultEcoNavigationBarController {
                navBarController.onLeftItemTap = { [weak self] in
                    self?.navigationController?.popViewController(animated: true)
                }
            } else {
            }
        }
    }
    
    // MARK: - SignUp-Specific Binding
    
    private func bindSignUpSpecific() {
        signUpController.isSignUpSuccess.observe(on: self) { [weak self] isSuccess in
            if isSuccess {
                // Success state is handled via successMessage Observable
            }
        }
        
        signUpController.successMessage.observe(on: self) { [weak self] message in
            guard let message = message, !message.isEmpty else { return }
            // Use default alertable from EcoViewController
            self?.showSuccessAlert(message: message)
        }
        
        // Bind error to show in error label
        signUpController.error.observe(on: self) { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.formView.setError(error.localizedDescription)
            } else {
                self.formView.setError(nil)
            }
        }
        
        // Bind loading state
        signUpController.loading.observe(on: self) { [weak self] isLoading in
            guard let self = self else { return }
            self.formView.isLoading = isLoading
        }
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        title = signUpController.screenTitle
        view.backgroundColor = .systemBackground
        
        // Scroll View
        scrollView.keyboardDismissMode = .onDrag
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        // Ensure scrollView doesn't block touch events to navigation bar
        scrollView.isUserInteractionEnabled = true
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
        let navBarHeight = signUpController.navigationBarInitialHeight
        
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
            formView.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            formView.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Sizing.tokenSizing40)
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
        signUpController.successMessage.value = nil
        
        // Use default alertable from EcoViewController
        showAlert(
            title: "success".localized(),
            message: message,
            completion: { [weak self] in
                // Navigate back or to next screen after alert dismissal
                self?.formView.setSuccess()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self?.navigationController?.popViewController(animated: true)
                }
            }
        )
    }
}

// MARK: - SignUpFormViewDelegate

extension SignUpViewController: SignUpFormViewDelegate {
    
    func signUpFormViewDidTapSignUp(
        _ view: SignUpFormView,
        fullName: String,
        email: String,
        phone: String,
        password: String
    ) {
        signUpController.didTapSignUp(
            fullName: fullName,
            email: email,
            phone: phone,
            password: password
        )
    }
    
    func signUpFormViewDidChange(_ view: SignUpFormView) {
        // Clear error when user changes input
        if !view.errorLabel.isHidden {
            view.setError(nil)
        }
    }
}
