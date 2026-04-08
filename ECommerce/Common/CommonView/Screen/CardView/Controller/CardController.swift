//
//  CardController.swift
//  ECommerce
//
//  Created by wizard.os25 on 10/1/26.
//

import Foundation
import UIKit

// MARK: - Card Controller Input Protocol

public protocol CardControllerInput {
    func didTapShow()
    func didTapExpand()
    func didTapCollapse()
    func didTapIntermediate() // For peek mode with 2-step expansion
    func didTapDismiss()
    func didPanGesture(translation: CGFloat, velocity: CGFloat)
    func didPanGestureEnded(velocity: CGFloat)
    func setParentViewHeight(_ height: CGFloat)
    func viewDidLoad()
    func updateVisibility(_ visible: Bool)
}

// MARK: - Card Controller Output Protocol

public protocol CardControllerOutput {
    var state: Observable<CardState> { get }
    var currentY: Observable<CGFloat?> { get }
    var isVisible: Observable<Bool> { get }
    var configuration: CardConfiguration { get }
    
    // Callbacks
    var onExpanded: (() -> Void)? { get set }
    var onCollapsed: (() -> Void)? { get set }
    var onDismissed: (() -> Void)? { get set }
    var onShown: (() -> Void)? { get set }
}

// MARK: - Card Controller Typealias

public typealias CardController = CardControllerInput & CardControllerOutput & EcoController

// MARK: - Default Card Controller

public final class DefaultCardController: CardController {
    
    // MARK: - OUTPUT (Card-specific)
    
    public let state: Observable<CardState>
    public let currentY: Observable<CGFloat?>
    public let isVisible: Observable<Bool>
    public let configuration: CardConfiguration
    
    // MARK: - EcoController Output (common to all controllers)
    
    public let loading: Observable<Bool> = Observable(false)
    public let error: Observable<Error?> = Observable(nil)
    public let navigationState: Observable<EcoNavigationState> = Observable(.init())
    
    // MARK: - Callbacks
    
    public var onExpanded: (() -> Void)?
    public var onCollapsed: (() -> Void)?
    public var onDismissed: (() -> Void)?
    public var onShown: (() -> Void)?
    
    // MARK: - Private
    
    private var model: CardModel
    private var parentViewHeight: CGFloat = 0
    
    // MARK: - Init
    
    public init(configuration: CardConfiguration) {
        self.configuration = configuration
        self.model = CardModel(configuration: configuration)
        self.state = Observable(model.state)
        self.currentY = Observable(model.currentY)
        self.isVisible = Observable(model.isVisible)
    }
    
    // MARK: - Private Helpers
    
    private func updateState(_ newState: CardState) {
        model.state = newState
        state.value = newState
    }
    
    public func updateVisibility(_ visible: Bool) {
        model.isVisible = visible
        isVisible.value = visible
    }
    
    private func updateCurrentY(_ y: CGFloat?) {
        model.currentY = y
        currentY.value = y
    }
    
    private func calculateY(for state: CardState, parentHeight: CGFloat) -> CGFloat {
        switch state {
        case .hidden:
            // Hide completely below screen - no peek
            return parentHeight + 100
        case .collapsed:
            return parentHeight - configuration.collapsedHeight
        case .intermediate:
            // Intermediate: Y từ top của view cha (chỉ dùng cho peek mode)
            if let intermediateY = configuration.intermediateY {
                return intermediateY
            }
            // Fallback to expanded if no intermediateY specified
            return parentHeight - configuration.expandedHeight
        case .expanded:
            // Expanded: cách đỉnh theo configuration
            return parentHeight - configuration.expandedHeight
        }
    }
    
    public func setParentViewHeight(_ height: CGFloat) {
        parentViewHeight = height
    }
}

// MARK: - INPUT Implementation

extension DefaultCardController {
    
    public func viewDidLoad() {
        // Initialize state based on configuration
        let initialState = configuration.presentationMode == .peek ? CardState.collapsed : CardState.hidden
        updateState(initialState)
        updateVisibility(configuration.presentationMode == .peek)
    }
    
    public func didTapShow() {
        guard !isVisible.value else { return }
        print("🔵 [CardController] didTapShow - parentViewHeight: \(parentViewHeight)")
        // Update state and position FIRST, then visibility
        // This ensures the view is ready to animate when it becomes visible
        updateState(.expanded)
        let y = calculateY(for: .expanded, parentHeight: parentViewHeight)
        print("🔵 [CardController] didTapShow - calculated Y: \(y)")
        updateCurrentY(y)
        // Update visibility last - this will trigger the animation
        updateVisibility(true)
        onShown?()
    }
    
    public func didTapExpand() {
        guard isVisible.value else { return }
        updateState(.expanded)
        let y = calculateY(for: .expanded, parentHeight: parentViewHeight)
        updateCurrentY(y)
        onExpanded?()
    }
    
    public func didTapCollapse() {
        guard isVisible.value else { return }
        // Allow collapse from both expanded and intermediate states
        guard state.value == .expanded || state.value == .intermediate else { return }
        updateState(.collapsed)
        let y = calculateY(for: .collapsed, parentHeight: parentViewHeight)
        updateCurrentY(y)
        onCollapsed?()
    }
    
    public func didTapIntermediate() {
        guard isVisible.value else { return }
        guard configuration.intermediateY != nil else {
            // If no intermediateY, go directly to expanded
            didTapExpand()
            return
        }
        updateState(.intermediate)
        let y = calculateY(for: .intermediate, parentHeight: parentViewHeight)
        updateCurrentY(y)
    }
    
    public func didTapDismiss() {
        guard isVisible.value else { return }
        // First update state and position (this will trigger animation)
        updateState(.hidden)
        let y = calculateY(for: .hidden, parentHeight: parentViewHeight)
        updateCurrentY(y)
        // Visibility will be updated after animation completes (handled in view)
        onDismissed?()
    }
    
    public func didPanGesture(translation: CGFloat, velocity: CGFloat) {
        guard isVisible.value, let currentYValue = currentY.value else { return }
        
        let newY = currentYValue + translation
        
        // For peek mode with intermediate: allow dragging between collapsed, intermediate, and expanded
        // For onDemand mode: only allow dragging between expanded and hidden
        if configuration.presentationMode == .peek && configuration.intermediateY != nil {
            // Peek mode: allow dragging from collapsed to expanded (through intermediate)
            let collapsedY = parentViewHeight - configuration.collapsedHeight
            let expandedY = parentViewHeight - configuration.expandedHeight
            let minY = expandedY // Can't drag above expanded
            let maxY = parentViewHeight + 50 // Allow dragging below screen for dismiss
            let clampedY = min(max(newY, minY), maxY)
            updateCurrentY(clampedY)
        } else {
            // onDemand mode: only expand or dismiss
            let minY = parentViewHeight - configuration.expandedHeight
            let maxY = parentViewHeight + 50
            let clampedY = min(max(newY, minY), maxY)
            updateCurrentY(clampedY)
        }
    }
    
    public func didPanGestureEnded(velocity: CGFloat) {
        guard isVisible.value, let currentYValue = currentY.value else { return }
        
        // Check if this is peek mode with intermediate support
        let hasIntermediate = configuration.presentationMode == .peek && configuration.intermediateY != nil
        
        if hasIntermediate {
            // Peek mode with 2-step expansion: collapsed -> intermediate -> expanded
            let collapsedY = parentViewHeight - configuration.collapsedHeight
            let intermediateY = configuration.intermediateY ?? (parentViewHeight - configuration.expandedHeight)
            let expandedY = parentViewHeight - configuration.expandedHeight
            
            if velocity < -300 {
                // Swiping up fast - move to next state up
                switch state.value {
                case .collapsed:
                    didTapIntermediate()
                case .intermediate:
                    didTapExpand()
                case .expanded:
                    // Already at top
                    break
                case .hidden:
                    break
                }
            } else if velocity > 300 {
                // Swiping down fast - move to next state down or dismiss
                switch state.value {
                case .expanded:
                    didTapIntermediate()
                case .intermediate:
                    didTapCollapse()
                case .collapsed:
                    // Already at bottom (peek), could dismiss but stay collapsed for peek mode
                    break
                case .hidden:
                    break
                }
            } else {
                // No significant velocity - snap to nearest position based on current Y
                let distanceToCollapsed = abs(currentYValue - collapsedY)
                let distanceToIntermediate = abs(currentYValue - intermediateY)
                let distanceToExpanded = abs(currentYValue - expandedY)
                
                let minDistance = min(distanceToCollapsed, min(distanceToIntermediate, distanceToExpanded))
                
                if minDistance == distanceToCollapsed {
                    didTapCollapse()
                } else if minDistance == distanceToIntermediate {
                    didTapIntermediate()
                } else {
                    didTapExpand()
                }
            }
        } else {
            // onDemand mode: only expand or dismiss, no collapse
            let threshold = parentViewHeight - configuration.expandedHeight + (configuration.expandedHeight * 0.3) // 30% from top
            
            if velocity < -300 {
                // Swiping up fast - expand (if not already)
                if state.value != .expanded {
                    didTapExpand()
                }
            } else if velocity > 300 {
                // Swiping down fast - dismiss completely
                didTapDismiss()
            } else {
                // No significant velocity - determine by position
                if currentYValue > threshold {
                    // Swiped down more than 30% - dismiss
                    didTapDismiss()
                } else {
                    // Swiped down less than 30% - stay expanded
                    if state.value != .expanded {
                        didTapExpand()
                    }
                }
            }
        }
    }
}

// MARK: - EcoController Implementation

extension DefaultCardController {
    
    public func onViewDidLoad() {
        // Initialize navigation state - CardView typically doesn't show navigation bar
        navigationState.value = EcoNavigationState(
            title: nil,
            showsSearch: false,
            searchState: nil,
            leftItem: nil,
            rightItems: [],
            background: .transparent,
            height: 0,
            collapsedHeight: 0
        )
        
        // Initialize card state
        viewDidLoad()
    }
    
    public func onViewWillAppear() {
        // Handle view will appear if needed
    }
    
    public func onViewDidDisappear() {
        // Handle view did disappear if needed
    }
}