//
//  CartModel.swift
//  ECommerce
//
//  Created by wizard.os25 on 17/1/26.
//

import Foundation

struct CartItemModel {
    let productId: Int
    let productName: String
    let productDescription: String
    let productImageUrl: String?
    let price: String
    var quantity: Int
    var isSelected: Bool
    
    init(
        productId: Int,
        productName: String,
        productDescription: String,
        productImageUrl: String?,
        price: String,
        quantity: Int,
        isSelected: Bool = true
    ) {
        self.productId = productId
        self.productName = productName
        self.productDescription = productDescription
        self.productImageUrl = productImageUrl
        self.price = price
        self.quantity = quantity
        self.isSelected = isSelected
    }
}
