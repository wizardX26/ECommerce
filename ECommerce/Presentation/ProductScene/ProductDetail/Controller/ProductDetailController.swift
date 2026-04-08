//
//  ProductDetailController.swift
//  ECommerce
//
//  Created by wizard.os25 on 14/1/26.
//

import Foundation
import UIKit

protocol ProductDetailControllerInput {
    func didLoad()
}

protocol ProductDetailControllerOutput {
    var product: Observable<ProductDetailModel?> { get }
    var loading: Observable<Bool> { get }
    var error: Observable<Error?> { get }
    var navigationState: Observable<EcoNavigationState> { get }
}

typealias ProductDetailController = ProductDetailControllerInput & ProductDetailControllerOutput & EcoController

final class DefaultProductDetailController: ProductDetailController {
    
    // MARK: - OUTPUT
    
    let product: Observable<ProductDetailModel?> = Observable(nil)
    let loading: Observable<Bool> = Observable(false)
    let error: Observable<Error?> = Observable(nil)
    let navigationState: Observable<EcoNavigationState> = Observable(.init())
    
    // MARK: - Properties
    
    private let productItem: ProductItemModel
    
    // MARK: - Init
    
    init(productItem: ProductItemModel) {
        self.productItem = productItem
    }
    
    // MARK: - Navigation Bar Configuration
    
    var navigationBarTitle: String? {
        return nil // Không hiển thị title
    }
    
    var navigationBarShowsSearch: Bool {
        return true // Enable search để có thể hiển thị khi scroll
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
    
    var navigationBarScrollBehavior: EcoNavigationScrollBehavior {
        return .collapseWithSearch
    }
    
    var navigationBarInitialHeight: CGFloat {
        return 180
    }
    
    var navigationBarCollapsedHeight: CGFloat {
        return 172
    }
    
    var navigationBarButtonTintColor: UIColor? {
        return .white // Màu trắng để nổi bật trên nền trong suốt với ảnh phía sau
    }
    
    var navigationBarLeftItem: EcoNavItem? {
        return EcoNavItem.back { [weak self] in
            self?.didTapBack()
        }
    }
    
    var navigationBarRightItems: [EcoNavItem] {
        return [
            EcoNavItem.icon(UIImage(systemName: "magnifyingglass") ?? UIImage(), action: { [weak self] in
                self?.didTapSearch()
            }),
            EcoNavItem.icon(UIImage(systemName: "cart") ?? UIImage(), action: { [weak self] in
                self?.didTapCart()
            })
        ]
    }
    
    var navigationBarBackground: EcoNavigationBackground {
        return .transparent // Nền trong suốt ban đầu
    }
    
    var navigationBarBackgroundColor: UIColor? {
        return nil
    }
    
    // MARK: - Callbacks
    
    var onBack: (() -> Void)?
    var onTapCart: (() -> Void)?
    var onTapSearch: (() -> Void)?
    
    // MARK: - Private Methods
    
    private func didTapBack() {
        onBack?()
    }
    
    private func didTapSearch() {
        onTapSearch?()
    }
    
    private func didTapCart() {
        onTapCart?()
    }
}

// MARK: - INPUT

extension DefaultProductDetailController {
    
    func didLoad() {
        // Initialize navigation state
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
            backButtonStyle: .circular,
            scrollBehavior: navigationBarScrollBehavior
        )
        
        // Load product data
        product.value = ProductDetailModel(productItem: productItem)
    }
}

// MARK: - EcoController Implementation

extension DefaultProductDetailController {
    
    var onNavigationBarSearchTextChange: ((String) -> Void)? {
        { [weak self] text in
            // Handle search text change if needed
        }
    }
    
    var onNavigationBarSearchSubmit: ((String) -> Void)? {
        { [weak self] text in
            guard let self = self, !text.isEmpty else { return }
            // Handle search submit if needed
        }
    }
    
    var onNavigationBarSearchClear: (() -> Void)? {
        { [weak self] in
            // Handle search clear if needed
        }
    }
    
    func onViewDidLoad() {
        didLoad()
    }
    
    func onViewWillAppear() {
        // Handle view will appear if needed
    }
    
    func onViewDidDisappear() {
        // Handle view did disappear if needed
    }
}
