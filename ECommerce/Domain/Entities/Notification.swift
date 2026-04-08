//
//  Notification.swift
//  ECommerce
//
//  Created by wizard.os25 on 19/1/26.
//

import Foundation

public struct Notification {
    public let id: Int
    public let title: String
    public let description: String
    public let createdAt: String
    public let isRead: Bool
    
    public init(
        id: Int,
        title: String,
        description: String,
        createdAt: String,
        isRead: Bool
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.createdAt = createdAt
        self.isRead = isRead
    }
}

public struct UnreadCount {
    public let count: Int
    
    public init(count: Int) {
        self.count = count
    }
}