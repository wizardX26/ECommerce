//
//  NotificationReadController.swift
//  ECommerce
//
//  Created by wizard.os25 on 19/1/26.
//

import Foundation
import UIKit

protocol NotificationReadControllerInput {
    func didLoad()
    func didSelectItem(at index: Int)
    func didToggleSelectionMode()
    func didDeleteSelectedNotifications()
    func didRefresh()
    func loadMoreNotifications()
    func deleteNotification(id: Int, completion: @escaping (Bool) -> Void)
}

protocol NotificationReadControllerOutput {
    var items: Observable<[NotificationItemModel]> { get }
    var isLoading: Observable<Bool> { get }
    var error: Observable<Error?> { get }
    var isSelectionMode: Observable<Bool> { get }
    var selectedItems: Observable<[Int]> { get }
}

typealias NotificationReadController = NotificationReadControllerInput & NotificationReadControllerOutput & EcoController

final class DefaultNotificationReadController: NotificationReadController {
    
    private let notificationUseCase: NotificationUseCase
    private let mainQueue: DispatchQueueType
    
    private var currentPage: Int = 0
    private var pageSize: Int = 20
    private var hasMorePages: Bool = true
    private var isLoadingMore: Bool = false
    
    // MARK: - OUTPUT
    
    let items: Observable<[NotificationItemModel]> = Observable([])
    let isLoading: Observable<Bool> = Observable(false)
    let error: Observable<Error?> = Observable(nil)
    let isSelectionMode: Observable<Bool> = Observable(false)
    let selectedItems: Observable<[Int]> = Observable([])
    let navigationState: Observable<EcoNavigationState> = Observable(.init())
    
    // MARK: - EcoController Output (map from isLoading to loading)
    var loading: Observable<Bool> {
        return isLoading
    }
    
    var onNotificationDeleted: (() -> Void)?
    
    // Add notification to read list (when marked as read from unread)
    func addNotification(_ notification: NotificationItemModel) {
        // Check if notification already exists
        guard !items.value.contains(where: { $0.id == notification.id }) else {
            return
        }
        
        // Add to the beginning of the list (newest first)
        var updatedItems = items.value
        updatedItems.insert(notification, at: 0)
        items.value = updatedItems
    }
    
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
        loadNotifications(reset: true)
    }
    
    func didSelectItem(at index: Int) {
        guard index >= 0 && index < items.value.count else { return }
        
        if isSelectionMode.value {
            toggleItemSelection(at: index)
        }
    }
    
    func didToggleSelectionMode() {
        isSelectionMode.value = !isSelectionMode.value
        if !isSelectionMode.value {
            selectedItems.value = []
        }
        updateNavigationState()
        // Update all items to show/hide selection button
        var updatedItems = items.value
        for i in updatedItems.indices {
            updatedItems[i].showSelectionButton = isSelectionMode.value
        }
        items.value = updatedItems
    }
    
    func didDeleteSelectedNotifications() {
        let selectedIds = selectedItems.value
        guard !selectedIds.isEmpty else { return }
        
        isLoading.value = true
        error.value = nil
        
        // Delete notifications one by one (API delete read notifications returns 404)
        deleteNotifications(ids: selectedIds) { [weak self] success in
            guard let self = self else { return }
            
            self.mainQueue.async(execute: {
                self.isLoading.value = false
                
                if success {
                    // Remove deleted items
                    var updatedItems = self.items.value
                    updatedItems.removeAll { selectedIds.contains($0.id) }
                    self.items.value = updatedItems
                    
                    // Clear selection
                    self.selectedItems.value = []
                    self.isSelectionMode.value = false
                    self.updateNavigationState()
                    
                    // Notify parent
                    self.onNotificationDeleted?()
                }
            })
        }
    }
    
    private func deleteNotifications(ids: [Int], completion: @escaping (Bool) -> Void) {
        guard !ids.isEmpty else {
            completion(true)
            return
        }
        
        var remaining = ids
        var successCount = 0
        var failedCount = 0
        
        func deleteNext() {
            guard let id = remaining.first else {
                // Consider success if at least some notifications were deleted
                completion(successCount > 0)
                return
            }
            
            remaining.removeFirst()
            deleteNotification(id: id) { success in
                if success {
                    successCount += 1
                } else {
                    failedCount += 1
                }
                deleteNext()
            }
        }
        
        deleteNext()
    }
    
    func didRefresh() {
        loadNotifications(reset: true)
    }
    
    func loadMoreNotifications() {
        guard hasMorePages && !isLoadingMore && !isLoading.value else { return }
        loadNotifications(reset: false)
    }
    
    func toggleItemSelection(at index: Int) {
        guard index >= 0 && index < items.value.count else { return }
        var updatedItems = items.value
        let item = updatedItems[index]
        
        if item.isSelected {
            updatedItems[index].isSelected = false
            var selected = selectedItems.value
            selected.removeAll { $0 == item.id }
            selectedItems.value = selected
        } else {
            updatedItems[index].isSelected = true
            var selected = selectedItems.value
            selected.append(item.id)
            selectedItems.value = selected
        }
        
        updatedItems[index].showSelectionButton = isSelectionMode.value
        items.value = updatedItems
        updateNavigationState()
    }
    
    // MARK: - NotificationReadControllerInput
    
    func deleteNotification(id: Int, completion: @escaping (Bool) -> Void) {
        notificationUseCase.deleteNotification(id: id) { result in
            switch result {
            case .success:
                completion(true)
            case .failure:
                completion(false)
            }
        }
    }
    
    // MARK: - Private
    
    private func loadNotifications(reset: Bool) {
        if reset {
            currentPage = 0
            hasMorePages = true
            isLoading.value = true
        } else {
            isLoadingMore = true
        }
        error.value = nil
        
        notificationUseCase.fetchNotifications(page: currentPage, pageSize: pageSize) { [weak self] result in
            guard let self = self else { return }
            
            self.mainQueue.async(execute: {
                if reset {
                    self.isLoading.value = false
                } else {
                    self.isLoadingMore = false
                }
                
                switch result {
                case .success(let page):
                    let readNotifications = page.content.filter { $0.isRead }
                    let newItems = readNotifications.map { NotificationItemModel(notification: $0, showSelectionButton: self.isSelectionMode.value) }
                    
                    if reset {
                        self.items.value = newItems
                    } else {
                        self.items.value.append(contentsOf: newItems)
                    }
                    
                    self.currentPage += 1
                    self.hasMorePages = page.hasMore
                case .failure(let err):
                    self.error.value = err
                }
            })
        }
    }
    
    private func updateNavigationState() {
        var state = EcoNavigationState()
        state.title = "Read"
        state.background = .solid(.white)
        state.backgroundColor = .white
        state.titleColor = .black
        state.buttonTintColor = Colors.tokenDark100
        state.backButtonStyle = .simple
        
        // Right bar item for selection mode
        if isSelectionMode.value {
            let bundle = Bundle(for: type(of: self))
            let icon = HelperFunction.getImage(named: "ic_radio_check", in: bundle) ?? UIImage()
            state.rightItems = [
                EcoNavItem.icon(icon) { [weak self] in
                    self?.didToggleSelectionMode()
                }
            ]
        } else {
            let bundle = Bundle(for: type(of: self))
            let icon = HelperFunction.getImage(named: "ic_new_tick_not_select", in: bundle) ?? UIImage()
            state.rightItems = [
                EcoNavItem.icon(icon) { [weak self] in
                    self?.didToggleSelectionMode()
                }
            ]
        }
        
        navigationState.value = state
    }
}