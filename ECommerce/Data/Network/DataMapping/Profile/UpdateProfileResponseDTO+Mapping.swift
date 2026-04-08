//
//  UpdateProfileResponseDTO+Mapping.swift
//  ECommerce
//
//  Created by wizard.os25 on 13/1/26.
//

import Foundation

// MARK: - API Response Wrapper
struct UpdateProfileAPIResponseWrapper: Decodable {
    let statusCode: Int
    let success: Bool
    let message: String
    let data: UpdateProfileResponseDTOInternal?
    
    enum CodingKeys: String, CodingKey {
        case statusCode
        case success
        case message
        case data
    }
}

// MARK: - Internal DTO for decoding nested "data" structure
struct UpdateProfileResponseDTOInternal: Decodable {
    let id: Int
    let fullName: String
    let email: String
    let phone: String
    let orderCount: Int
    let memberSinceDays: Int
    let createdAt: String
    let accountType: String?
    let avatarUrl: String?
    let cardInfo: [String]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case fullName // API now returns fullName directly
        case email
        case phone
        case orderCount = "orderCount"
        case memberSinceDays = "memberSinceDays"
        case createdAt = "createdAt"
        case accountType = "accountType"
        case avatarUrl = "avatarUrl"
        case cardInfo = "cardInfo"
    }
}

// MARK: - UpdateProfileResponseDTO - main DTO used by Endpoint<UpdateProfileResponseDTO>
struct UpdateProfileResponseDTO: Decodable {
    let id: Int
    let fullName: String
    let email: String
    let phone: String
    let orderCount: Int
    let memberSinceDays: Int
    let createdAt: String
    let accountType: String?
    let avatarUrl: String?
    let cardInfo: [String]?
    
    // Init from decoder (API response)
    init(from decoder: Decoder) throws {
        let wrapper = try UpdateProfileAPIResponseWrapper(from: decoder)
        guard let data = wrapper.data else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "UpdateProfile response data is nil"
                )
            )
        }
        
        self.id = data.id
        self.fullName = data.fullName
        self.email = data.email
        self.phone = data.phone
        self.orderCount = data.orderCount
        self.memberSinceDays = data.memberSinceDays
        self.createdAt = data.createdAt
        self.accountType = data.accountType
        self.avatarUrl = data.avatarUrl
        self.cardInfo = data.cardInfo
    }
    
    // Init for manual creation
    init(
        id: Int,
        fullName: String,
        email: String,
        phone: String,
        orderCount: Int,
        memberSinceDays: Int,
        createdAt: String,
        accountType: String? = nil,
        avatarUrl: String? = nil,
        cardInfo: [String]? = nil
    ) {
        self.id = id
        self.fullName = fullName
        self.email = email
        self.phone = phone
        self.orderCount = orderCount
        self.memberSinceDays = memberSinceDays
        self.createdAt = createdAt
        self.accountType = accountType
        self.avatarUrl = avatarUrl
        self.cardInfo = cardInfo
    }
}

// MARK: - Mappings to Domain
extension UpdateProfileResponseDTO {
    func toDomain() -> User {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]
        
        // Use cardInfo if available, otherwise fallback to empty array
        let accountInfo: [String]
        if let cardInfo = cardInfo, !cardInfo.isEmpty {
            accountInfo = cardInfo
        } else {
            accountInfo = []
        }
        
        return User(
            id: id,
            fullName: fullName,
            email: email,
            phone: phone,
            avatarURL: avatarUrl.flatMap { URL(string: $0) },
            bankAccount: accountInfo,
            orderCount: orderCount,
            memberSinceDays: memberSinceDays,
            createdAt: dateFormatter.date(from: createdAt)
        )
    }
}
