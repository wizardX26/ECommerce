//
//  NotificationEndpoints.swift
//  ECommerce
//
//  Created by wizard.os25 on 19/1/26.
//

import Foundation

enum NotificationEndpoints {
    
    // MARK: - Get Notifications
    
    static func getNotifications(page: Int, pageSize: Int) -> Endpoint<NotificationResponseDTO> {
        return Endpoint(
            path: "api/v1/notifications",
            method: .get,
            queryParameters: [
                "page": page,
                "pageSize": pageSize
            ]
        )
    }
    
    // MARK: - Mark Notification as Read
    
    static func markAsRead(id: Int) -> Endpoint<Void> {
        return Endpoint(
            path: "api/v1/notifications/\(id)/read",
            method: .put
        )
    }
    
    // MARK: - Mark All as Read
    
    static func markAllAsRead() -> Endpoint<Void> {
        return Endpoint(
            path: "api/v1/notifications/read-all",
            method: .put
        )
    }
    
    // MARK: - Delete Notification
    
    static func deleteNotification(id: Int) -> Endpoint<Void> {
        return Endpoint(
            path: "api/v1/notifications/\(id)",
            method: .delete
        )
    }
    
    // MARK: - Delete Read Notifications
    
    static func deleteReadNotifications() -> Endpoint<Void> {
        return Endpoint(
            path: "api/v1/notifications/read",
            method: .delete
        )
    }
    
    // MARK: - Get Unread Count
    
    static func getUnreadCount() -> Endpoint<UnreadCountResponseDTO> {
        return Endpoint(
            path: "api/v1/notifications/unread-count",
            method: .get
        )
    }
}