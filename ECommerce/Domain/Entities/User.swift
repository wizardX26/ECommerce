//
//  User.swift
//  ECommerce
//
//  Created by wizard.os25 on 9/1/26.
//

import Foundation

public struct User: Identifiable {
    public typealias Identifier = Int
    
    public let id: Identifier
    public let fullName: String
    public let email: String
    public let phone: String
    public let avatarURL: URL?
    public let bankAccount: [String]
    public let orderCount: Int
    public let memberSinceDays: Int
    public let createdAt: Date?
    public let isEmailVerified: Bool
    
    public init(
        id: Identifier,
        fullName: String,
        email: String,
        phone: String,
        avatarURL: URL?,
        bankAccount: [String] = [],
        orderCount: Int = 0,
        memberSinceDays: Int = 0,
        createdAt: Date? = nil,
        isEmailVerified: Bool = false
    ) {
        self.id = id
        self.fullName = fullName
        self.email = email
        self.phone = phone
        self.avatarURL = avatarURL
        self.bankAccount = bankAccount
        self.orderCount = orderCount
        self.memberSinceDays = memberSinceDays
        self.createdAt = createdAt
        self.isEmailVerified = isEmailVerified
    }
}


