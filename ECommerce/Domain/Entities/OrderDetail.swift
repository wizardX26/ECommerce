//
//  OrderDetail.swift
//  ECommerce
//
//  Created by wizard.os25 on 16/1/26.
//

import Foundation

public struct OrderDetail {
    public let id: Int
    public let userId: Int
    public let orderAmount: Double
    public let shippingFee: Double
    public let paymentStatus: String
    public let paymentMethod: String?
    public let transactionReference: String?
    public let orderStatus: String
    public let confirmed: String?
    public let accepted: String?
    public let scheduled: Int
    public let outForDelivery: String?
    public let processing: String?
    public let handover: String?
    public let failed: String?
    public let scheduledAt: String?
    public let deliveryAddressId: Int
    public let orderNote: String?
    public let createdAt: String
    public let updatedAt: String
    public let deliveryCharge: Double?
    public let shippingAddress: ShippingAddress
    public let otp: String?
    public let pending: String?
    public let pickedUp: String?
    public let delivered: String?
    public let canceled: String?
    public let totalAmount: Double
    public let details: [OrderDetailItem]
    
    public init(
        id: Int,
        userId: Int,
        orderAmount: Double,
        shippingFee: Double,
        paymentStatus: String,
        paymentMethod: String?,
        transactionReference: String?,
        orderStatus: String,
        confirmed: String?,
        accepted: String?,
        scheduled: Int,
        outForDelivery: String?,
        processing: String?,
        handover: String?,
        failed: String?,
        scheduledAt: String?,
        deliveryAddressId: Int,
        orderNote: String?,
        createdAt: String,
        updatedAt: String,
        deliveryCharge: Double?,
        shippingAddress: ShippingAddress,
        otp: String?,
        pending: String?,
        pickedUp: String?,
        delivered: String?,
        canceled: String?,
        totalAmount: Double,
        details: [OrderDetailItem]
    ) {
        self.id = id
        self.userId = userId
        self.orderAmount = orderAmount
        self.shippingFee = shippingFee
        self.paymentStatus = paymentStatus
        self.paymentMethod = paymentMethod
        self.transactionReference = transactionReference
        self.orderStatus = orderStatus
        self.confirmed = confirmed
        self.accepted = accepted
        self.scheduled = scheduled
        self.outForDelivery = outForDelivery
        self.processing = processing
        self.handover = handover
        self.failed = failed
        self.scheduledAt = scheduledAt
        self.deliveryAddressId = deliveryAddressId
        self.orderNote = orderNote
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deliveryCharge = deliveryCharge
        self.shippingAddress = shippingAddress
        self.otp = otp
        self.pending = pending
        self.pickedUp = pickedUp
        self.delivered = delivered
        self.canceled = canceled
        self.totalAmount = totalAmount
        self.details = details
    }
}

public struct OrderDetailItem {
    public let id: Int
    public let orderId: Int
    public let foodId: Int
    public let price: Double
    public let quantity: Int
    public let taxAmount: Double
    public let createdAt: String
    public let updatedAt: String
    public let foodDetails: FoodDetails
    
    public init(
        id: Int,
        orderId: Int,
        foodId: Int,
        price: Double,
        quantity: Int,
        taxAmount: Double,
        createdAt: String,
        updatedAt: String,
        foodDetails: FoodDetails
    ) {
        self.id = id
        self.orderId = orderId
        self.foodId = foodId
        self.price = price
        self.quantity = quantity
        self.taxAmount = taxAmount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.foodDetails = foodDetails
    }
}

public struct FoodDetails {
    public let id: Int
    public let name: String
    public let description: String
    public let price: String
    public let stars: String?
    public let people: Int?
    public let selectedPeople: Int?
    public let img: String?
    public let blurhash: String?
    public let location: String?
    public let createdAt: String?
    public let updatedAt: String?
    public let typeId: Int?
    
    public init(
        id: Int,
        name: String,
        description: String,
        price: String,
        stars: String?,
        people: Int?,
        selectedPeople: Int?,
        img: String?,
        blurhash: String?,
        location: String?,
        createdAt: String?,
        updatedAt: String?,
        typeId: Int?
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.price = price
        self.stars = stars
        self.people = people
        self.selectedPeople = selectedPeople
        self.img = img
        self.blurhash = blurhash
        self.location = location
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.typeId = typeId
    }
}
