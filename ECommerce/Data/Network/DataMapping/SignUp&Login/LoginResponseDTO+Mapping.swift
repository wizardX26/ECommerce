//
//  LoginResponseDTO+Mapping.swift
//  ECommerce
//
//  Created by wizard.os25 on 9/1/26.
//

import Foundation

// MARK: - API Response Wrapper
struct LoginAPIResponseWrapper: Decodable {
    let statusCode: Int
    let success: Bool
    let message: String
    let data: LoginResponseDTOInternal?
    
    enum CodingKeys: String, CodingKey {
        case statusCode
        case success
        case message
        case data
    }
}

// MARK: - Internal DTO for decoding nested "data" structure
struct LoginResponseDTOInternal: Decodable {
    let user: UserDTO
    let session: SessionDTO
}

// MARK: - LoginResponseDTO - main DTO used by Endpoint<LoginResponseDTO>
struct LoginResponseDTO: Decodable {
    let user: UserDTO
    let session: SessionDTO
    
    // Init from decoder (API response)
    init(from decoder: Decoder) throws {
        // Decode the wrapper first to extract "data" key
        let wrapper = try LoginAPIResponseWrapper(from: decoder)
        guard let data = wrapper.data else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Login response data is nil"
                )
            )
        }
        
        // Extract values from data
        self.user = data.user
        self.session = data.session
    }
    
    // Init for manual creation
    init(
        user: UserDTO,
        session: SessionDTO
    ) {
        self.user = user
        self.session = session
    }
}

// MARK: - Mappings to Domain

extension LoginResponseDTO {
    func toDomain() -> AuthResult {
        return .init(
            user: user.toDomain(),
            session: session.toDomain()
        )
    }
}
