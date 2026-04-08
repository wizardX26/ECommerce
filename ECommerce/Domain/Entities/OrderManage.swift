//
//  OrderManage.swift
//  ECommerce
//
//  Created by wizard.os25 on 16/1/26.
//

import Foundation

public struct OrderManage {
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
    public let detailsCount: Int
    public let totalAmount: Double
    
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
        detailsCount: Int,
        totalAmount: Double
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
        self.detailsCount = detailsCount
        self.totalAmount = totalAmount
    }
}

public struct ShippingAddress: Equatable {
    public let contactPersonName: String
    public let contactPersonNumber: String
    public let addressDetail: String
    public let countryId: Int
    public let provinceId: Int
    public let districtId: Int
    public let wardId: Int
    
    public init(
        contactPersonName: String,
        contactPersonNumber: String,
        addressDetail: String,
        countryId: Int,
        provinceId: Int,
        districtId: Int,
        wardId: Int
    ) {
        self.contactPersonName = contactPersonName
        self.contactPersonNumber = contactPersonNumber
        self.addressDetail = addressDetail
        self.countryId = countryId
        self.provinceId = provinceId
        self.districtId = districtId
        self.wardId = wardId
    }
}
