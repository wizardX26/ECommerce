//
//  ProductImageCell.swift
//  ECommerce
//
//  Created by wizard.os25 on 14/1/26.
//

import UIKit

final class ProductImageCell: UICollectionViewCell {
    
    static let reuseIdentifierProductImage = String(describing: ProductImageCell.self)
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .systemGray5
        return iv
    }()
    
    private let imageCoverView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.alpha = 0.3
        return view
    }()
    
    private let imageCache = DefaultImageCacheService.shared
    
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
        contentView.addSubview(imageView)
        contentView.addSubview(imageCoverView)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageCoverView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            imageCoverView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageCoverView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageCoverView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageCoverView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    // MARK: - Configuration
    
    func configure(with product: ProductDetailModel) {
        if let imageUrl = product.imageUrl {
            loadImage(from: imageUrl, blurhash: product.imageBlurhash)
        } else {
            imageView.image = nil
            imageView.backgroundColor = .systemGray5
        }
    }
    
    private func loadImage(from urlString: String, blurhash: String?) {
        // Show blurhash placeholder if available
        if let blurhash = blurhash {
            // TODO: Decode blurhash to UIImage placeholder
            imageView.backgroundColor = UIColor.systemGray5
        } else {
            imageView.image = nil
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
                self.imageView.image = image
                self.imageView.backgroundColor = nil
            }
        }
    }
    
    // MARK: - Scroll Effect
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        
        let standardHeight = UltravisualLayoutConstants.Cell.standardHeight
        
        // Tính toán featuredHeight từ collectionView height (nửa màn hình)
        var featuredHeight: CGFloat = UIScreen.main.bounds.height / 2
        
        var view: UIView? = self.superview
        while view != nil {
            if let collectionView = view as? UICollectionView {
                featuredHeight = collectionView.bounds.height / 2
                break
            }
            view = view?.superview
        }
        
        let heightDifference = featuredHeight - standardHeight
        guard heightDifference > 0 else {
            return
        }
        
        // delta = 1 khi cell expanded, delta = 0 khi cell collapsed
        let delta = 1 - ((featuredHeight - frame.height) / heightDifference)
        
        // Hiệu ứng alpha cho imageCoverView
        let minAlpha: CGFloat = 0.3
        let maxAlpha: CGFloat = 0.75
        imageCoverView.alpha = maxAlpha - (delta * (maxAlpha - minAlpha))
    }
}
