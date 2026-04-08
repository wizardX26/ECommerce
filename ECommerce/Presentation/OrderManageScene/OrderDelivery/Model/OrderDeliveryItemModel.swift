//
//  OrderDeliveryItemModel.swift
//  ECommerce
//
//  Created by wizard.os25 on 16/1/26.
//

import Foundation

struct OrderDeliveryItemModel: Equatable {
    let id: Int
    let paymentMethod: String?
    let totalAmount: Double
    let createdAt: String
}

extension OrderDeliveryItemModel {
    init(orderManage: OrderManage) {
        self.id = orderManage.id
        self.paymentMethod = orderManage.paymentMethod
        self.totalAmount = orderManage.totalAmount
        self.createdAt = orderManage.createdAt
    }
    
    // Format date to user-friendly string
    var formattedDate: String {
        // Parse ISO8601 date format: "2026-01-16T11:20:09.000000Z"
        let inputFormatter = ISO8601DateFormatter()
        inputFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = inputFormatter.date(from: createdAt) else {
            return createdAt // Return original if parsing fails
        }
        
        // Format to user-friendly: "Jan 16, 2026 at 11:20 AM"
        let outputFormatter = DateFormatter()
        outputFormatter.locale = Locale(identifier: "en_US")
        outputFormatter.dateStyle = .medium
        outputFormatter.timeStyle = .short
        return outputFormatter.string(from: date)
    }
    
    // Format payment method to user-friendly string
    var formattedPaymentMethod: String {
        guard let method = paymentMethod, !method.isEmpty else {
            return "N/A"
        }
        // Capitalize first letter and make it readable
        return method.capitalized
    }
    
    // Format total amount to currency string - bỏ .00 khi không cần
    var formattedTotalAmount: String {
        let formatted = totalAmount.formattedWithSeparatorWithoutTrailingZeros
        return "\(formatted) VND"
    }
}
