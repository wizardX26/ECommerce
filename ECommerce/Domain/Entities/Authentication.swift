//
//  Authentication.swift
//  ECommerce
//
//  Created by wizard.os25 on 9/1/26.
//

import Foundation

public struct AuthResult {
    public let user: User
    public let session: AuthSession
}

public struct AuthSession {
    public let accessToken: String
    public let refreshToken: String
    public let expiredAt: Date

    public func isExpired(now: Date = Date()) -> Bool {
        return now >= expiredAt
    }
}

