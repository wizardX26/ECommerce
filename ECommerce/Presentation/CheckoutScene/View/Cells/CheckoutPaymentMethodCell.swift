//
//  CheckoutPaymentMethodCell.swift
//  ECommerce
//
//  Created by wizard.os25 on 15/1/26.
//

import UIKit

final class CheckoutPaymentMethodCell: UICollectionViewCell {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Payment method"
        label.font = Typography.fontBold16
        label.textColor = Colors.tokenDark100
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private var paymentMethodViews: [PaymentMethodView] = []
    private var onSelect: ((PaymentMethod) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            stackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }
    
    func configure(
        methods: [PaymentMethod],
        selected: PaymentMethod?,
        defaultCard: PaymentCard?,
        onSelect: @escaping (PaymentMethod) -> Void
    ) {
        self.onSelect = onSelect
        
        // Clear existing views
        paymentMethodViews.forEach { $0.removeFromSuperview() }
        paymentMethodViews.removeAll()
        
        // Create method views
        for method in methods {
            let methodView = PaymentMethodView(method: method, isSelected: method == selected, defaultCard: method == .chooseCard ? defaultCard : nil)
            methodView.onTap = { [weak self] in
                self?.selectMethod(method)
            }
            paymentMethodViews.append(methodView)
            stackView.addArrangedSubview(methodView)
        }
    }
    
    private func selectMethod(_ method: PaymentMethod) {
        paymentMethodViews.forEach { $0.setSelected($0.method == method) }
        onSelect?(method)
    }
}

private class PaymentMethodView: UIView {
    
    let method: PaymentMethod
    private let radioButton: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = Typography.fontRegular16
        label.textColor = Colors.tokenDark100
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let defaultCardLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.italicSystemFont(ofSize: 14)
        label.textColor = Colors.tokenRainbowBlueEnd // Match button color below
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var onTap: (() -> Void)?
    
    init(method: PaymentMethod, isSelected: Bool, defaultCard: PaymentCard?) {
        self.method = method
        super.init(frame: .zero)
        setupViews()
        setSelected(isSelected)
        configureMethod(defaultCard: defaultCard)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        addSubview(radioButton)
        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(defaultCardLabel)
        
        NSLayoutConstraint.activate([
            radioButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            radioButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            radioButton.widthAnchor.constraint(equalToConstant: 24),
            radioButton.heightAnchor.constraint(equalToConstant: 24),
            
            iconImageView.leadingAnchor.constraint(equalTo: radioButton.trailingAnchor, constant: 12),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 32),
            iconImageView.heightAnchor.constraint(equalToConstant: 32),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            defaultCardLabel.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 8),
            defaultCardLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            defaultCardLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
        
        // Set height
        heightAnchor.constraint(equalToConstant: 56).isActive = true
    }
    
    private func configureMethod(defaultCard: PaymentCard?) {
        switch method {
        case .addNewCard:
            titleLabel.text = "Add a new card"
            iconImageView.image = UIImage(systemName: "creditcard.fill")
            defaultCardLabel.text = nil
            defaultCardLabel.isHidden = true
        case .chooseCard:
            titleLabel.text = "Choose Card"
            iconImageView.image = UIImage(systemName: "creditcard.fill")
            if let card = defaultCard {
                defaultCardLabel.text = card.displayName
                defaultCardLabel.isHidden = false
            } else {
                defaultCardLabel.text = nil
                defaultCardLabel.isHidden = true
            }
        case .other:
            titleLabel.text = "Other payment methods"
            iconImageView.image = UIImage(systemName: "dollarsign.circle.fill")
            defaultCardLabel.text = nil
            defaultCardLabel.isHidden = true
        }
    }
    
    func setSelected(_ selected: Bool) {
        let bundle = Bundle.main
        if selected {
            radioButton.image = HelperFunction.getImage(named: "ic_radio_check", in: bundle)
        } else {
            radioButton.image = HelperFunction.getImage(named: "ic_new_tick_not_select", in: bundle)
        }
    }
    
    @objc private func tapped() {
        onTap?()
    }
}
