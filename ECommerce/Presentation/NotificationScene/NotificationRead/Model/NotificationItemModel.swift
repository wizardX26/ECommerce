//
//  NotificationItemModel.swift
//  ECommerce
//
//  Created by wizard.os25 on 19/1/26.
//

import Foundation

struct NotificationItemModel: Equatable {
    let id: Int
    let title: String
    let description: String
    let createdAt: String
    var isRead: Bool
    var isSelected: Bool
    var showSelectionButton: Bool
    
    init(
        id: Int,
        title: String,
        description: String,
        createdAt: String,
        isRead: Bool,
        isSelected: Bool = false,
        showSelectionButton: Bool = false
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.createdAt = createdAt
        self.isRead = isRead
        self.isSelected = isSelected
        self.showSelectionButton = showSelectionButton
    }
    
    init(notification: Notification, showSelectionButton: Bool = false) {
        self.id = notification.id
        self.title = notification.title
        self.description = notification.description
        self.createdAt = notification.createdAt
        self.isRead = notification.isRead
        self.isSelected = false
        self.showSelectionButton = showSelectionButton
    }
    
    var timeAgo: String {
        return RelativeTimeFormatter.format(createdAt)
    }
}