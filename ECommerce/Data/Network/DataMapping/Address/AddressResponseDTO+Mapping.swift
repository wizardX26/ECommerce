//
//  AddressResponseDTO+Mapping.swift
//  ECommerce
//
//  Created by wizard.os25 on 11/1/26.
//

import Foundation

// MARK: - API Response Wrapper
struct AddressAPIResponseWrapper: Decodable {
    let statusCode: Int
    let success: Bool
    let message: String
    let data: AddressResponseDTOInternal?
    
    enum CodingKeys: String, CodingKey {
        case statusCode
        case success
        case message
        case data
    }
}

// MARK: - Internal DTO for decoding nested "data" structure
struct AddressResponseDTOInternal: Decodable {
    let id: Int
    let userId: Int
    let contactPersonName: String
    let contactPersonNumber: String
    let address: String?
    let addressDetail: String
    let addressType: String
    let zoneId: Int?
    let countryId: Int
    let provinceId: Int
    let districtId: Int
    let wardId: Int
    let longitude: String?
    let latitude: String?
    let defaultShipping: Bool
    let shippingFee: String?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case contactPersonName = "contact_person_name"
        case contactPersonNumber = "contact_person_number"
        case address
        case addressDetail = "address_detail"
        case addressType = "address_type"
        case zoneId = "zone_id"
        case countryId = "country_id"
        case provinceId = "province_id"
        case districtId = "district_id"
        case wardId = "ward_id"
        case longitude
        case latitude
        case defaultShipping = "default_shipping"
        case shippingFee = "shipping_fee"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // Custom decoder for shippingFee to handle both String and Number
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        userId = try container.decode(Int.self, forKey: .userId)
        contactPersonName = try container.decode(String.self, forKey: .contactPersonName)
        contactPersonNumber = try container.decode(String.self, forKey: .contactPersonNumber)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        addressDetail = try container.decode(String.self, forKey: .addressDetail)
        addressType = try container.decode(String.self, forKey: .addressType)
        zoneId = try container.decodeIfPresent(Int.self, forKey: .zoneId)
        countryId = try container.decode(Int.self, forKey: .countryId)
        provinceId = try container.decode(Int.self, forKey: .provinceId)
        districtId = try container.decode(Int.self, forKey: .districtId)
        wardId = try container.decode(Int.self, forKey: .wardId)
        longitude = try container.decodeIfPresent(String.self, forKey: .longitude)
        latitude = try container.decodeIfPresent(String.self, forKey: .latitude)
        defaultShipping = try container.decode(Bool.self, forKey: .defaultShipping)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
        
        // Handle shippingFee as either String or Number
        if let shippingFeeString = try? container.decode(String.self, forKey: .shippingFee) {
            shippingFee = shippingFeeString
        } else if let shippingFeeDouble = try? container.decode(Double.self, forKey: .shippingFee) {
            shippingFee = String(shippingFeeDouble)
        } else if let shippingFeeInt = try? container.decode(Int.self, forKey: .shippingFee) {
            shippingFee = String(shippingFeeInt)
        } else {
            shippingFee = nil
        }
    }
}

// MARK: - AddressResponseDTO - main DTO used by Endpoint<AddressResponseDTO>
struct AddressResponseDTO: Decodable {
    let id: Int
    let userId: Int
    let contactPersonName: String
    let contactPersonNumber: String
    let address: String
    let addressDetail: String
    let addressType: String
    let zoneId: Int?
    let countryId: Int
    let provinceId: Int
    let districtId: Int
    let wardId: Int
    let longitude: String?
    let latitude: String?
    let defaultShipping: Bool
    let shippingFee: String?
    let createdAt: String
    let updatedAt: String
    
    // Init from decoder (API response)
    init(from decoder: Decoder) throws {
        // Decode the wrapper first to extract "data" key
        let wrapper = try AddressAPIResponseWrapper(from: decoder)
        guard let data = wrapper.data else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Address response data is nil"
                )
            )
        }
        
        // Extract values from data
        self.id = data.id
        self.userId = data.userId
        self.contactPersonName = data.contactPersonName
        self.contactPersonNumber = data.contactPersonNumber
        self.address = data.address ?? data.addressDetail // Use address if available, fallback to addressDetail
        self.addressDetail = data.addressDetail
        self.addressType = data.addressType
        self.zoneId = data.zoneId
        self.countryId = data.countryId
        self.provinceId = data.provinceId
        self.districtId = data.districtId
        self.wardId = data.wardId
        self.longitude = data.longitude
        self.latitude = data.latitude
        self.defaultShipping = data.defaultShipping
        self.shippingFee = data.shippingFee
        self.createdAt = data.createdAt
        self.updatedAt = data.updatedAt
    }
    
    // Init for manual creation
    init(
        id: Int,
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
        longitude: String?,
        latitude: String?,
        defaultShipping: Bool,
        shippingFee: String?,
        createdAt: String,
        updatedAt: String
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
        self.defaultShipping = defaultShipping
        self.shippingFee = shippingFee
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Mappings to Domain

extension AddressResponseDTO {
    func toDomain() -> Address {
        // Parse dates from ISO8601 string format
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        return Address(
            id: id,
            userId: userId,
            contactPersonName: contactPersonName,
            contactPersonNumber: contactPersonNumber,
            address: address,
            addressDetail: addressDetail,
            addressType: addressType,
            zoneId: zoneId,
            countryId: countryId,
            provinceId: provinceId,
            districtId: districtId,
            wardId: wardId,
            longitude: longitude ?? "",
            latitude: latitude ?? "",
            shippingFee: shippingFee,
            createdAt: dateFormatter.date(from: createdAt),
            updatedAt: dateFormatter.date(from: updatedAt),
            isDefault: defaultShipping
        )
    }
}
