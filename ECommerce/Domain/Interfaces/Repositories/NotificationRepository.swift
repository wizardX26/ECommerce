//
//  NotificationRepository.swift
//  ECommerce
//
//  Created by wizard.os25 on 19/1/26.
//

import Foundation

protocol NotificationRepository {
    @discardableResult
    func fetchNotifications(
        page: Int,
        pageSize: Int,
        completion: @escaping (Result<NotificationPage, Error>) -> Void
    ) -> Cancellable?
    
    @discardableResult
    func markAsRead(
        id: Int,
        completion: @escaping (Result<Void, Error>) -> Void
    ) -> Cancellable?
    
    @discardableResult
    func markAllAsRead(
        completion: @escaping (Result<Void, Error>) -> Void
    ) -> Cancellable?
    
    @discardableResult
    func deleteNotification(
        id: Int,
        completion: @escaping (Result<Void, Error>) -> Void
    ) -> Cancellable?
    
    @discardableResult
    func deleteReadNotifications(
        completion: @escaping (Result<Void, Error>) -> Void
    ) -> Cancellable?
    
    @discardableResult
    func getUnreadCount(
        completion: @escaping (Result<UnreadCount, Error>) -> Void
    ) -> Cancellable?
}

public struct NotificationPage {
    public let content: [Notification]
    public let page: Int
    public let pageSize: Int
    public let totalElements: Int
    public let hasMore: Bool
    
    public init(
        content: [Notification],
        page: Int,
        pageSize: Int,
        totalElements: Int,
        hasMore: Bool
    ) {
        self.content = content
        self.page = page
        self.pageSize = pageSize
        self.totalElements = totalElements
        self.hasMore = hasMore
    }
    
    // Computed property for backward compatibility
    public var totalPages: Int {
        guard pageSize > 0 else { return 1 }
        return (totalElements + pageSize - 1) / pageSize
    }
}