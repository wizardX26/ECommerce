//
//  SignUpResponseDTO+Mapping.swift
//  ECommerce
//
//  Created by wizard.os25 on 9/1/26.
//

import Foundation

// MARK: - API Response Wrapper
struct SignUpAPIResponseWrapper: Decodable {
    let statusCode: Int
    let success: Bool
    let message: String
    let data: SignUpResponseDTOInternal?
    
    enum CodingKeys: String, CodingKey {
        case statusCode
        case success
        case message
        case data
    }
}

// MARK: - Internal DTO for decoding nested "data" structure
struct SignUpResponseDTOInternal: Decodable {
    let user: UserDTO
    let session: SessionDTO
}

// UserDTO and SessionDTO are defined in UserDTO+Mapping.swift

// MARK: - SignUpResponseDTO - main DTO used by Endpoint<SignUpResponseDTO>
struct SignUpResponseDTO: Decodable {
    let user: UserDTO
    let session: SessionDTO
    
    // Init from decoder (API response)
    init(from decoder: Decoder) throws {
        // Decode the wrapper first to extract "data" key
        let wrapper = try SignUpAPIResponseWrapper(from: decoder)
        guard let data = wrapper.data else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "SignUp response data is nil"
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

extension SignUpResponseDTO {
    func toDomain() -> AuthResult {
        return .init(
            user: user.toDomain(),
            session: session.toDomain()
        )
    }
}

// UserDTO and SessionDTO mappings are defined in UserDTO+Mapping.swift
