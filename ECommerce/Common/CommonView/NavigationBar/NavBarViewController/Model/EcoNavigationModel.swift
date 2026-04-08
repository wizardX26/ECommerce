//
//  EcoNavigationState.swift
//  ECommerce
//
//  Created by wizard.os25 on 8/1/26.
//

import UIKit

// MARK: - Navigation Item
public enum EcoNavItem {
    case back(action: () -> Void)
    case close(action: () -> Void)
    case icon(UIImage, action: () -> Void)
    case text(String, action: () -> Void)
    case cart(count: Int, action: () -> Void)
}

// MARK: - Back Button Style
public enum EcoBackButtonStyle {
    case simple // Back button không có vòng tròn nhám
    case circular // Back button có vòng tròn nhám (default)
}

// MARK: - Background Style
public enum EcoNavigationBackground {
    case transparent
    case solid(UIColor)
    case blur(UIBlurEffect.Style)
}

// MARK: - Navigation State
public struct EcoNavigationState {
    public var title: String?
    public var titleFont: UIFont?
    public var titleColor: UIColor?
    public var showsSearch: Bool
    public var searchState: EcoSearchState?
    public var leftItem: EcoNavItem?
    public var rightItems: [EcoNavItem]
    public var background: EcoNavigationBackground
    public var backgroundColor: UIColor?
    public var buttonTintColor: UIColor?
    public var height: CGFloat?
    public var collapsedHeight: CGFloat?
    
    // MARK: - Back Button Style
    public var backButtonStyle: EcoBackButtonStyle
    
    // MARK: - Scroll Behavior
    public var scrollBehavior: EcoNavigationScrollBehavior
    
    public init(
        title: String? = nil,
        titleFont: UIFont? = nil,
        titleColor: UIColor? = nil,
        showsSearch: Bool = false,
        searchState: EcoSearchState? = nil,
        leftItem: EcoNavItem? = nil,
        rightItems: [EcoNavItem] = [],
        background: EcoNavigationBackground = .solid(.white),
        backgroundColor: UIColor? = nil,
        buttonTintColor: UIColor? = nil,
        height: CGFloat? = nil,
        collapsedHeight: CGFloat? = nil,
        backButtonStyle: EcoBackButtonStyle = .circular,
        scrollBehavior: EcoNavigationScrollBehavior = .default
    ) {
        self.title = title
        self.titleFont = titleFont
        self.titleColor = titleColor
        self.showsSearch = showsSearch
        self.searchState = searchState
        self.leftItem = leftItem
        self.rightItems = rightItems
        self.background = background
        self.backgroundColor = backgroundColor
        self.buttonTintColor = buttonTintColor
        self.height = height
        self.collapsedHeight = collapsedHeight
        self.backButtonStyle = backButtonStyle
        self.scrollBehavior = scrollBehavior
    }
}

// MARK: - Scroll Behavior

public enum EcoNavigationScrollBehavior {
    case `default` // Normal behavior
    case collapseOnScroll // Collapse when scrolling down
    case fadeOnScroll // Fade out when scrolling
    case sticky // Always visible
    case hideOnScroll // Hide completely when scrolling down
    case collapseWithSearch // Collapse height, hide title, show search center with padding
}
