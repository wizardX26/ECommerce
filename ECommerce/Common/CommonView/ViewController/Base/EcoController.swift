//
//  EcoController.swift
//  ECommerce
//
//  Created by wizard.os25 on 8/1/26.
//

import UIKit

public protocol EcoController: AnyObject {

    // MARK: - Lifecycle
    func onViewDidLoad()
    func onViewWillAppear()
    func onViewDidDisappear()

    // MARK: - Common Output
    var loading: Observable<Bool> { get }
    var error: Observable<Error?> { get }

    // MARK: - Navigation
    var navigationState: Observable<EcoNavigationState> { get }
}

// MARK: - Navigation Bar Callbacks (Optional)

public extension EcoController {
    /// Navigation bar search text change callback
    var onNavigationBarSearchTextChange: ((String) -> Void)? { nil }
    
    /// Navigation bar search submit callback
    var onNavigationBarSearchSubmit: ((String) -> Void)? { nil }
    
    /// Navigation bar search clear callback
    var onNavigationBarSearchClear: (() -> Void)? { nil }
    
    /// Navigation bar left item tap callback
    var onNavigationBarLeftItemTap: (() -> Void)? { nil }
    
    /// Navigation bar right item tap callback
    var onNavigationBarRightItemTap: ((Int) -> Void)? { nil }
    
    /// Navigation bar search camera button tap callback
    var onNavigationBarCameraTap: (() -> Void)? { nil }
}

// MARK: - Navigation Bar Configuration (Default Values)

public extension EcoController {
    /// Navigation bar title font
    var navigationBarTitleFont: UIFont? {
        return UIFont.systemFont(ofSize: 18, weight: .semibold)
    }
    
    /// Navigation bar title color
    var navigationBarTitleColor: UIColor? {
        return .systemGray3
    }
    
    /// Whether to show search field in navigation bar
    var navigationBarShowsSearch: Bool {
        return false
    }
    
    /// Search field height
    /// Default: 44pt (can be customized per scene)
    var navigationBarSearchFieldHeight: CGFloat {
        return 44
    }
    
    /// Search field background color
    /// Default: nil (sẽ tự động tính từ navigationBar backgroundColor)
    /// Set giá trị để override màu tự động
    var navigationBarSearchFieldBackgroundColor: UIColor? {
        return nil // nil = tự động đồng bộ với navigationBar
    }
    
    /// Search field border width
    /// Default: 1pt
    var navigationBarSearchFieldBorderWidth: CGFloat? {
        return 1
    }
    
    /// Search field border color
    /// Default: .black
    var navigationBarSearchFieldBorderColor: UIColor? {
        return .black
    }
    
    /// Left navigation item
    var navigationBarLeftItem: EcoNavItem? {
        return nil
    }
    
    /// Right navigation items
    var navigationBarRightItems: [EcoNavItem] {
        return []
    }
    
    /// Navigation bar background style
    var navigationBarBackground: EcoNavigationBackground {
        return .solid(Colors.tokenRainbowBlueEnd)
    }
    
    /// Navigation bar background color (overrides background style if set)
    var navigationBarBackgroundColor: UIColor? {
        return Colors.tokenRainbowBlueEnd
    }
    
    /// Navigation bar button tint color (for back button, icons, etc.)
    var navigationBarButtonTintColor: UIColor? {
        return Colors.tokenRainbowBlueEnd
    }
    
    /// Navigation bar title
    var navigationBarTitle: String? {
        return nil
    }
    
    /// Search field state configuration
    var navigationBarSearchState: EcoSearchState {
        return EcoSearchState(
            text: "",
            placeholder: "search_placeholder".localized(),
            isEditing: false,
            showsClearButton: true,
            showsCameraButton: true,
            height: navigationBarSearchFieldHeight,
            backgroundColor: navigationBarSearchFieldBackgroundColor,
            borderWidth: navigationBarSearchFieldBorderWidth,
            borderColor: navigationBarSearchFieldBorderColor
        )
    }
    
    /// Initial height of navigation bar for this scene
    /// Default: 120pt (can be customized per scene)
    var navigationBarInitialHeight: CGFloat {
        return 140
    }
    
    /// Collapsed height of navigation bar when scrolling
    /// Default: 80pt (can be customized per scene)
    var navigationBarCollapsedHeight: CGFloat {
        return 80
    }
    
    /// Navigation bar scroll behavior
    var navigationBarScrollBehavior: EcoNavigationScrollBehavior {
        return .default
    }
}
