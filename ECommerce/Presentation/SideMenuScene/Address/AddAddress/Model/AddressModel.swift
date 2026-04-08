//
//  AddressModel.swift
//  ECommerce
//
//  Created by wizard.os25 on 11/1/26.
//

import Foundation

// MARK: - Address Form Model (Presentation Layer)
// Only contains information needed for the Address screen form

public struct AddressFormModel {
    public var contactPersonName: String
    public var contactPersonNumber: String
    public var addressDetail: String
    public var countryId: Int
    public var provinceId: Int
    public var districtId: Int
    public var wardId: Int
    public var addressType: String
    public var isDefault: Bool
    
    public init(
        contactPersonName: String = "",
        contactPersonNumber: String = "",
        addressDetail: String = "",
        countryId: Int = 1, // Default: Việt Nam
        provinceId: Int = 2, // Default: Hà Nội
        districtId: Int = 0,
        wardId: Int = 0,
        addressType: String = "shipping",
        isDefault: Bool = false
    ) {
        self.contactPersonName = contactPersonName
        self.contactPersonNumber = contactPersonNumber
        self.addressDetail = addressDetail
        self.countryId = countryId
        self.provinceId = provinceId
        self.districtId = districtId
        self.wardId = wardId
        self.addressType = addressType
        self.isDefault = isDefault
    }
    
    public var isValid: Bool {
        return !contactPersonName.isEmpty &&
               !contactPersonNumber.isEmpty &&
               !addressDetail.isEmpty &&
               countryId > 0 &&
               provinceId > 0 &&
               districtId > 0 &&
               wardId > 0
    }
}
