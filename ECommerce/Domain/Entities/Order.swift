//
//  Order.swift
//  ECommerce
//
//  Created by wizard.os25 on 14/1/26.
//

import Foundation

public struct CartItem {
    public let id: Int
    public let quantity: Int
    
    public init(id: Int, quantity: Int) {
        self.id = id
        self.quantity = quantity
    }
}

public struct Order {
    public let orderId: Int
    public let orderAmount: Double
    public let shippingFee: Double
    public let totalAmount: Double
    
    public init(orderId: Int, orderAmount: Double, shippingFee: Double, totalAmount: Double) {
        self.orderId = orderId
        self.orderAmount = orderAmount
        self.shippingFee = shippingFee
        self.totalAmount = totalAmount
    }
}
