//
//  CheckoutModel.swift
//  ECommerce
//
//  Created by wizard.os25 on 15/1/26.
//

import Foundation

// MARK: - Checkout Models

struct CheckoutCartItem {
    let productId: Int
    let productName: String
    let productImageUrl: String?
    let price: String
    var quantity: Int
    
    init(productId: Int, productName: String, productImageUrl: String?, price: String, quantity: Int) {
        self.productId = productId
        self.productName = productName
        self.productImageUrl = productImageUrl
        self.price = price
        self.quantity = quantity
    }
}

struct OrderSummary {
    let subtotal: Double
    let shippingFee: Double
    let total: Double
}

enum CheckoutStep: Int {
    case placeOrder = 0
    case createCustomer = 1
    case createPayment = 2
    case complete = 3
}

enum PaymentMethod {
    case addNewCard
    case chooseCard
    case other
}
