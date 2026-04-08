//
//  DividerCell.swift
//  ECommerce
//
//  Created by wizard.os25 on 11/1/26.
//

import UIKit

final class DividerCell: UITableViewCell {
    
    private let divider = ECoDivider()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupViews()
    }
    
    // MARK: - Private
    private func setupViews() {
            backgroundColor = .clear
            selectionStyle = .none
            contentView.backgroundColor = .clear
            
            // Add divider
            divider.dividerType = .small
            divider.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(divider)
            
            NSLayoutConstraint.activate([
                divider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.tokenSpacing22),
                divider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.tokenSpacing22),
                divider.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                divider.heightAnchor.constraint(equalToConstant: Sizing.tokenSizing01)
            ])
        }
}
