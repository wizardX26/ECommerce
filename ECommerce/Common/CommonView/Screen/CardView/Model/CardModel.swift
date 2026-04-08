//
//  CardModel.swift
//  ECommerce
//
//  Created by wizard.os25 on 10/1/26.
//

import Foundation
import UIKit

// MARK: - Presentation Mode

public enum CardPresentationMode {
    case peek
    case onDemand
}

// MARK: - Card State

public enum CardState {
    case hidden
    case collapsed
    case intermediate // Intermediate state for peek mode with 2-step expansion
    case expanded
}

// MARK: - Card Configuration

public struct CardConfiguration {
    public let expandedHeight: CGFloat
    public let collapsedHeight: CGFloat
    public let presentationMode: CardPresentationMode
    public let enableGesture: Bool
    /// Optional intermediate Y position (from top of parent view) for peek mode with 2-step expansion
    /// Only used when presentationMode == .peek
    public let intermediateY: CGFloat?
    
    public init(
        expandedHeight: CGFloat,
        collapsedHeight: CGFloat,
        presentationMode: CardPresentationMode,
        intermediateY: CGFloat? = nil,
        enableGesture: Bool = true
    ) {
        self.expandedHeight = expandedHeight
        self.collapsedHeight = collapsedHeight
        self.presentationMode = presentationMode
        self.intermediateY = intermediateY
        self.enableGesture = enableGesture
    }
}

// MARK: - Card Modelpublic struct CardModel {
    public let configuration: CardConfiguration
    public var state: CardState
    public var isVisible: Bool
    public var currentY: CGFloat?
    
    public init(configuration: CardConfiguration) {
        self.configuration = configuration
        self.state = configuration.presentationMode == .peek ? .collapsed : .hidden
        self.isVisible = configuration.presentationMode == .peek
        self.currentY = nil
    }
    
    public var isExpanded: Bool {
        return state == .expanded
    }
    
    public var isCollapsed: Bool {
        return state == .collapsed
    }
    
    public var isHidden: Bool {
        return state == .hidden
    }
}
