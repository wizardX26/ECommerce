//
//  CategoryController.swift
//  ECommerce
//
//  Created by wizard.os25 on 7/1/26.
//

import Foundation
import UIKit

protocol CategoryControllerInput {
    func didSelectItem(at index: Int)
}

protocol CategoryControllerOutput {
    var items: Observable<[CategoryItemModel]> { get }
    var isEmpty: Bool { get }
    var screenTitle: String { get }
    var errorTitle: String { get }
    
    // Callbacks
    var onSelectCategory: ((CategoryItemModel) -> Void)? { get set }
}

typealias CategoryController = CategoryControllerInput & CategoryControllerOutput & EcoController

final class DefaultCategoryController: CategoryController {
    
    private let categoryUseCase: CategoryUseCase
    private let mainQueue: DispatchQueueType
    
    private var categoriesLoadTask: Cancellable? { willSet { categoriesLoadTask?.cancel() } }
    
    // MARK: - OUTPUT (Category-specific)
    
    let items: Observable<[CategoryItemModel]> = Observable([])
    var isEmpty: Bool { return items.value.isEmpty }
    var screenTitle: String { "Category" }
    var errorTitle: String { "error".localized() }
    
    // Callback for selecting category
    var onSelectCategory: ((CategoryItemModel) -> Void)?
    
    // MARK: - Navigation Bar Configuration
    
    /// Navigation bar title (override default to use screenTitle)
    var navigationBarTitle: String? {
        return self.screenTitle
    }
    
    /// Navigation bar title font (large and bold)
    var navigationBarTitleFont: UIFont? {
        return UIFont.systemFont(ofSize: 24, weight: .bold)
    }
    
    /// Navigation bar background color (same as Products - Colors.tokenRainbowBlueEnd)
    var navigationBarBackgroundColor: UIColor? {
        return Colors.tokenRainbowBlueEnd
    }
    
    /// Navigation bar button tint color
    var navigationBarButtonTintColor: UIColor? {
        return .white
    }
    
    /// Left navigation item (none)
    var navigationBarLeftItem: EcoNavItem? {
        return nil
    }
    
    /// Right navigation items (none)
    var navigationBarRightItems: [EcoNavItem] {
        return []
    }
    
    /// Initial height of navigation bar for Category scene (same as Products)
    var navigationBarInitialHeight: CGFloat {
        return 100
    }
    
    // MARK: - EcoController Output (common to all controllers)
    
    let loading: Observable<Bool> = Observable(false)
    let error: Observable<Error?> = Observable(nil)
    let navigationState: Observable<EcoNavigationState> = Observable(.init())
    
    // MARK: - Init
    
    init(
        categoryUseCase: CategoryUseCase,
        mainQueue: DispatchQueueType = DispatchQueue.main
    ) {
        self.categoryUseCase = categoryUseCase
        self.mainQueue = mainQueue
    }
    
    // MARK: - Private
    
    private func load(loading: Bool) {
        self.loading.value = loading
        
        categoriesLoadTask = categoryUseCase.execute(
            cached: { [weak self] categories in
                self?.mainQueue.async {
                    let items = categories.map { CategoryItemModel(category: $0) }
                    self?.items.value = items
                }
            },
            completion: { [weak self] result in
                self?.mainQueue.async {
                    switch result {
                    case .success(let categories):
                        let items = categories.map { CategoryItemModel(category: $0) }
                        self?.items.value = items
                    case .failure(let error):
                        self?.handle(error: error)
                    }
                    self?.loading.value = false
                }
            }
        )
    }
    
    private func handle(error: Error) {
        self.error.value = error
    }
}

// MARK: - INPUT. View event methods

extension DefaultCategoryController {
    
    func didSelectItem(at index: Int) {
        guard index >= 0, index < items.value.count else { return }
        let categoryItem = items.value[index]
        
        if let callback = onSelectCategory {
            callback(categoryItem)
        }
    }
}

// MARK: - EcoController Implementation

extension DefaultCategoryController {
    
    func onViewDidLoad() {
        // Initialize navigation state using customizable properties
        navigationState.value = EcoNavigationState(
            title: navigationBarTitle,
            titleFont: navigationBarTitleFont,
            titleColor: navigationBarTitleColor,
            showsSearch: navigationBarShowsSearch,
            searchState: navigationBarShowsSearch ? navigationBarSearchState : nil,
            leftItem: navigationBarLeftItem,
            rightItems: navigationBarRightItems,
            background: navigationBarBackground,
            backgroundColor: navigationBarBackgroundColor,
            buttonTintColor: navigationBarButtonTintColor,
            height: navigationBarInitialHeight,
            collapsedHeight: navigationBarCollapsedHeight,
            backButtonStyle: .simple,
            scrollBehavior: navigationBarScrollBehavior
        )
        
        // Load categories
        load(loading: true)
    }
    
    func onViewWillAppear() {
        // Handle view will appear if needed
    }
    
    func onViewDidDisappear() {
        // Handle view did disappear if needed
    }
}
