//
//  StoreItemCell.swift
//  MyKiot
//
//  Created by Nguyen Duc Hung on 18/6/25.
//

import UIKit

class GroceryItemCell: UICollectionViewCell {
    
    @IBOutlet weak var storeContentView: UIView!
    @IBOutlet weak var storeAvatarImageView: UIImageView!
    
    @IBOutlet weak var storeGuaranteedImageView: UIImageView!
    @IBOutlet weak var storeTitleLabel: UILabel!
    @IBOutlet weak var storeInfoLabel: UILabel!
    @IBOutlet weak var storeSubTitleLabel: UILabel!
    
    @IBOutlet weak var storeProductStackView: UIStackView!
    
    @IBOutlet weak var leftProductView: UIView!
    @IBOutlet weak var leftProductImageView: UIImageView!
    @IBOutlet weak var leftProductTitleLabel: UILabel!
    @IBOutlet weak var leftProductPrice: UILabel!
    
    @IBOutlet weak var centerProductView: UIView!
    @IBOutlet weak var centerProductImageView: UIImageView!
    @IBOutlet weak var centerProductTitleLabel: UILabel!
    @IBOutlet weak var centerProductPrice: UILabel!
    
    @IBOutlet weak var rightProductView: UIView!
    @IBOutlet weak var rightProductImageView: UIImageView!
    @IBOutlet weak var rightProductTitleLabel: UILabel!
    @IBOutlet weak var rightProductPrice: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func configure(with product: Product) {
        self.layoutIfNeeded()
        
        self.storeAvatarImageView.contentMode = .scaleAspectFill
        self.storeAvatarImageView.clipsToBounds = true
        
        self.storeGuaranteedImageView.contentMode = .scaleAspectFill
        self.storeGuaranteedImageView.clipsToBounds = true
        
        self.leftProductImageView.contentMode = .scaleAspectFill
        self.leftProductImageView.layer.cornerRadius = 4
        self.leftProductImageView.clipsToBounds = true
        
        self.centerProductImageView.contentMode = .scaleAspectFill
        self.centerProductImageView.layer.cornerRadius = 4
        self.centerProductImageView.clipsToBounds = true
        
        self.rightProductImageView.contentMode = .scaleAspectFill
        self.rightProductImageView.layer.cornerRadius = 4
        self.rightProductImageView.clipsToBounds = true
        
        self.storeContentView.layer.borderWidth = 1
        self.storeContentView.layer.borderColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        
        self.storeTitleLabel.text = product.name
//        self.storeInfoLabel.text = "\(product.price) • \(product.stars) • \(product.location)"
//        self.storeSubTitleLabel.text = "\(product.createdAt) || (\(product.updatedAt)"
        
        self.leftProductTitleLabel.text = product.name
        self.leftProductPrice.text = "\(product.price)"
        
        self.centerProductTitleLabel.text = product.name
        self.centerProductPrice.text = "\(product.price) $"
        
        self.rightProductTitleLabel.text = product.name
        self.rightProductPrice.text = "\(product.price)"
    }
}
