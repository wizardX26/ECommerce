//
//  SideMenuCell.swift
//  ECommerce
//
//  Created by wizard.os25 on 17/11/25.
//

import UIKit

final class SideMenuCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupViews()
    }
    
    // MARK: - Private
    
    private func setupViews() {
        backgroundColor = .clear
        iconImageView.tintColor = .white
        titleLabel.textColor = .white
    }
    
    // MARK: - Public
    
    func fill(with model: SideMenuModel) {
        iconImageView.image = model.icon
        titleLabel.text = model.title
    }
}
