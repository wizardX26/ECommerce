//
//  NotificationSceneDIContainer.swift
//  ECommerce
//
//  Created by wizard.os25 on 19/1/26.
//

import UIKit

final class NotificationSceneDIContainer {
    
    struct Dependencies {
        let notificationDataTransferService: DataTransferService
    }
    
    private let dependencies: Dependencies
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    // MARK: - Repositories
    
    func makeNotificationRepository() -> NotificationRepository {
        DefaultNotificationRepository(
            dataTransferService: dependencies.notificationDataTransferService
        )
    }
    
    // MARK: - Use Cases
    
    func makeNotificationUseCase() -> NotificationUseCase {
        DefaultNotificationUseCase(
            notificationRepository: makeNotificationRepository()
        )
    }
    
    // MARK: - Sub DIContainers
    
    func makeNotificationReadDIContainer() -> NotificationReadDIContainer {
        NotificationReadDIContainer(
            dependencies: NotificationReadDIContainer.Dependencies(
                notificationUseCase: makeNotificationUseCase()
            )
        )
    }
    
    func makeNotificationUnreadDIContainer() -> NotificationUnreadDIContainer {
        NotificationUnreadDIContainer(
            dependencies: NotificationUnreadDIContainer.Dependencies(
                notificationUseCase: makeNotificationUseCase()
            )
        )
    }
    
    // MARK: - Controllers
    
    func makeNotificationContainerController() -> NotificationContainerController {
        DefaultNotificationContainerController(
            notificationUseCase: makeNotificationUseCase()
        )
    }
    
    // MARK: - View Controllers
    
    func makeNotificationViewController() -> NotificationViewController {
        let containerController = makeNotificationContainerController()
        let readController = makeNotificationReadDIContainer().makeNotificationReadController()
        let unreadController = makeNotificationUnreadDIContainer().makeNotificationUnreadController()
        
        return NotificationViewController.create(
            with: containerController,
            readController: readController,
            unreadController: unreadController
        )
    }
}