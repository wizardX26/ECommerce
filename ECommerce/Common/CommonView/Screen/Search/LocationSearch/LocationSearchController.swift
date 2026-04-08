//
//  LocationSearchController.swift
//  ECommerce
//
//  Created by wizard.os25 on 11/1/26.
//

import Foundation
import UIKit
import MapKit

protocol LocationSearchControllerInput {
    func didSearch(keyword: String)
    func didSelectKeyword(_ keyword: LocationSearchKeyword)
    func didClearSearch()
}

protocol LocationSearchControllerOutput {
    var searchSuggestions: Observable<[LocationSearchKeyword]> { get }
    var recentSearches: Observable<[LocationSearchKeyword]> { get }
    var screenTitle: String { get }
    var onLocationSelected: ((LocationSearchKeyword) -> Void)? { get set } // Callback khi chọn vị trí
}

typealias LocationSearchController = LocationSearchControllerInput & LocationSearchControllerOutput & EcoController

final class DefaultLocationSearchController: LocationSearchController {
    
    // MARK: - OUTPUT
    
    let searchSuggestions: Observable<[LocationSearchKeyword]> = Observable([])
    let recentSearches: Observable<[LocationSearchKeyword]> = Observable([])
    var screenTitle: String { "search_location".localized() }
    var onLocationSelected: ((LocationSearchKeyword) -> Void)? // Callback khi chọn vị trí
    
    // MARK: - EcoController Output
    
    let loading: Observable<Bool> = Observable(false)
    let error: Observable<Error?> = Observable(nil)
    let navigationState: Observable<EcoNavigationState> = Observable(.init())
    
    // MARK: - Private
    
    private var searchTask: Cancellable? { willSet { searchTask?.cancel() } }
    private var localSearch: MKLocalSearch? { willSet { localSearch?.cancel() } }
    private let maxRecentSearches = 10
    private let historyStore = MapSearchHistoryStore.shared
    
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
            placeholder: "Search location",
            isEditing: false,
            showsClearButton: true,
            showsCameraButton: false, // Bỏ icon chụp ảnh
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
        return 52 // Chiều cao mặc định 80pt, luôn hiển thị search bar
    }
    
//    var navigationBarCollapsedHeight: CGFloat {
//        return 64 // Giữ nguyên 80pt, không collapse
//    }
    
    /// Navigation bar scroll behavior (luôn hiển thị search bar, không collapse)
    var navigationBarScrollBehavior: EcoNavigationScrollBehavior {
        return .sticky // Luôn hiển thị, không collapse
    }
    
    // MARK: - Init
    
    init() {
        loadRecentSearches()
    }
    
    // MARK: - Private
    
    /// Load search history từ MapSearchHistoryStore
    private func loadRecentSearches() {
        let history = historyStore.load()
        recentSearches.value = history
    }
    
    /// Save search keyword vào MapSearchHistoryStore
    private func saveRecentSearch(_ keyword: LocationSearchKeyword) {
        // Save vào history store
        historyStore.save(keyword)
        
        // Update recent searches từ store
        loadRecentSearches()
    }
}

// MARK: - INPUT Implementation

extension DefaultLocationSearchController {
    
    func didSearch(keyword: String) {
        guard !keyword.isEmpty else {
            searchSuggestions.value = []
            return
        }
        
        // Cancel previous search
        localSearch?.cancel()
        
        // Use MKLocalSearch để tìm kiếm địa điểm thực tế
        loading.value = true
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = keyword
        request.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 10.8231, longitude: 106.6297), // Default: Ho Chi Minh City
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )
        
        localSearch = MKLocalSearch(request: request)
        localSearch?.start { [weak self] response, error in
            DispatchQueue.main.async {
                self?.loading.value = false
                
                if let error = error {
                    // Ignore cancellation errors
                    if (error as NSError).code != NSUserCancelledError {
                        self?.error.value = error
                    }
                    return
                }
                
                guard let response = response else {
                    self?.searchSuggestions.value = []
                    return
                }
                
                // Convert MKMapItem to LocationSearchKeyword với tọa độ
                let suggestions = response.mapItems.prefix(10).map { mapItem -> LocationSearchKeyword in
                    LocationSearchKeyword(
                        keyword: mapItem.name ?? mapItem.placemark.title ?? "",
                        coordinate: mapItem.placemark.coordinate
                    )
                }
                
                self?.searchSuggestions.value = Array(suggestions)
            }
        }
    }
    
    func didSelectKeyword(_ keyword: LocationSearchKeyword) {
        // Save vào history (với coordinate nếu có)
        saveRecentSearch(keyword)
        // Call callback để thông báo đã chọn vị trí
        onLocationSelected?(keyword)
    }
    
    func didClearSearch() {
        searchSuggestions.value = []
    }
}

// MARK: - EcoController Implementation

extension DefaultLocationSearchController {
    
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
            collapsedHeight: navigationBarCollapsedHeight,
            scrollBehavior: navigationBarScrollBehavior // Animate navbar khi scroll
        )
        
        // Load search history khi viewDidLoad (mỗi khi mở lại màn hình)
        loadRecentSearches()
    }
    
    func onViewWillAppear() {
        // Load search history mỗi khi màn hình xuất hiện (đảm bảo có dữ liệu mới nhất)
        loadRecentSearches()
    }
    
    func onViewDidDisappear() {
        // Handle view did disappear if needed
    }
}