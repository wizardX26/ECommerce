//
//  NotificationUnreadDIContainer.swift
//  ECommerce
//
//  Created by wizard.os25 on 19/1/26.
//

import UIKit

final class NotificationUnreadDIContainer {
    
    struct Dependencies {
        let notificationUseCase: NotificationUseCase
    }
    
    private let dependencies: Dependencies
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    // MARK: - Controllers
    
    func makeNotificationUnreadController() -> NotificationUnreadController {
        DefaultNotificationUnreadController(
            notificationUseCase: dependencies.notificationUseCase
        )
    }
    
    // MARK: - View Controllers
    
    func makeNotificationUnreadViewController() -> NotificationUnreadViewController {
        NotificationUnreadViewController.create(
            with: makeNotificationUnreadController()
        )
    }
}