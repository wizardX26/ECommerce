//
//  UserInfoResponseDTO+Mapping.swift
//  ECommerce
//
//  Created by wizard.os25 on 9/1/26.
//

import Foundation

// MARK: - API Response Wrapper
struct UserInfoAPIResponseWrapper: Decodable {
    let statusCode: Int
    let success: Bool
    let message: String
    let data: UserDTO?
    
    enum CodingKeys: String, CodingKey {
        case statusCode
        case success
        case message
        case data
    }
}

// MARK: - UserInfoResponseDTO - main DTO used by Endpoint<UserInfoResponseDTO>
struct UserInfoResponseDTO: Decodable {
    let user: UserDTO
    
    // Init from decoder (API response)
    init(from decoder: Decoder) throws {
        let wrapper = try UserInfoAPIResponseWrapper(from: decoder)
        guard let data = wrapper.data else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "UserInfo response data is nil"
                )
            )
        }
        
        self.user = data
    }
    
    // Init for manual creation
    init(user: UserDTO) {
        self.user = user
    }
}

// MARK: - Mappings to Domain

extension UserInfoResponseDTO {
    func toDomain() -> User {
        return user.toDomain()
    }
}
