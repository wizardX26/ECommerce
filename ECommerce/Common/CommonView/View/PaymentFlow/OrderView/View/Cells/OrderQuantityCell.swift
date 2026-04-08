//
//  OrderQuantityCell.swift
//  ECommerce
//
//  Created by wizard.os25 on 14/1/26.
//

import UIKit

final class OrderQuantityCell: UITableViewCell {
        
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Input Quantity"
        label.font = Typography.fontBold16
        label.textColor = Colors.tokenDark100
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let quantityContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = Colors.tokenDark02
        view.layer.cornerRadius = BorderRadius.tokenBorderRadius12
        view.layer.borderWidth = Sizing.tokenSizing01
        view.layer.borderColor = Colors.tokenDark10.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let quantityMinusButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("-", for: .normal)
        button.titleLabel?.font = Typography.fontBold18
        button.setTitleColor(Colors.tokenDark100, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let quantityTextField: UITextField = {
        let textField = UITextField()
        textField.text = "1"
        textField.textAlignment = .center
        textField.font = Typography.fontMedium14
        textField.textColor = Colors.tokenDark100
        textField.keyboardType = .numberPad
        textField.borderStyle = .none
        textField.backgroundColor = Colors.tokenWhite
        textField.layer.cornerRadius = BorderRadius.tokenBorderRadius08
        textField.layer.masksToBounds = true
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let quantityPlusButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("+", for: .normal)
        button.titleLabel?.font = Typography.fontBold18
        button.setTitleColor(Colors.tokenDark100, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Callback
    var onQuantityChanged: ((Int) -> Void)?
    
    private var currentQuantity: Int = 1 {
        didSet {
            quantityTextField.text = "\(currentQuantity)"
            onQuantityChanged?(currentQuantity)
        }
    }
    
    // MARK: - Init
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(quantityContainerView)
        
        quantityContainerView.addSubview(quantityMinusButton)
        quantityContainerView.addSubview(quantityTextField)
        quantityContainerView.addSubview(quantityPlusButton)
        
        quantityMinusButton.addTarget(self, action: #selector(quantityMinusTapped), for: .touchUpInside)
        quantityPlusButton.addTarget(self, action: #selector(quantityPlusTapped), for: .touchUpInside)
        quantityTextField.delegate = self
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.tokenSpacing22),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            quantityContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.tokenSpacing22),
            quantityContainerView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            quantityContainerView.heightAnchor.constraint(equalToConstant: 40),
            quantityContainerView.widthAnchor.constraint(equalToConstant: 120),
            
            quantityMinusButton.leadingAnchor.constraint(equalTo: quantityContainerView.leadingAnchor, constant: Spacing.tokenSpacing08),
            quantityMinusButton.centerYAnchor.constraint(equalTo: quantityContainerView.centerYAnchor),
            quantityMinusButton.widthAnchor.constraint(equalToConstant: 24),
            quantityMinusButton.heightAnchor.constraint(equalToConstant: 24),
            
            quantityTextField.centerXAnchor.constraint(equalTo: quantityContainerView.centerXAnchor),
            quantityTextField.centerYAnchor.constraint(equalTo: quantityContainerView.centerYAnchor),
            quantityTextField.widthAnchor.constraint(equalToConstant: 40),
            
            quantityPlusButton.trailingAnchor.constraint(equalTo: quantityContainerView.trailingAnchor, constant: -Spacing.tokenSpacing08),
            quantityPlusButton.centerYAnchor.constraint(equalTo: quantityContainerView.centerYAnchor),
            quantityPlusButton.widthAnchor.constraint(equalToConstant: 24),
            quantityPlusButton.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    // MARK: - Configuration
    
    func configure(quantity: Int) {
        currentQuantity = quantity
    }
    
    func getQuantity() -> Int {
        return currentQuantity
    }
    
    // MARK: - Actions
    
    @objc private func quantityMinusTapped() {
        if currentQuantity > 1 {
            currentQuantity -= 1
        }
    }
    
    @objc private func quantityPlusTapped() {
        currentQuantity += 1
    }
}

// MARK: - UITextFieldDelegate

extension OrderQuantityCell: UITextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let text = textField.text, let value = Int(text), value > 0 {
            currentQuantity = value
        } else {
            quantityTextField.text = "\(currentQuantity)"
        }
    }
}
