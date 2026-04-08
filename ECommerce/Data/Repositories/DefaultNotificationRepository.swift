//
//  DefaultNotificationRepository.swift
//  ECommerce
//
//  Created by wizard.os25 on 19/1/26.
//

import Foundation

final class DefaultNotificationRepository {
    
    private let dataTransferService: DataTransferService
    private let backgroundQueue: DataTransferDispatchQueue
    
    init(
        dataTransferService: DataTransferService,
        backgroundQueue: DataTransferDispatchQueue = DispatchQueue.global(qos: .userInitiated)
    ) {
        self.dataTransferService = dataTransferService
        self.backgroundQueue = backgroundQueue
    }
}

extension DefaultNotificationRepository: NotificationRepository {
    
    func fetchNotifications(
        page: Int,
        pageSize: Int,
        completion: @escaping (Result<NotificationPage, Error>) -> Void
    ) -> Cancellable? {
        let task = RepositoryTask()
        
        guard !task.isCancelled else { return nil }
        
        let endpoint = NotificationEndpoints.getNotifications(page: page, pageSize: pageSize)
        task.networkTask = dataTransferService.request(
            with: endpoint,
            on: backgroundQueue
        ) { [weak self] result in
            guard !task.isCancelled else { return }
            
            switch result {
            case .success(let responseDTO):
                let page = NotificationPage(
                    content: responseDTO.data.contents.map { $0.toDomain() },
                    page: responseDTO.data.page,
                    pageSize: responseDTO.data.pageSize,
                    totalElements: responseDTO.data.totalElements,
                    hasMore: responseDTO.data.hasMore
                )
                completion(.success(page))
            case .failure(let error):
                completion(.failure(error))
            }
        }
        return task
    }
    
    func markAsRead(
        id: Int,
        completion: @escaping (Result<Void, Error>) -> Void
    ) -> Cancellable? {
        let task = RepositoryTask()
        
        guard !task.isCancelled else { return nil }
        
        let endpoint = NotificationEndpoints.markAsRead(id: id)
        task.networkTask = dataTransferService.request(
            with: endpoint,
            on: backgroundQueue
        ) { [weak self] result in
            guard !task.isCancelled else { return }
            
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
        return task
    }
    
    func markAllAsRead(
        completion: @escaping (Result<Void, Error>) -> Void
    ) -> Cancellable? {
        let task = RepositoryTask()
        
        guard !task.isCancelled else { return nil }
        
        let endpoint = NotificationEndpoints.markAllAsRead()
        task.networkTask = dataTransferService.request(
            with: endpoint,
            on: backgroundQueue
        ) { [weak self] result in
            guard !task.isCancelled else { return }
            
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
        return task
    }
    
    func deleteNotification(
        id: Int,
        completion: @escaping (Result<Void, Error>) -> Void
    ) -> Cancellable? {
        let task = RepositoryTask()
        
        guard !task.isCancelled else { return nil }
        
        let endpoint = NotificationEndpoints.deleteNotification(id: id)
        task.networkTask = dataTransferService.request(
            with: endpoint,
            on: backgroundQueue
        ) { [weak self] result in
            guard !task.isCancelled else { return }
            
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
        return task
    }
    
    func deleteReadNotifications(
        completion: @escaping (Result<Void, Error>) -> Void
    ) -> Cancellable? {
        let task = RepositoryTask()
        
        guard !task.isCancelled else { return nil }
        
        let endpoint = NotificationEndpoints.deleteReadNotifications()
        task.networkTask = dataTransferService.request(
            with: endpoint,
            on: backgroundQueue
        ) { [weak self] result in
            guard !task.isCancelled else { return }
            
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
        return task
    }
    
    func getUnreadCount(
        completion: @escaping (Result<UnreadCount, Error>) -> Void
    ) -> Cancellable? {
        let task = RepositoryTask()
        
        guard !task.isCancelled else { return nil }
        
        let endpoint = NotificationEndpoints.getUnreadCount()
        task.networkTask = dataTransferService.request(
            with: endpoint,
            on: backgroundQueue
        ) { [weak self] result in
            guard !task.isCancelled else { return }
            
            switch result {
            case .success(let responseDTO):
                let unreadCount = responseDTO.data.toDomain()
                completion(.success(unreadCount))
            case .failure(let error):
                completion(.failure(error))
            }
        }
        return task
    }
}