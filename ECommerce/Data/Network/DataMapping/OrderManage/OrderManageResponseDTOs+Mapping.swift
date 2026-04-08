//
//  OrderManageResponseDTOs+Mapping.swift
//  ECommerce
//
//  Created by wizard.os25 on 16/1/26.
//

import Foundation

// MARK: - API Response Wrapper

struct OrderManageResponseDTO: Decodable {
    let statusCode: Int
    let success: Bool
    let message: String
    let data: [OrderManageDataDTO]
    
    enum CodingKeys: String, CodingKey {
        case statusCode
        case success
        case message
        case data
    }
}

// MARK: - Order Data DTO

struct OrderManageDataDTO: Decodable {
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
    let detailsCount: Int
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
        case detailsCount = "details_count"
        case totalAmount = "total_amount"
    }
}

// MARK: - Shipping Address DTO

struct ShippingAddressDTO: Decodable {
    let contactPersonName: String
    let contactPersonNumber: String
    let addressDetail: String
    let countryId: Int
    let provinceId: Int
    let districtId: Int
    let wardId: Int
    
    enum CodingKeys: String, CodingKey {
        case contactPersonName = "contact_person_name"
        case contactPersonNumber = "contact_person_number"
        case addressDetail = "address_detail"
        case countryId = "country_id"
        case provinceId = "province_id"
        case districtId = "district_id"
        case wardId = "ward_id"
    }
}

// MARK: - Mappings to Domain

extension OrderManageDataDTO {
    func toDomain() -> OrderManage {
        return OrderManage(
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
            detailsCount: detailsCount,
            totalAmount: totalAmount
        )
    }
}

extension ShippingAddressDTO {
    func toDomain() -> ShippingAddress {
        return ShippingAddress(
            contactPersonName: contactPersonName,
            contactPersonNumber: contactPersonNumber,
            addressDetail: addressDetail,
            countryId: countryId,
            provinceId: provinceId,
            districtId: districtId,
            wardId: wardId
        )
    }
}
