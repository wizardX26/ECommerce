//
//  NotificationUnreadController.swift
//  ECommerce
//
//  Created by wizard.os25 on 19/1/26.
//

import Foundation
import UIKit

protocol NotificationUnreadControllerInput {
    func didLoad()
    func didSelectItem(at index: Int)
    func didToggleSelectionMode()
    func didMarkAllAsRead()
    func didRefresh()
    func loadMoreNotifications()
    func markAsRead(id: Int)
    func deleteNotification(id: Int, completion: @escaping (Bool) -> Void)
}

protocol NotificationUnreadControllerOutput {
    var items: Observable<[NotificationItemModel]> { get }
    var isLoading: Observable<Bool> { get }
    var error: Observable<Error?> { get }
    var isSelectionMode: Observable<Bool> { get }
    var selectedItems: Observable<[Int]> { get }
    var onNotificationRead: (() -> Void)? { get set }
    var onNotificationMarkedAsRead: ((NotificationItemModel) -> Void)? { get set }
}

typealias NotificationUnreadController = NotificationUnreadControllerInput & NotificationUnreadControllerOutput & EcoController

final class DefaultNotificationUnreadController: NotificationUnreadController {
    
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
    
    var onNotificationRead: (() -> Void)?
    var onNotificationMarkedAsRead: ((NotificationItemModel) -> Void)?
    
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
    
    func didMarkAllAsRead() {
        let selectedIds = selectedItems.value
        guard !selectedIds.isEmpty else { return }
        
        isLoading.value = true
        error.value = nil
        
        // Prepare items to move to read list
        var itemsToMove: [NotificationItemModel] = []
        for id in selectedIds {
            if let index = items.value.firstIndex(where: { $0.id == id }) {
                var item = items.value[index]
                item.isRead = true
                itemsToMove.append(item)
            }
        }
        
        // Call API to mark all selected as read
        notificationUseCase.markAllAsRead { [weak self] result in
            guard let self = self else { return }
            
            self.mainQueue.async(execute: {
                self.isLoading.value = false
                
                switch result {
                case .success:
                    // Remove marked items from unread list
                    var updatedItems = self.items.value
                    updatedItems.removeAll { selectedIds.contains($0.id) }
                    self.items.value = updatedItems
                    
                    // Clear selection
                    self.selectedItems.value = []
                    self.isSelectionMode.value = false
                    self.updateNavigationState()
                    
                    // Notify to add all items to read list
                    for item in itemsToMove {
                        self.onNotificationMarkedAsRead?(item)
                    }
                    
                    // Notify parent to refresh unread count
                    self.onNotificationRead?()
                case .failure(let err):
                    self.error.value = err
                }
            })
        }
    }
    
    func didRefresh() {
        loadNotifications(reset: true)
    }
    
    func loadMoreNotifications() {
        guard hasMorePages && !isLoadingMore && !isLoading.value else { return }
        loadNotifications(reset: false)
    }
    
    func markAsRead(id: Int) {
        notificationUseCase.markAsRead(id: id) { [weak self] result in
            guard let self = self else { return }
            
            self.mainQueue.async(execute: {
                switch result {
                case .success:
                    // Find and get the item before removing
                    var updatedItems = self.items.value
                    if let index = updatedItems.firstIndex(where: { $0.id == id }) {
                        let markedItem = updatedItems[index]
                        
                        // Mark as read
                        var markedItemCopy = markedItem
                        markedItemCopy.isRead = true
                        
                        // Remove from unread list
                        updatedItems.remove(at: index)
                        self.items.value = updatedItems
                        
                        // Notify to add to read list
                        self.onNotificationMarkedAsRead?(markedItemCopy)
                    }
                    
                    // Notify parent to refresh unread count
                    self.onNotificationRead?()
                case .failure(let err):
                    self.error.value = err
                }
            })
        }
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
                    let unreadNotifications = page.content.filter { !$0.isRead }
                    let newItems = unreadNotifications.map { NotificationItemModel(notification: $0, showSelectionButton: self.isSelectionMode.value) }
                    
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
        state.title = "Unread"
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