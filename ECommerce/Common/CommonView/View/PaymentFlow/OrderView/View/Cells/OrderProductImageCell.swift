//
//  OrderProductImageCell.swift
//  ECommerce
//
//  Created by wizard.os25 on 14/1/26.
//

import UIKit

final class OrderProductImageCell: UITableViewCell {
        
    private let productImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray5
        imageView.layer.cornerRadius = BorderRadius.tokenBorderRadius12
        imageView.layer.masksToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = Typography.fontBold18
        label.textColor = Colors.tokenDark100
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = Typography.fontRegular14
        label.textColor = Colors.tokenDark60
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let imageCache = DefaultImageCacheService.shared
    private var product: ProductDetailModel?
    
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
        
        contentView.addSubview(productImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(descriptionLabel)
        
        NSLayoutConstraint.activate([
            // Product Image - left side 64x64
            productImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.tokenSpacing22),
            productImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Spacing.tokenSpacing16),
            productImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Spacing.tokenSpacing16),
            productImageView.widthAnchor.constraint(equalToConstant: 64),
            productImageView.heightAnchor.constraint(equalToConstant: 64),
            
            // Title Label - right side of image
            titleLabel.leadingAnchor.constraint(equalTo: productImageView.trailingAnchor, constant: Spacing.tokenSpacing16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.tokenSpacing16),
            titleLabel.topAnchor.constraint(equalTo: productImageView.topAnchor),
            
            // Description Label - below title
            descriptionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: Spacing.tokenSpacing08),
            descriptionLabel.bottomAnchor.constraint(lessThanOrEqualTo: productImageView.bottomAnchor)
        ])
    }
    
    // MARK: - Configuration
    
    func configure(with product: ProductDetailModel?) {
        self.product = product
        
        guard let product = product else {
            productImageView.image = nil
            productImageView.backgroundColor = .systemGray5
            titleLabel.text = nil
            descriptionLabel.text = nil
            return
        }
        
        // Set title and description
        titleLabel.text = product.name
        descriptionLabel.text = product.description
        
        if let imageUrl = product.imageUrl {
            loadImage(from: imageUrl, blurhash: product.imageBlurhash)
        } else {
            productImageView.image = nil
            productImageView.backgroundColor = .systemGray5
        }
    }
    
    private func loadImage(from urlString: String, blurhash: String?) {
        // Show blurhash placeholder if available
        if let blurhash = blurhash {
            productImageView.backgroundColor = UIColor.systemGray5
        } else {
            productImageView.image = nil
        }
        
        // Sử dụng helper function để ghép URL
        guard let fullURLString = urlString.fullImageURL(),
              let url = URL(string: fullURLString) else {
            return
        }
        
        // Load image using ImageCache service
        imageCache.loadImage(from: url) { [weak self] image in
            guard let self = self else { return }
            DispatchQueue.main.async {
                // Only update if cell hasn't been reused
                if self.product?.imageUrl == urlString {
                    self.productImageView.image = image
                    self.productImageView.backgroundColor = nil
                }
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        productImageView.image = nil
        productImageView.backgroundColor = .systemGray5
        titleLabel.text = nil
        descriptionLabel.text = nil
        product = nil
    }
}
