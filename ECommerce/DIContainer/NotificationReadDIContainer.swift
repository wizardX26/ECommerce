//
//  NotificationReadDIContainer.swift
//  ECommerce
//
//  Created by wizard.os25 on 19/1/26.
//

import UIKit

final class NotificationReadDIContainer {
    
    struct Dependencies {
        let notificationUseCase: NotificationUseCase
    }
    
    private let dependencies: Dependencies
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    // MARK: - Controllers
    
    func makeNotificationReadController() -> NotificationReadController {
        DefaultNotificationReadController(
            notificationUseCase: dependencies.notificationUseCase
        )
    }
    
    // MARK: - View Controllers
    
    func makeNotificationReadViewController() -> NotificationReadViewController {
        NotificationReadViewController.create(
            with: makeNotificationReadController()
        )
    }
}