//
//  OrderDetailProductCell.swift
//  ECommerce
//
//  Created by wizard.os25 on 16/1/26.
//

import UIKit

final class OrderDetailProductCell: UITableViewCell {
    
    @IBOutlet weak var productImageView: UIImageView!
    @IBOutlet weak var orderIdLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var quantityLabel: UILabel!
    
    private let imageCache = DefaultImageCacheService.shared
    private var currentImageUrl: String?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        productImageView?.contentMode = .scaleAspectFill
        productImageView?.clipsToBounds = true
        productImageView?.layer.cornerRadius = 8
        descriptionLabel?.numberOfLines = 3
    }
    
    func fill(with detailItem: OrderDetailItem) {
        // Order ID - Convert Int to String để tránh crash
        orderIdLabel?.text = String(format: "order_number".localized(), "\(detailItem.orderId)")
        
        // Price - Format bỏ .00 khi không cần
        let priceValue = Double(detailItem.foodDetails.price) ?? 0.0
        let formattedPrice = priceValue.formattedWithSeparatorWithoutTrailingZeros
        priceLabel?.text = "\(formattedPrice) VND"
        
        // Name
        nameLabel?.text = detailItem.foodDetails.name
        
        // Description (max 3 lines)
        descriptionLabel?.text = detailItem.foodDetails.description
        
        // Quantity - Convert Int to String để tránh crash
        quantityLabel?.text = String(format: "quantity_label".localized(), "\(detailItem.quantity)")
        
        // Load image
        if let imgUrl = detailItem.foodDetails.img {
            loadImage(from: imgUrl)
        } else {
            productImageView?.image = nil
            productImageView?.backgroundColor = .systemGray5
        }
    }
    
    private func loadImage(from urlString: String) {
        currentImageUrl = urlString
        
        // Show placeholder
        productImageView?.backgroundColor = .systemGray5
        
        // Ghép thêm /uploads vào URL path
        let urlWithUploads = addUploadsPath(to: urlString)
        
        // Get full URL
        guard let fullURLString = urlWithUploads.fullImageURL(),
              let url = URL(string: fullURLString) else {
            productImageView?.image = nil
            return
        }
        
        // Load image using ImageCache
        imageCache.loadImage(from: url) { [weak self] image in
            guard let self = self else { return }
            // Only update if cell hasn't been reused
            if self.currentImageUrl == urlString {
                self.productImageView?.image = image
                self.productImageView?.backgroundColor = nil
            }
        }
    }
    
    /// Ghép thêm /uploads vào URL path
    /// - Parameter urlString: URL string gốc (ví dụ: "images/abc.jpg")
    /// - Returns: URL string đã được ghép /uploads (ví dụ: "/uploads/images/abc.jpg")
    private func addUploadsPath(to urlString: String) -> String {
        // Nếu đã là full URL, không xử lý
        if urlString.hasPrefix("http://") || urlString.hasPrefix("https://") {
            return urlString
        }
        
        // Loại bỏ leading slash nếu có
        let cleanPath = urlString.hasPrefix("/") ? String(urlString.dropFirst()) : urlString
        
        // Ghép /uploads vào đầu path
        return "uploads/\(cleanPath)"
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        currentImageUrl = nil
        productImageView?.image = nil
        productImageView?.backgroundColor = .systemGray5
        orderIdLabel?.text = nil
        priceLabel?.text = nil
        nameLabel?.text = nil
        descriptionLabel?.text = nil
        quantityLabel?.text = nil
    }
}
