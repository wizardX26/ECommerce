//
//  LoginFooterView.swift
//  ECommerce
//
//  Created by wizard.os25 on 9/1/26.
//

import UIKit

protocol LoginFooterViewDelegate: AnyObject {
    func loginFooterViewDidTapSignUp(_ view: LoginFooterView)
}

final class LoginFooterView: EcoBaseViewController {
    
    // MARK: - UI Components
    
    private let containerView = UIView()
    private let promptLabel = UILabel()
    private let signUpButton = UIButton(type: .system)
    
    // MARK: - Properties
    
    weak var delegate: LoginFooterViewDelegate?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        view.backgroundColor = .clear
        
        // Container
        containerView.backgroundColor = .clear
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        // Prompt Label
        promptLabel.text = "dont_have_account".localized()
        promptLabel.font = Typography.fontRegular16
        promptLabel.textColor = Colors.tokenDark60
        promptLabel.textAlignment = .center
        promptLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(promptLabel)
        
        // Sign Up Button
        signUpButton.setTitle("sign_up".localized(), for: .normal)
        signUpButton.titleLabel?.font = Typography.fontMedium16
        signUpButton.setTitleColor(Colors.tokenRainbowBlueEnd, for: .normal)
        signUpButton.addTarget(self, action: #selector(signUpButtonTapped), for: .touchUpInside)
        signUpButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(signUpButton)
        
        // Constraints
        NSLayoutConstraint.activate([
            // Container
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Prompt Label
            promptLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            promptLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            // Sign Up Button
            signUpButton.topAnchor.constraint(equalTo: promptLabel.bottomAnchor, constant: Sizing.tokenSizing08),
            signUpButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            signUpButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -Sizing.tokenSizing40)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func signUpButtonTapped() {
        delegate?.loginFooterViewDidTapSignUp(self)
    }
}
