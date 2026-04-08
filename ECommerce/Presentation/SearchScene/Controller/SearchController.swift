//
//  SearchController.swift
//  ECommerce
//
//  Created by wizard.os25 on 9/1/26.
//

import Foundation
import UIKit

protocol SearchControllerInput {
    func didUpdateSearchText(_ text: String) // Cập nhật text khi user nhập (không call API)
    func didSearch(query: String) // Call API khi user nhấn Done/Return
    func didSelectRecentQuery(_ query: ProductQuery)
    func didClearSearch()
}

protocol SearchControllerOutput {
    var recentQueries: Observable<[ProductQuery]> { get }
    var searchText: Observable<String> { get } // Text hiện tại trong search field
    var screenTitle: String { get }
    var onSearchResult: ((ProductPage, String) -> Void)? { get set } // Callback với kết quả search và query
}

typealias SearchController = SearchControllerInput & SearchControllerOutput & EcoController

final class DefaultSearchController: SearchController {
    
    // MARK: - OUTPUT
    
    let recentQueries: Observable<[ProductQuery]> = Observable([])
    let searchText: Observable<String> = Observable("") // Text hiện tại trong search field
    var screenTitle: String { "search".localized() }
    var onSearchResult: ((ProductPage, String) -> Void)? // Callback với kết quả search và query
    
    // MARK: - EcoController Output
    
    let loading: Observable<Bool> = Observable(false)
    let error: Observable<Error?> = Observable(nil)
    let navigationState: Observable<EcoNavigationState> = Observable(.init())
    
    // MARK: - Private
    
    private var searchTask: Cancellable? { willSet { searchTask?.cancel() } }
    private let searchProductsUseCase: SearchProductsUseCase
    private let productsQueriesRepository: ProductsQueriesRepository
    private let mainQueue: DispatchQueueType
    private let maxRecentQueries = 10
    
    // MARK: - Navigation Bar Configuration
    
    var navigationBarTitle: String? {
        return nil // No title, only search field
    }
    
    var navigationBarShowsSearch: Bool {
        return true
    }
    
    var navigationBarSearchState: EcoSearchState {
        return EcoSearchState(
            text: "",
            placeholder: "Search products",
            isEditing: false,
            showsClearButton: true,
            showsCameraButton: false,
            height: navigationBarSearchFieldHeight,
            backgroundColor: navigationBarSearchFieldBackgroundColor,
            borderWidth: navigationBarSearchFieldBorderWidth,
            borderColor: navigationBarSearchFieldBorderColor
        )
    }
    
    var navigationBarBackground: EcoNavigationBackground {
        return .solid(.white)
    }
    
    var navigationBarBackgroundColor: UIColor? {
        return .white
    }
    
    var navigationBarInitialHeight: CGFloat {
        return 156 // 100 + 24
    }
    
    var navigationBarScrollBehavior: EcoNavigationScrollBehavior {
        return .sticky // Luôn hiển thị search bar
    }
    
    // MARK: - Init
    
    init(
        searchProductsUseCase: SearchProductsUseCase,
        productsQueriesRepository: ProductsQueriesRepository,
        mainQueue: DispatchQueueType = DispatchQueue.main
    ) {
        self.searchProductsUseCase = searchProductsUseCase
        self.productsQueriesRepository = productsQueriesRepository
        self.mainQueue = mainQueue
        loadRecentQueries()
    }
    
    // MARK: - Private
    
    /// Load recent queries từ repository
    private func loadRecentQueries() {
        productsQueriesRepository.fetchRecentsQueries(maxCount: maxRecentQueries) { [weak self] result in
            guard let self = self else { return }
            self.mainQueue.async(execute: {
                switch result {
                case .success(let queries):
                    self.recentQueries.value = queries
                case .failure:
                    self.recentQueries.value = []
                }
            })
        }
    }
    
    /// Save query vào repository
    private func saveRecentQuery(_ query: ProductQuery) {
        productsQueriesRepository.saveRecentQuery(query: query) { [weak self] _ in
            guard let self = self else { return }
            self.loadRecentQueries()
        }
    }
}

// MARK: - INPUT Implementation

extension DefaultSearchController {
    
    func didUpdateSearchText(_ text: String) {
        // Chỉ cập nhật text, không call API
        searchText.value = text
    }
    
    func didSearch(query: String) {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let productQuery = ProductQuery(query: trimmedQuery)
        
        // Save to recent queries
        saveRecentQuery(productQuery)
        
        // Perform search
        loading.value = true
        error.value = nil
        
        searchTask = searchProductsUseCase.execute(query: trimmedQuery) { [weak self] result in
            guard let self = self else { return }
            self.mainQueue.async(execute: {
                self.loading.value = false
                
                switch result {
                case .success(let productPage):
                    // Call callback với kết quả và query
                    self.onSearchResult?(productPage, trimmedQuery)
                case .failure(let err):
                    self.error.value = err
                }
            })
        }
    }
    
    func didSelectRecentQuery(_ query: ProductQuery) {
        // Perform search với query đã chọn
        didSearch(query: query.query)
    }
    
    func didClearSearch() {
        searchTask?.cancel()
        loading.value = false
        error.value = nil
        searchText.value = ""
    }
}

// MARK: - EcoController Implementation

extension DefaultSearchController {
    
    func onViewDidLoad() {
        navigationState.value = EcoNavigationState(
            title: navigationBarTitle,
            showsSearch: navigationBarShowsSearch,
            searchState: navigationBarShowsSearch ? navigationBarSearchState : nil,
            leftItem: nil,
            rightItems: [],
            background: navigationBarBackground,
            backgroundColor: navigationBarBackgroundColor,
            height: navigationBarInitialHeight,
            collapsedHeight: navigationBarInitialHeight,
            scrollBehavior: navigationBarScrollBehavior
        )
        
        loadRecentQueries()
    }
    
    func onViewWillAppear() {
        loadRecentQueries()
    }
    
    func onViewDidDisappear() {
        // Handle view did disappear if needed
    }
}
