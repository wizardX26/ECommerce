//
//  AddressRequestDTO+Mapping.swift
//  ECommerce
//
//  Created by wizard.os25 on 11/1/26.
//

import Foundation

struct AddressRequestDTO: Encodable {
    let contactPersonName: String
    let contactPersonNumber: String
    let addressDetail: String
    let countryId: Int
    let provinceId: Int
    let districtId: Int
    let wardId: Int
    let addressType: String
    let defaultShipping: Bool
    
    enum CodingKeys: String, CodingKey {
        case contactPersonName = "contact_person_name"
        case contactPersonNumber = "contact_person_number"
        case addressDetail = "address_detail"
        case countryId = "country_id"
        case provinceId = "province_id"
        case districtId = "district_id"
        case wardId = "ward_id"
        case addressType = "address_type"
        case defaultShipping = "default_shipping"
    }
}
