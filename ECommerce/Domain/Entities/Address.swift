//
//  Address.swift
//  ECommerce
//
//  Created by wizard.os25 on 11/1/26.
//

import Foundation

public struct Address: Identifiable {
    public typealias Identifier = Int
    
    public let id: Identifier
    public let userId: Int
    public let contactPersonName: String
    public let contactPersonNumber: String
    public let address: String
    public let addressDetail: String
    public let addressType: String
    public let zoneId: Int?
    public let countryId: Int
    public let provinceId: Int
    public let districtId: Int
    public let wardId: Int
    public let longitude: String
    public let latitude: String
    public let shippingFee: String?
    public let createdAt: Date?
    public let updatedAt: Date?
    public let isDefault: Bool
    
    public init(
        id: Identifier,
        userId: Int,
        contactPersonName: String,
        contactPersonNumber: String,
        address: String,
        addressDetail: String,
        addressType: String,
        zoneId: Int?,
        countryId: Int,
        provinceId: Int,
        districtId: Int,
        wardId: Int,
        longitude: String,
        latitude: String,
        shippingFee: String?,
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        isDefault: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.contactPersonName = contactPersonName
        self.contactPersonNumber = contactPersonNumber
        self.address = address
        self.addressDetail = addressDetail
        self.addressType = addressType
        self.zoneId = zoneId
        self.countryId = countryId
        self.provinceId = provinceId
        self.districtId = districtId
        self.wardId = wardId
        self.longitude = longitude
        self.latitude = latitude
        self.shippingFee = shippingFee
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isDefault = isDefault
    }
}
