//
//  NotificationCell.swift
//  ECommerce
//
//  Created by wizard.os25 on 19/1/26.
//

import UIKit

final class NotificationCell: UITableViewCell {
    
    static let height: CGFloat = 100
    
    // MARK: - UI Components
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let selectionButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        return button
    }()
    
    private var item: NotificationItemModel?
    var onSelectionButtonTap: (() -> Void)?
    
    // MARK: - Initialization
    
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
        backgroundColor = .systemBackground
        
        selectionButton.addTarget(self, action: #selector(selectionButtonTapped), for: .touchUpInside)
        
        contentView.addSubview(selectionButton)
        contentView.addSubview(titleLabel)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(timeLabel)
        
        NSLayoutConstraint.activate([
            selectionButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            selectionButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            selectionButton.widthAnchor.constraint(equalToConstant: 24),
            selectionButton.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.leadingAnchor.constraint(equalTo: selectionButton.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            
            descriptionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            
            timeLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            timeLabel.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 4),
            timeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    // MARK: - Configuration
    
    func configure(with item: NotificationItemModel) {
        self.item = item
        
        titleLabel.text = item.title
        descriptionLabel.text = item.description
        timeLabel.text = item.timeAgo
        
        // Update selection button
        updateSelectionButton(show: item.showSelectionButton, isSelected: item.isSelected)
    }
    
    private func updateSelectionButton(show: Bool, isSelected: Bool) {
        selectionButton.isHidden = !show
        
        if show {
            let bundle = Bundle(for: type(of: self))
            let iconName = isSelected ? "ic_radio_check" : "ic_new_tick_not_select"
            let icon = HelperFunction.getImage(named: iconName, in: bundle)
            selectionButton.setImage(icon, for: .normal)
        }
    }
    
    @objc private func selectionButtonTapped() {
        onSelectionButtonTap?()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        descriptionLabel.text = nil
        timeLabel.text = nil
        selectionButton.isHidden = true
        item = nil
        onSelectionButtonTap = nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Alternate cell background colors
        if let tableView = superview as? UITableView,
           let indexPath = tableView.indexPath(for: self) {
            backgroundColor = (indexPath.row % 2 == 0) ? .white : .systemGray6
        }
    }
}