//
//  LocationListResponseDTO+Mapping.swift
//  ECommerce
//
//  Created by wizard.os25 on 13/1/26.
//

import Foundation

// MARK: - API Response Wrapper
struct LocationListAPIResponseWrapper: Decodable {
    let statusCode: Int
    let success: Bool
    let message: String
    let data: [LocationListResponseDTOInternal]
    
    enum CodingKeys: String, CodingKey {
        case statusCode
        case success
        case message
        case data
    }
}

// MARK: - Internal DTO for decoding nested "data" structure
struct LocationListResponseDTOInternal: Decodable {
    let id: Int
    let addressType: String
    let contactPersonNumber: String
    let address: String?
    let addressDetail: String
    let latitude: String?
    let zoneId: Int?
    let longitude: String?
    let userId: Int
    let contactPersonName: String
    let countryId: Int
    let provinceId: Int
    let districtId: Int
    let wardId: Int
    let shippingFee: String?
    let createdAt: String
    let updatedAt: String
    let defaultShipping: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case addressType = "address_type"
        case contactPersonNumber = "contact_person_number"
        case address
        case addressDetail = "address_detail"
        case latitude
        case zoneId = "zone_id"
        case longitude
        case userId = "user_id"
        case contactPersonName = "contact_person_name"
        case countryId = "country_id"
        case provinceId = "province_id"
        case districtId = "district_id"
        case wardId = "ward_id"
        case shippingFee = "shipping_fee"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case defaultShipping = "default_shipping"
    }
    
    // Custom decoder for shippingFee to handle both String and Number
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        addressType = try container.decode(String.self, forKey: .addressType)
        contactPersonNumber = try container.decode(String.self, forKey: .contactPersonNumber)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        addressDetail = try container.decode(String.self, forKey: .addressDetail)
        latitude = try container.decodeIfPresent(String.self, forKey: .latitude)
        zoneId = try container.decodeIfPresent(Int.self, forKey: .zoneId)
        longitude = try container.decodeIfPresent(String.self, forKey: .longitude)
        userId = try container.decode(Int.self, forKey: .userId)
        contactPersonName = try container.decode(String.self, forKey: .contactPersonName)
        countryId = try container.decode(Int.self, forKey: .countryId)
        provinceId = try container.decode(Int.self, forKey: .provinceId)
        districtId = try container.decode(Int.self, forKey: .districtId)
        wardId = try container.decode(Int.self, forKey: .wardId)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
        defaultShipping = try container.decode(Bool.self, forKey: .defaultShipping)
        
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

// MARK: - LocationListResponseDTO - main DTO used by Endpoint<LocationListResponseDTO>
struct LocationListResponseDTO: Decodable {
    let addresses: [LocationListAddressDTO]
    
    // Init from decoder (API response)
    init(from decoder: Decoder) throws {
        // Decode the wrapper first to extract "data" array
        let wrapper = try LocationListAPIResponseWrapper(from: decoder)
        
        // Convert array of internal DTOs to array of address DTOs
        self.addresses = wrapper.data.map { internalDTO in
            LocationListAddressDTO(
                id: internalDTO.id,
                addressType: internalDTO.addressType,
                contactPersonNumber: internalDTO.contactPersonNumber,
                address: internalDTO.address ?? internalDTO.addressDetail,
                addressDetail: internalDTO.addressDetail,
                latitude: internalDTO.latitude,
                zoneId: internalDTO.zoneId,
                longitude: internalDTO.longitude,
                userId: internalDTO.userId,
                contactPersonName: internalDTO.contactPersonName,
                countryId: internalDTO.countryId,
                provinceId: internalDTO.provinceId,
                districtId: internalDTO.districtId,
                wardId: internalDTO.wardId,
                shippingFee: internalDTO.shippingFee,
                createdAt: internalDTO.createdAt,
                updatedAt: internalDTO.updatedAt,
                defaultShipping: internalDTO.defaultShipping
            )
        }
    }
    
    // Init for manual creation
    init(addresses: [LocationListAddressDTO]) {
        self.addresses = addresses
    }
}


// MARK: - LocationListAddressDTO
struct LocationListAddressDTO: Decodable {
    let id: Int
    let addressType: String
    let contactPersonNumber: String
    let address: String
    let addressDetail: String
    let latitude: String?
    let zoneId: Int?
    let longitude: String?
    let userId: Int
    let contactPersonName: String
    let countryId: Int
    let provinceId: Int
    let districtId: Int
    let wardId: Int
    let shippingFee: String?
    let createdAt: String
    let updatedAt: String
    let defaultShipping: Bool
}

// MARK: - Mappings to Domain
extension LocationListAddressDTO {
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
