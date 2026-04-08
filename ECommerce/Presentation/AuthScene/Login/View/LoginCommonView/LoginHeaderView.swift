//
//  LoginHeaderView.swift
//  ECommerce
//
//  Created by wizard.os25 on 9/1/26.
//

import UIKit

final class LoginHeaderView: EcoBaseViewController {
    
    // MARK: - UI Components
    
    private let logoImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        view.backgroundColor = .clear
        
        // Logo
        logoImageView.image = UIImage(systemName: "cart.fill")
        logoImageView.tintColor = Colors.tokenRainbowBlueEnd
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoImageView)
        
        // Title
        titleLabel.text = "welcome_back".localized()
        titleLabel.font = Typography.fontBold32
        titleLabel.textColor = Colors.tokenDark100
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        // Subtitle
        subtitleLabel.text = "sign_in_to_continue".localized()
        subtitleLabel.font = Typography.fontRegular16
        subtitleLabel.textColor = Colors.tokenDark60
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(subtitleLabel)
        
        // Constraints
        NSLayoutConstraint.activate([
            // Logo
            logoImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: Sizing.tokenSizing40),
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: Sizing.tokenSizing80),
            logoImageView.heightAnchor.constraint(equalToConstant: Sizing.tokenSizing80),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: Sizing.tokenSizing24),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Sizing.tokenSizing24),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Sizing.tokenSizing24),
            
            // Subtitle
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: Sizing.tokenSizing08),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Sizing.tokenSizing24),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Sizing.tokenSizing24),
            subtitleLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -Sizing.tokenSizing40)
        ])
    }
}
