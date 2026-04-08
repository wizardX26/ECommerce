//
//  CartController.swift
//  ECommerce
//
//  Created by wizard.os25 on 17/1/26.
//

import Foundation
import UIKit

protocol CartControllerInput {
    func didLoadView()
    func didAddItem(productId: Int, productName: String, productDescription: String, productImageUrl: String?, price: String, quantity: Int)
    func didUpdateItemQuantity(productId: Int, quantity: Int)
    func didToggleItemSelection(productId: Int)
    func didToggleSelectAll()
    func didDeleteItem(productId: Int)
    func didDeleteItems(productIds: [Int])
    func didTapCheckout()
}

protocol CartControllerOutput {
    var cartItems: Observable<[CartItemModel]> { get }
    var selectedItemsCount: Observable<Int> { get }
    var totalPrice: Observable<Double> { get }
    var screenTitle: String { get }
    var onNavigateToCheckout: (([CartItem]) -> Void)? { get set }
}

typealias CartController = CartControllerInput & CartControllerOutput & EcoController

final class DefaultCartController: CartController {
    
    // MARK: - OUTPUT
    
    let cartItems: Observable<[CartItemModel]> = Observable([])
    let selectedItemsCount: Observable<Int> = Observable(0)
    let totalPrice: Observable<Double> = Observable(0.0)
    let screenTitle: String = "Cart"
    
    var onNavigateToCheckout: (([CartItem]) -> Void)?
    
    // MARK: - EcoController Output
    
    let loading: Observable<Bool> = Observable(false)
    let error: Observable<Error?> = Observable(nil)
    let navigationState: Observable<EcoNavigationState> = Observable(.init())
    
    // MARK: - Navigation Bar Configuration
    
    var navigationBarTitle: String? {
        let count = cartItems.value.filter { $0.isSelected }.count
        return count > 0 ? "Cart (\(count))" : "Cart"
    }
    
    var navigationBarLeftItem: EcoNavItem? {
        let isAllSelected = !cartItems.value.isEmpty && cartItems.value.allSatisfy { $0.isSelected }
        let iconName = isAllSelected ? "ic_radio_check" : "ic_new_tick_not_select"
        let bundle = Bundle(for: type(of: self))
        let icon = HelperFunction.getImage(named: iconName, in: bundle)
        
        return EcoNavItem.icon(icon ?? UIImage()) { [weak self] in
            self?.didToggleSelectAll()
        }
    }
    
    var navigationBarBackground: EcoNavigationBackground {
        return .solid(.white)
    }
    
    var navigationBarBackgroundColor: UIColor? {
        return .white
    }
    
    var navigationBarButtonTintColor: UIColor? {
        return Colors.tokenDark100
    }
    
    var navigationBarTitleColor: UIColor? {
        return .black
    }
    
    // MARK: - Private Methods
    
    private func updateSelectedItemsCount() {
        let count = cartItems.value.filter { $0.isSelected }.count
        selectedItemsCount.value = count
        
        // Update navigation bar title
        navigationState.value = EcoNavigationState(
            title: navigationBarTitle,
            titleFont: navigationBarTitleFont,
            titleColor: navigationBarTitleColor,
            showsSearch: false,
            searchState: nil,
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
    }
    
    private func updateTotalPrice() {
        let total = cartItems.value
            .filter { $0.isSelected }
            .reduce(0.0) { total, item in
                let price = item.price.convertMoneyToNumber()
                return total + (price * Double(item.quantity))
            }
        totalPrice.value = total
    }
}

// MARK: - INPUT Implementation

extension DefaultCartController {
    
    func didLoadView() {
        updateSelectedItemsCount()
        updateTotalPrice()
    }
    
    func didAddItem(productId: Int, productName: String, productDescription: String, productImageUrl: String?, price: String, quantity: Int) {
        
        var items = cartItems.value
        
        // Check if item already exists
        if let index = items.firstIndex(where: { $0.productId == productId }) {
            // Update quantity if exists
            items[index].quantity += quantity
        } else {
            // Add new item
            let newItem = CartItemModel(
                productId: productId,
                productName: productName,
                productDescription: productDescription,
                productImageUrl: productImageUrl,
                price: price,
                quantity: quantity,
                isSelected: true
            )
            items.append(newItem)
        }
        
        cartItems.value = items
        
        updateSelectedItemsCount()
        updateTotalPrice()
        
    }
    
    func didUpdateItemQuantity(productId: Int, quantity: Int) {
        guard quantity > 0 else {
            // If quantity is 0, remove item
            didDeleteItem(productId: productId)
            return
        }
        
        var items = cartItems.value
        if let index = items.firstIndex(where: { $0.productId == productId }) {
            items[index].quantity = quantity
            cartItems.value = items
            updateTotalPrice()
        }
    }
    
    func didToggleItemSelection(productId: Int) {
        var items = cartItems.value
        if let index = items.firstIndex(where: { $0.productId == productId }) {
            items[index].isSelected.toggle()
            cartItems.value = items
            updateSelectedItemsCount()
            updateTotalPrice()
        }
    }
    
    func didToggleSelectAll() {
        let allSelected = cartItems.value.allSatisfy { $0.isSelected }
        var items = cartItems.value
        
        for index in items.indices {
            items[index].isSelected = !allSelected
        }
        
        cartItems.value = items
        updateSelectedItemsCount()
        updateTotalPrice()
    }
    
    func didDeleteItem(productId: Int) {
        var items = cartItems.value
        items.removeAll { $0.productId == productId }
        cartItems.value = items
        updateSelectedItemsCount()
        updateTotalPrice()
    }
    
    func didDeleteItems(productIds: [Int]) {
        
        var items = cartItems.value
        items.removeAll { productIds.contains($0.productId) }
        cartItems.value = items
        
        
        updateSelectedItemsCount()
        updateTotalPrice()
    }
    
    func didTapCheckout() {
        let selectedItems = cartItems.value.filter { $0.isSelected }
        guard !selectedItems.isEmpty else { return }
        
        let cartItemsForCheckout = selectedItems.map { CartItem(id: $0.productId, quantity: $0.quantity) }
        onNavigateToCheckout?(cartItemsForCheckout)
    }
}

// MARK: - EcoController Implementation

extension DefaultCartController {
    
    func onViewDidLoad() {
        navigationState.value = EcoNavigationState(
            title: navigationBarTitle,
            titleFont: navigationBarTitleFont,
            titleColor: navigationBarTitleColor,
            showsSearch: false,
            searchState: nil,
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
    }
    
    func onViewWillAppear() {}
    func onViewDidDisappear() {}
}
