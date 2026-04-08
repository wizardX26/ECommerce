//
//  ProductGuaranteedCell.swift
//  ECommerce
//
//  Created by wizard.os25 on 14/1/26.
//

import UIKit

final class ProductGuaranteedCell: UIView {
    
    // MARK: - UI Components
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Order Protection"
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textColor = .black
        return label
    }()
    
    private let protectionStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .leading
        return stack
    }()
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = .white
        
        addSubview(titleLabel)
        addSubview(protectionStackView)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        protectionStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Create protection items
        let protectionItems = [
            ProtectionItem(icon: UIImage(systemName: "pencil"), title: "Secure Payment"),
            ProtectionItem(icon: UIImage(systemName: "leaf"), title: "Eco-Friendly Packaging"),
            ProtectionItem(icon: UIImage(systemName: "chineseyuanrenminbisign.bank.building.fill"), title: "Money Back Guarantee")
        ]
        
        for item in protectionItems {
            let itemView = createProtectionItemView(icon: item.icon, title: item.title)
            protectionStackView.addArrangedSubview(itemView)
        }
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            
            protectionStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            protectionStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            protectionStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            protectionStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }
    
    private func createProtectionItemView(icon: UIImage?, title: String) -> UIView {
        let containerView = UIView()
        
        let iconImageView = UIImageView()
        iconImageView.image = icon
        iconImageView.tintColor = .black
        iconImageView.contentMode = .scaleAspectFit
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 17)
        titleLabel.textColor = .black
        titleLabel.numberOfLines = 0 // Cho phép nhiều dòng để tránh chồng lên nhau
        
        containerView.addSubview(iconImageView)
        containerView.addSubview(titleLabel)
        
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Icon constraints
            iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            iconImageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 16),
            iconImageView.heightAnchor.constraint(equalToConstant: 16),
            
            // Title label constraints - đảm bảo không chồng lên nhau
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -16),
            titleLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            // Container view height - đảm bảo có đủ không gian cho icon và text
            containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 20)
        ])
        
        return containerView
    }
}

// MARK: - Protection Item Model

private struct ProtectionItem {
    let icon: UIImage?
    let title: String
}
