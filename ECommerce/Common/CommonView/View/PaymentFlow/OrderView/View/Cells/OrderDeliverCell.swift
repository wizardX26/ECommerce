//
//  OrderDeliverCell.swift
//  ECommerce
//
//  Created by wizard.os25 on 14/1/26.
//

import UIKit

final class OrderDeliverCell: UITableViewCell {
        
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = Colors.tokenDark02
        view.layer.cornerRadius = BorderRadius.tokenBorderRadius04
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = Spacing.tokenSpacing08
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let deliveryTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Fast Delivery"
        label.font = Typography.fontBold16
        label.textColor = Colors.tokenDark100
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let shippingFeeLabel: UILabel = {
        let label = UILabel()
        label.text = "Shipping fee: Free"
        label.font = Typography.fontRegular14
        label.textColor = Colors.tokenDark60
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let guaranteedLabel: UILabel = {
        let label = UILabel()
        label.text = "Guaranteed delivery within 2-3 days"
        label.font = Typography.fontRegular12
        label.textColor = Colors.tokenDark60
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
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
        
        contentView.addSubview(containerView)
        containerView.addSubview(stackView)
        
        stackView.addArrangedSubview(deliveryTitleLabel)
        stackView.addArrangedSubview(shippingFeeLabel)
        stackView.addArrangedSubview(guaranteedLabel)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Spacing.tokenSpacing08),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.tokenSpacing22),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.tokenSpacing22),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Spacing.tokenSpacing08),
            
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: Spacing.tokenSpacing16),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Spacing.tokenSpacing16),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Spacing.tokenSpacing16),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -Spacing.tokenSpacing16)
        ])
    }
}
