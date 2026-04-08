//
//  NotificationUseCase.swift
//  ECommerce
//
//  Created by wizard.os25 on 19/1/26.
//

import Foundation

protocol NotificationUseCase {
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

final class DefaultNotificationUseCase: NotificationUseCase {
    
    private let notificationRepository: NotificationRepository
    
    init(notificationRepository: NotificationRepository) {
        self.notificationRepository = notificationRepository
    }
    
    func fetchNotifications(
        page: Int,
        pageSize: Int,
        completion: @escaping (Result<NotificationPage, Error>) -> Void
    ) -> Cancellable? {
        return notificationRepository.fetchNotifications(
            page: page,
            pageSize: pageSize,
            completion: completion
        )
    }
    
    func markAsRead(
        id: Int,
        completion: @escaping (Result<Void, Error>) -> Void
    ) -> Cancellable? {
        return notificationRepository.markAsRead(id: id, completion: completion)
    }
    
    func markAllAsRead(
        completion: @escaping (Result<Void, Error>) -> Void
    ) -> Cancellable? {
        return notificationRepository.markAllAsRead(completion: completion)
    }
    
    func deleteNotification(
        id: Int,
        completion: @escaping (Result<Void, Error>) -> Void
    ) -> Cancellable? {
        return notificationRepository.deleteNotification(id: id, completion: completion)
    }
    
    func deleteReadNotifications(
        completion: @escaping (Result<Void, Error>) -> Void
    ) -> Cancellable? {
        return notificationRepository.deleteReadNotifications(completion: completion)
    }
    
    func getUnreadCount(
        completion: @escaping (Result<UnreadCount, Error>) -> Void
    ) -> Cancellable? {
        return notificationRepository.getUnreadCount(completion: completion)
    }
}