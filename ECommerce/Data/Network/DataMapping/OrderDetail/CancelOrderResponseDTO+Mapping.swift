//
//  CancelOrderResponseDTO+Mapping.swift
//  ECommerce
//
//  Created by wizard.os25 on 16/1/26.
//

import Foundation

// MARK: - API Response Wrapper

struct CancelOrderResponseWrapperDTO: Decodable {
    let statusCode: Int
    let success: Bool
    let message: String
    let data: CancelOrderDataDTO
    
    enum CodingKeys: String, CodingKey {
        case statusCode
        case success
        case message
        case data
    }
}

// MARK: - Cancel Order Data DTO

struct CancelOrderDataDTO: Decodable {
    let order: CancelOrderDTO
    let message: String
}

// MARK: - Cancel Order DTO

struct CancelOrderDTO: Decodable {
    let id: Int
    let userId: Int
    let orderAmount: Double
    let shippingFee: Double
    let paymentStatus: String
    let paymentMethod: String?
    let transactionReference: String?
    let orderStatus: String
    let confirmed: String?
    let accepted: String?
    let scheduled: Int
    let outForDelivery: String?
    let processing: String?
    let handover: String?
    let failed: String?
    let scheduledAt: String?
    let deliveryAddressId: Int
    let orderNote: String?
    let createdAt: String
    let updatedAt: String
    let deliveryCharge: Double?
    let shippingAddress: ShippingAddressDTO
    let otp: String?
    let pending: String?
    let pickedUp: String?
    let delivered: String?
    let canceled: String?
    let totalAmount: Double
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case orderAmount = "order_amount"
        case shippingFee = "shipping_fee"
        case paymentStatus = "payment_status"
        case paymentMethod = "payment_method"
        case transactionReference = "transaction_reference"
        case orderStatus = "order_status"
        case confirmed
        case accepted
        case scheduled
        case outForDelivery = "out_for_delivery"
        case processing
        case handover
        case failed
        case scheduledAt = "scheduled_at"
        case deliveryAddressId = "delivery_address_id"
        case orderNote = "order_note"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deliveryCharge = "delivery_charge"
        case shippingAddress = "shipping_address"
        case otp
        case pending
        case pickedUp = "picked_up"
        case delivered
        case canceled
        case totalAmount = "total_amount"
    }
}

// MARK: - Cancel Order Response DTO

struct CancelOrderResponseDTO: Decodable {
    let message: String
    
    init(from decoder: Decoder) throws {
        let wrapper = try CancelOrderResponseWrapperDTO(from: decoder)
        self.message = wrapper.data.message
    }
}
