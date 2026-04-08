//
//  CheckoutOrderSummaryCell.swift
//  ECommerce
//
//  Created by wizard.os25 on 15/1/26.
//

import UIKit

final class CheckoutOrderSummaryCell: UICollectionViewCell {
    
    private let subtotalLabel: UILabel = {
        let label = UILabel()
        label.text = "Subtotal"
        label.font = Typography.fontRegular14
        label.textColor = Colors.tokenDark60
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let subtotalValueLabel: UILabel = {
        let label = UILabel()
        label.font = Typography.fontRegular14
        label.textColor = Colors.tokenDark100
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let shippingLabel: UILabel = {
        let label = UILabel()
        label.text = "Shipping"
        label.font = Typography.fontRegular14
        label.textColor = Colors.tokenDark60
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let shippingValueLabel: UILabel = {
        let label = UILabel()
        label.font = Typography.fontRegular14
        label.textColor = Colors.tokenDark100
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let totalLabel: UILabel = {
        let label = UILabel()
        label.text = "Total"
        label.font = Typography.fontBold16
        label.textColor = Colors.tokenDark100
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let totalValueLabel: UILabel = {
        let label = UILabel()
        label.font = Typography.fontBold16
        label.textColor = Colors.tokenDark100
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        contentView.addSubview(subtotalLabel)
        contentView.addSubview(subtotalValueLabel)
        contentView.addSubview(shippingLabel)
        contentView.addSubview(shippingValueLabel)
        contentView.addSubview(totalLabel)
        contentView.addSubview(totalValueLabel)
        
        NSLayoutConstraint.activate([
            subtotalLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
            subtotalLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            subtotalValueLabel.centerYAnchor.constraint(equalTo: subtotalLabel.centerYAnchor),
            subtotalValueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            shippingLabel.topAnchor.constraint(equalTo: subtotalLabel.bottomAnchor, constant: 4),
            shippingLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            shippingValueLabel.centerYAnchor.constraint(equalTo: shippingLabel.centerYAnchor),
            shippingValueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            totalLabel.topAnchor.constraint(equalTo: shippingLabel.bottomAnchor, constant: 4),
            totalLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            totalLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            totalValueLabel.centerYAnchor.constraint(equalTo: totalLabel.centerYAnchor),
            totalValueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }
    
    func configure(
        summary: OrderSummary?,
        shippingFeeFromAddress: String? = nil,
        items: [CheckoutCartItem]? = nil
    ) {
        guard let summary = summary else { return }
        
        // Format giá bỏ .00 khi không cần, có separator
        // Subtotal - tính từ tổng price của các sản phẩm (đã có trong summary)
        let subtotalFormatted = summary.subtotal.formattedWithSeparatorWithoutTrailingZeros
        subtotalLabel.text = "Subtotal"
        subtotalValueLabel.text = "\(subtotalFormatted) vnd"
        
        // Shipping - tính bằng số lượng sản phẩm * shipping_fee từ address
        if let shippingFeeString = shippingFeeFromAddress,
           !shippingFeeString.isEmpty,
           let shippingFeePerItem = Double(shippingFeeString),
           shippingFeePerItem > 0 {
            // Tính số lượng sản phẩm
            let totalQuantity = items?.reduce(0) { $0 + $1.quantity } ?? 0
            let totalShippingFee = shippingFeePerItem * Double(totalQuantity)
            let shippingFormatted = totalShippingFee.formattedWithSeparatorWithoutTrailingZeros
            shippingLabel.text = "Shipping"
            shippingValueLabel.text = "\(shippingFormatted) vnd"
            shippingValueLabel.textColor = Colors.tokenDark100
        } else {
            // Use shippingFee from summary if available (fallback)
            if summary.shippingFee > 0 {
                let shippingFormatted = summary.shippingFee.formattedWithSeparatorWithoutTrailingZeros
                shippingLabel.text = "Shipping"
                shippingValueLabel.text = "\(shippingFormatted) vnd"
                shippingValueLabel.textColor = Colors.tokenDark100
            } else {
                shippingLabel.text = "Shipping"
                shippingValueLabel.text = "Calculate by address"
                shippingValueLabel.textColor = Colors.tokenDark60
            }
        }
        
        // Total - format bỏ .00 khi không cần
        let totalFormatted = summary.total.formattedWithSeparatorWithoutTrailingZeros
        totalLabel.text = "Total"
        totalValueLabel.text = "\(totalFormatted) vnd"
    }
}
