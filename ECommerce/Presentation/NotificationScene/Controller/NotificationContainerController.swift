//
//  NotificationContainerController.swift
//  ECommerce
//
//  Created by wizard.os25 on 19/1/26.
//

import Foundation
import UIKit

protocol NotificationContainerControllerInput {
    func didLoad()
    func refreshUnreadCount()
}

protocol NotificationContainerControllerOutput {
    var unreadCount: Observable<Int> { get }
    var loading: Observable<Bool> { get }
    var error: Observable<Error?> { get }
}

typealias NotificationContainerController = NotificationContainerControllerInput & NotificationContainerControllerOutput & EcoController

final class DefaultNotificationContainerController: NotificationContainerController {
    
    private let notificationUseCase: NotificationUseCase
    private let mainQueue: DispatchQueueType
    
    // MARK: - OUTPUT
    
    let unreadCount: Observable<Int> = Observable(0)
    let loading: Observable<Bool> = Observable(false)
    let error: Observable<Error?> = Observable(nil)
    let navigationState: Observable<EcoNavigationState> = Observable(.init())
    
    // MARK: - Init
    
    init(
        notificationUseCase: NotificationUseCase,
        mainQueue: DispatchQueueType = DispatchQueue.main
    ) {
        self.notificationUseCase = notificationUseCase
        self.mainQueue = mainQueue
    }
    
    // MARK: - Input
    
    func onViewDidLoad() {
        updateNavigationState()
    }
    
    func onViewWillAppear() {}
    func onViewDidDisappear() {}
    
    func didLoad() {
        loadUnreadCount()
    }
    
    func refreshUnreadCount() {
        loadUnreadCount()
    }
    
    // MARK: - Private
    
    private func loadUnreadCount() {
        loading.value = true
        error.value = nil
        
        notificationUseCase.getUnreadCount { [weak self] result in
            guard let self = self else { return }
            
            self.mainQueue.async(execute: {
                self.loading.value = false
                
                switch result {
                case .success(let unreadCount):
                    self.unreadCount.value = unreadCount.count
                case .failure(let err):
                    self.error.value = err
                }
            })
        }
    }
    
    private func updateNavigationState() {
        var state = EcoNavigationState()
        state.title = "notification".localized()
        state.background = .solid(.white)
        state.backgroundColor = .white
        state.titleColor = .black
        state.buttonTintColor = Colors.tokenDark100
        state.backButtonStyle = .simple
        navigationState.value = state
    }
}