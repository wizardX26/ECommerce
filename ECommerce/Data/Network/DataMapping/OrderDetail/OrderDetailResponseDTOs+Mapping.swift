//
//  OrderDetailResponseDTOs+Mapping.swift
//  ECommerce
//
//  Created by wizard.os25 on 16/1/26.
//

import Foundation

// MARK: - API Response Wrapper

struct OrderDetailResponseDTO: Decodable {
    let statusCode: Int
    let success: Bool
    let message: String
    let data: OrderDetailDataDTO
    
    enum CodingKeys: String, CodingKey {
        case statusCode
        case success
        case message
        case data
    }
}

// MARK: - Order Detail Data DTO

struct OrderDetailDataDTO: Decodable {
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
    let details: [OrderDetailItemDTO]
    
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
        case details
    }
}

// MARK: - Order Detail Item DTO

struct OrderDetailItemDTO: Decodable {
    let id: Int
    let orderId: Int
    let foodId: Int
    let price: Double
    let quantity: Int
    let taxAmount: Double
    let createdAt: String
    let updatedAt: String
    let foodDetails: FoodDetailsDTO
    
    enum CodingKeys: String, CodingKey {
        case id
        case orderId = "order_id"
        case foodId = "food_id"
        case price
        case quantity
        case taxAmount = "tax_amount"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case foodDetails = "food_details"
    }
}

// MARK: - Food Details DTO

struct FoodDetailsDTO: Decodable {
    let id: Int
    let name: String
    let description: String
    let price: String
    let stars: String?
    let people: Int?
    let selectedPeople: Int?
    let img: String?
    let blurhash: String?
    let location: String?
    let createdAt: String?
    let updatedAt: String?
    let typeId: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case price
        case stars
        case people
        case selectedPeople = "selected_people"
        case img
        case blurhash
        case location
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case typeId = "type_id"
    }
}

// MARK: - Mappings to Domain

extension OrderDetailDataDTO {
    func toDomain() -> OrderDetail {
        return OrderDetail(
            id: id,
            userId: userId,
            orderAmount: orderAmount,
            shippingFee: shippingFee,
            paymentStatus: paymentStatus,
            paymentMethod: paymentMethod,
            transactionReference: transactionReference,
            orderStatus: orderStatus,
            confirmed: confirmed,
            accepted: accepted,
            scheduled: scheduled,
            outForDelivery: outForDelivery,
            processing: processing,
            handover: handover,
            failed: failed,
            scheduledAt: scheduledAt,
            deliveryAddressId: deliveryAddressId,
            orderNote: orderNote,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deliveryCharge: deliveryCharge,
            shippingAddress: shippingAddress.toDomain(),
            otp: otp,
            pending: pending,
            pickedUp: pickedUp,
            delivered: delivered,
            canceled: canceled,
            totalAmount: totalAmount,
            details: details.map { $0.toDomain() }
        )
    }
}

extension OrderDetailItemDTO {
    func toDomain() -> OrderDetailItem {
        return OrderDetailItem(
            id: id,
            orderId: orderId,
            foodId: foodId,
            price: price,
            quantity: quantity,
            taxAmount: taxAmount,
            createdAt: createdAt,
            updatedAt: updatedAt,
            foodDetails: foodDetails.toDomain()
        )
    }
}

extension FoodDetailsDTO {
    func toDomain() -> FoodDetails {
        return FoodDetails(
            id: id,
            name: name,
            description: description,
            price: price,
            stars: stars,
            people: people,
            selectedPeople: selectedPeople,
            img: img,
            blurhash: blurhash,
            location: location,
            createdAt: createdAt,
            updatedAt: updatedAt,
            typeId: typeId
        )
    }
}
