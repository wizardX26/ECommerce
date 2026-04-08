//
//  CheckoutAddressCell.swift
//  ECommerce
//
//  Created by wizard.os25 on 15/1/26.
//

import UIKit

final class CheckoutAddressCell: UICollectionViewCell {
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = BorderRadius.tokenBorderRadius12
        view.layer.borderWidth = 1
        view.layer.borderColor = Colors.tokenDark10.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let locationIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "mappin.circle.fill")
        imageView.tintColor = Colors.tokenRainbowBlueEnd
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let addressLabel: UILabel = {
        let label = UILabel()
        label.font = Typography.fontRegular16
        label.textColor = Colors.tokenDark100
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let chevronIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "chevron.right")
        imageView.tintColor = Colors.tokenDark60
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let defaultAddressLabel: UILabel = {
        let label = UILabel()
        label.text = "Use saved location"
        label.font = UIFont.italicSystemFont(ofSize: 14)
        label.textColor = Colors.tokenRainbowBlueEnd
        label.isUserInteractionEnabled = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var onTap: (() -> Void)?
    private var onToggleDefault: ((Bool) -> Void)?
    private var onTapUseSavedLocation: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        contentView.addSubview(containerView)
        
        containerView.addSubview(locationIcon)
        containerView.addSubview(addressLabel)
        containerView.addSubview(chevronIcon)
        containerView.addSubview(defaultAddressLabel)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            
            locationIcon.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            locationIcon.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            locationIcon.widthAnchor.constraint(equalToConstant: 24),
            locationIcon.heightAnchor.constraint(equalToConstant: 24),
            
            addressLabel.leadingAnchor.constraint(equalTo: locationIcon.trailingAnchor, constant: 12),
            addressLabel.trailingAnchor.constraint(equalTo: chevronIcon.leadingAnchor, constant: -12),
            addressLabel.centerYAnchor.constraint(equalTo: locationIcon.centerYAnchor),
            
            chevronIcon.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            chevronIcon.centerYAnchor.constraint(equalTo: locationIcon.centerYAnchor),
            chevronIcon.widthAnchor.constraint(equalToConstant: 16),
            chevronIcon.heightAnchor.constraint(equalToConstant: 16),
            
            defaultAddressLabel.leadingAnchor.constraint(equalTo: locationIcon.leadingAnchor),
            defaultAddressLabel.topAnchor.constraint(equalTo: locationIcon.bottomAnchor, constant: 4),
            defaultAddressLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])
        
        // Tap gesture for address
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(addressTapped))
        containerView.addGestureRecognizer(tapGesture)
        containerView.isUserInteractionEnabled = true
        
        // Tap gesture for "Use saved location" - opens location list
        let useSavedLocationTap = UITapGestureRecognizer(target: self, action: #selector(useSavedLocationTapped))
        defaultAddressLabel.addGestureRecognizer(useSavedLocationTap)
    }
    
    func configure(
        address: Address?,
        useDefault: Bool,
        onTap: @escaping () -> Void,
        onToggleDefault: @escaping (Bool) -> Void,
        onTapUseSavedLocation: @escaping () -> Void
    ) {
        self.onTap = onTap
        self.onToggleDefault = onToggleDefault
        self.onTapUseSavedLocation = onTapUseSavedLocation
        
        if let address = address {
            addressLabel.text = address.address
        } else {
            addressLabel.text = "Add address"
        }
    }
    
    @objc private func addressTapped() {
        onTap?()
    }
    
    @objc private func useSavedLocationTapped() {
        // Open location list
        onTapUseSavedLocation?()
    }
}
