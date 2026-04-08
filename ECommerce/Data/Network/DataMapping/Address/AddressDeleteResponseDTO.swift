//
//  AddressDeleteResponseDTO.swift
//  ECommerce
//
//  Created by wizard.os25 on 11/1/26.
//

import Foundation

// MARK: - API Response Wrapper for Delete
struct AddressDeleteAPIResponseWrapper: Decodable {
    let statusCode: Int
    let success: Bool
    let message: String
    let data: AddressDeleteResponseDTO?
    
    enum CodingKeys: String, CodingKey {
        case statusCode
        case success
        case message
        case data
    }
}

// MARK: - AddressDeleteResponseDTO
struct AddressDeleteResponseDTO: Decodable {
    // Init from decoder (API response)
    init(from decoder: Decoder) throws {
        // Decode the wrapper first to extract "data" key
        let wrapper = try AddressDeleteAPIResponseWrapper(from: decoder)
        // Data is null for delete response, so we just validate the wrapper
        _ = wrapper.data
    }
}
