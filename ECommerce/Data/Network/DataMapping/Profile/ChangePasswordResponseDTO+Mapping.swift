//
//  ChangePasswordResponseDTO+Mapping.swift
//  ECommerce
//
//  Created by wizard.os25 on 13/1/26.
//

import Foundation

// MARK: - API Response Wrapper
struct ChangePasswordAPIResponseWrapper: Decodable {
    let statusCode: Int
    let success: Bool
    let message: String
    let data: ChangePasswordResponseDTO?
    
    enum CodingKeys: String, CodingKey {
        case statusCode
        case success
        case message
        case data
    }
}

// MARK: - ChangePasswordResponseDTO - main DTO used by Endpoint<ChangePasswordResponseDTO>
struct ChangePasswordResponseDTO: Decodable {
    // Response data is null, so we just need to decode the wrapper
    // This DTO exists for type safety with Endpoint<ChangePasswordResponseDTO>
    
    init(from decoder: Decoder) throws {
        let wrapper = try ChangePasswordAPIResponseWrapper(from: decoder)
        // Data is null, so we don't need to extract anything
        // Just verify the response structure is valid
    }
    
    init() {
        // Empty init for manual creation
    }
}
