//
//  ProductDetailModel.swift
//  ECommerce
//
//  Created by wizard.os25 on 14/1/26.
//

import Foundation

struct ProductDetailModel {
    let id: Int
    let name: String
    let description: String
    let price: String
    let stars: Int?
    let location: String
    let imageUrl: String?
    let imageBlurhash: String?
    let soldCount: Int? // Số lượng đã bán
    let sellerName: String? // Tên người bán
    let sellerImageUrl: String? // Ảnh người bán
}

extension ProductDetailModel {
    init(productItem: ProductItemModel) {
        self.id = productItem.id
        self.name = productItem.name
        self.description = productItem.description
        self.price = productItem.price
        self.stars = productItem.stars
        self.location = productItem.location
        self.imageUrl = productItem.imageUrl
        self.imageBlurhash = productItem.imageBlurhash
        // Default values - có thể update sau từ API
        self.soldCount = 100 // Default 100+
        self.sellerName = "Seller" // Default seller name
        self.sellerImageUrl = nil
    }
}
