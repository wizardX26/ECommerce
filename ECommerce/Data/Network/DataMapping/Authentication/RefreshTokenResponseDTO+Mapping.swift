//
//  RefreshTokenResponseDTO+Mapping.swift
//  ECommerce
//
//  Created by wizard.os25 on 9/1/26.
//

import Foundation

// MARK: - API Response Wrapper
struct RefreshTokenAPIResponseWrapper: Decodable {
    let statusCode: Int
    let success: Bool
    let message: String
    let data: RefreshTokenResponseDTOInternal?
    
    enum CodingKeys: String, CodingKey {
        case statusCode
        case success
        case message
        case data
    }
}

// MARK: - Internal DTO for decoding nested "data" structure
struct RefreshTokenResponseDTOInternal: Decodable {
    let session: SessionDTO
}

// MARK: - RefreshTokenResponseDTO - main DTO used by Endpoint<RefreshTokenResponseDTO>
struct RefreshTokenResponseDTO: Decodable {
    let session: SessionDTO
    
    // Init from decoder (API response)
    init(from decoder: Decoder) throws {
        let wrapper = try RefreshTokenAPIResponseWrapper(from: decoder)
        guard let data = wrapper.data else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "RefreshToken response data is nil"
                )
            )
        }
        
        self.session = data.session
    }
    
    // Init for manual creation
    init(session: SessionDTO) {
        self.session = session
    }
}

// MARK: - Mappings to Domain

extension RefreshTokenResponseDTO {
    func toDomain() -> AuthSession {
        return session.toDomain()
    }
}
