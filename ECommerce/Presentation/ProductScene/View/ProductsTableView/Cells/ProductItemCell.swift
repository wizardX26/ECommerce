//
//  ProductItemCell.swift
//  ExampleMVVM
//
//  Created by wizard.os25 on 14/11/25.
//

import UIKit

final class ProductItemCell: UITableViewCell {

    static let height = CGFloat(130)
    
    @IBOutlet private var nameLabel: UILabel!
    @IBOutlet private var priceLabel: UILabel!
    @IBOutlet private var locationLabel: UILabel!
    @IBOutlet private var descriptionLabel: UILabel!
    @IBOutlet private var productImageView: UIImageView!
    @IBOutlet private var starsLabel: UILabel!
    
    private var items: ProductItemModel?
    private let imageCache = DefaultImageCacheService.shared
    
    override func awakeFromNib() {
        super.awakeFromNib()
        descriptionLabel.numberOfLines = 5
        descriptionLabel.lineBreakMode = .byTruncatingTail
    }
    
    func fill(with items: ProductItemModel) {
        self.items = items
        
        nameLabel.text = items.name
        priceLabel.text = "\(items.price) vnd"
        locationLabel.text = items.location
        descriptionLabel.text = items.description
        
        if let stars = items.stars {
            starsLabel.text = String(repeating: "⭐", count: stars)
        } else {
            starsLabel.text = ""
        }
        
        // Load image if URL is available
        if let imageUrl = items.imageUrl {
            loadImage(from: imageUrl, blurhash: items.imageBlurhash)
        } else {
            productImageView.image = nil
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // Reset image when cell is reused
        productImageView.image = nil
        productImageView.backgroundColor = nil
    }
    
    private func loadImage(from urlString: String, blurhash: String?) {
        // Show blurhash placeholder if available
        if let blurhash = blurhash {
            // TODO: Decode blurhash to UIImage placeholder
            // For now, show a placeholder color
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
            // Only update if cell hasn't been reused
            if self.items?.imageUrl == urlString {
                self.productImageView.image = image
                self.productImageView.backgroundColor = nil
            }
        }
    }
}
