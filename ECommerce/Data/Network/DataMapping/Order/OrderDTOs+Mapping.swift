//
//  OrderDTOs+Mapping.swift
//  ECommerce
//
//  Created by wizard.os25 on 14/1/26.
//

import Foundation

// MARK: - Place Order Request

struct PlaceOrderRequestDTO: Encodable {
    let cart: [CartItemDTO]
    let orderNote: String?
    
    // Option 1: Use saved address (delivery_address_id)
    let deliveryAddressId: Int?
    
    // Option 2: Use new address details
    let addressDetail: String?
    let countryId: Int?
    let provinceId: Int?
    let districtId: Int?
    let wardId: Int?
    let contactPersonName: String?
    let contactPersonNumber: String?
    
    init(
        cart: [CartItemDTO],
        orderNote: String?,
        deliveryAddressId: Int? = nil,
        addressDetail: String? = nil,
        countryId: Int? = nil,
        provinceId: Int? = nil,
        districtId: Int? = nil,
        wardId: Int? = nil,
        contactPersonName: String? = nil,
        contactPersonNumber: String? = nil
    ) {
        self.cart = cart
        self.orderNote = orderNote
        self.deliveryAddressId = deliveryAddressId
        self.addressDetail = addressDetail
        self.countryId = countryId
        self.provinceId = provinceId
        self.districtId = districtId
        self.wardId = wardId
        self.contactPersonName = contactPersonName
        self.contactPersonNumber = contactPersonNumber
    }
    
    enum CodingKeys: String, CodingKey {
        case cart
        case orderNote = "order_note"
        case deliveryAddressId = "delivery_address_id"
        case addressDetail = "address_detail"
        case countryId = "country_id"
        case provinceId = "province_id"
        case districtId = "district_id"
        case wardId = "ward_id"
        case contactPersonName = "contact_person_name"
        case contactPersonNumber = "contact_person_number"
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Always encode cart and orderNote
        try container.encode(cart, forKey: .cart)
        try container.encodeIfPresent(orderNote, forKey: .orderNote)
        
        // If deliveryAddressId is provided, only encode it (saved address)
        if let deliveryAddressId = deliveryAddressId {
            try container.encode(deliveryAddressId, forKey: .deliveryAddressId)
        } else {
            // Otherwise, encode address detail fields (new address)
            try container.encodeIfPresent(addressDetail, forKey: .addressDetail)
            try container.encodeIfPresent(countryId, forKey: .countryId)
            try container.encodeIfPresent(provinceId, forKey: .provinceId)
            try container.encodeIfPresent(districtId, forKey: .districtId)
            try container.encodeIfPresent(wardId, forKey: .wardId)
            try container.encodeIfPresent(contactPersonName, forKey: .contactPersonName)
            try container.encodeIfPresent(contactPersonNumber, forKey: .contactPersonNumber)
        }
    }
}

struct CartItemDTO: Encodable {
    let id: Int
    let quantity: Int
}

// MARK: - Place Order Response

struct PlaceOrderResponseDTO: Decodable {
    let statusCode: Int
    let success: Bool
    let message: String
    let data: PlaceOrderDataDTO
    
    enum CodingKeys: String, CodingKey {
        case statusCode
        case success
        case message
        case data
    }
}

struct PlaceOrderDataDTO: Decodable {
    let orderId: Int
    let orderAmount: Double
    let shippingFee: Double
    let totalAmount: Double
    
    enum CodingKeys: String, CodingKey {
        case orderId = "order_id"
        case orderAmount = "order_amount"
        case shippingFee = "shipping_fee"
        case totalAmount = "total_amount"
    }
}

// MARK: - Mappings to Domain

extension PlaceOrderDataDTO {
    func toDomain() -> Order {
        return Order(
            orderId: orderId,
            orderAmount: orderAmount,
            shippingFee: shippingFee,
            totalAmount: totalAmount
        )
    }
}
