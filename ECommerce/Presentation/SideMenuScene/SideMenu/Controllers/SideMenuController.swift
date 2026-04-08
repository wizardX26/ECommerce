//
//  SideMenuController.swift
//  ECommerce
//
//  Created by wizard.os25 on 17/11/25.
//

import Foundation
import UIKit

protocol SideMenuControllerInput {
    func viewDidLoad()
    func didSelectMenuItem(at section: Int, index: Int)
}

protocol SideMenuControllerOutput {
    var firstSectionMenuItems: Observable<[SideMenuModel]> { get }
    var secondSectionMenuItems: Observable<[SideMenuModel]> { get }
    var selectedIndex: Observable<Int> { get }
    var selectedSection: Observable<Int> { get }
    var horizontalScrollOffset: Observable<CGFloat> { get }
    var footerText: String { get }
    func shouldSelectItem(at section: Int, index: Int) -> Bool
    func shouldDeselectItem(at section: Int, index: Int) -> Bool
    var onLogout: (() -> Void)? { get set }
    var onNavigateToShippingAddress: (() -> Void)? { get set }
    var onNavigateToProfile: (() -> Void)? { get set }
    var onNavigateToPayment: (() -> Void)? { get set }
    var onNavigateToOrder: (() -> Void)? { get set }
}

typealias SideMenuController = SideMenuControllerInput & SideMenuControllerOutput

final class DefaultSideMenuController: SideMenuController {
    
    // MARK: - OUTPUT
    
    let firstSectionMenuItems: Observable<[SideMenuModel]> = Observable([])
    let secondSectionMenuItems: Observable<[SideMenuModel]> = Observable([])
    let selectedIndex: Observable<Int> = Observable(0)
    let selectedSection: Observable<Int> = Observable(0)
    let horizontalScrollOffset: Observable<CGFloat> = Observable(0)
    let footerText: String = "Version 1.1"
    var onLogout: (() -> Void)?
    var onNavigateToShippingAddress: (() -> Void)?
    var onNavigateToProfile: (() -> Void)?
    var onNavigateToPayment: (() -> Void)?
    var onNavigateToOrder: (() -> Void)?
    
    // MARK: - Private
    
    private lazy var firstSectionMenuItemsData: [SideMenuModel] = [
        SideMenuModel(icon: UIImage(systemName: "person")!, title: "profile".localized()),
        SideMenuModel(icon: UIImage(systemName: "bag")!, title: "my_order".localized()),
        SideMenuModel(icon: UIImage(systemName: "clock")!, title: "browsing_history".localized()),
        SideMenuModel(icon: UIImage(systemName: "mappin.circle")!, title: "shipping_address".localized()),
        SideMenuModel(icon: UIImage(systemName: "creditcard")!, title: "payment".localized())
    ]
    
    private lazy var secondSectionMenuItemsData: [SideMenuModel] = [
        SideMenuModel(icon: UIImage(systemName: "gearshape")!, title: "settings_and_privacy".localized()),
        SideMenuModel(icon: UIImage(systemName: "questionmark.circle")!, title: "help_center".localized()),
        SideMenuModel(icon: UIImage(systemName: "rectangle.portrait.and.arrow.right")!, title: "logout".localized())
    ]
    
    // MARK: - Init
    
    init() {
        firstSectionMenuItems.value = firstSectionMenuItemsData
        secondSectionMenuItems.value = secondSectionMenuItemsData
    }
    
    // MARK: - INPUT
    
    func viewDidLoad() {
        // Initialize menu items if needed
        if firstSectionMenuItems.value.isEmpty {
            firstSectionMenuItems.value = firstSectionMenuItemsData
        }
        if secondSectionMenuItems.value.isEmpty {
            secondSectionMenuItems.value = secondSectionMenuItemsData
        }
    }
    
    func didSelectMenuItem(at section: Int, index: Int) {
        guard section >= 0 && section <= 1 else { return }
        
        let items = section == 0 ? firstSectionMenuItems.value : secondSectionMenuItems.value
        guard index >= 0 && index < items.count else { return }
        
        // Check if logout item was selected (section 1, last item)
        if section == 1 && index == items.count - 1 {
            // Handle logout
            onLogout?()
            return
        }
        
        // Update selected state first
        selectedSection.value = section
        selectedIndex.value = index
        
        // Handle navigation based on section and index
        if section == 0 && index == 0 {
            // Profile - trigger navigation callback
            onNavigateToProfile?()
        } else if section == 0 && index == 1 {
            // My Order - trigger navigation callback
            onNavigateToOrder?()
        } else if section == 0 && index == 3 {
            // Shipping Address - trigger navigation callback (index changed from 4 to 3 after removing Favorites)
            onNavigateToShippingAddress?()
        } else if section == 0 && index == 4 {
            // Payment - trigger navigation callback (index changed from 5 to 4 after removing Favorites and Selling)
            onNavigateToPayment?()
        }
        // TODO: Handle other menu items
    }
    
    func shouldSelectItem(at section: Int, index: Int) -> Bool {
        // All items can be selected except divider row
        return true
    }
    
    func shouldDeselectItem(at section: Int, index: Int) -> Bool {
        // Only deselect logout item (section 1, last item)
        // Other items should remain selected to show which screen is active
        if section == 1 {
            let items = secondSectionMenuItems.value
            if index == items.count - 1 {
                return true // Logout can be deselected
            }
        }
        return false // Keep other items selected
    }
}
