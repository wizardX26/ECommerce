//
//  SideMenuPanGestureProcessor.swift
//  ECommerce
//
//  Created by wizard.os25 on 18/11/25.
//

import UIKit

/// Handles all side menu gesture recognition and pan gesture logic
/// Note: This is a processor class, not to be confused with the SideMenuGestureHandler protocol
final class SideMenuPanGestureProcessor: NSObject {
    
    // MARK: - Properties
    
    private let revealWidth: CGFloat
    private let velocityThreshold: CGFloat = 550.0
    private let edgeThreshold: CGFloat = 20.0
    
    // Drag state
    private var isDragging: Bool = false
    private var dragStartPosition: CGFloat = 0.0
    private var isExpanded: Bool = false
    
    // MARK: - Callbacks
    
    var onDragBegan: (() -> Void)?
    var onDragChanged: ((CGFloat) -> Void)? // Progress from 0.0 to 1.0
    var onDragEnded: ((Bool) -> Void)? // True if should expand, false if should collapse
    var onFastSwipe: ((Bool) -> Void)? // True if swipe right, false if swipe left
    
    // MARK: - Init
    
    init(revealWidth: CGFloat) {
        self.revealWidth = revealWidth
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// Update the current expanded state
    func updateExpandedState(_ expanded: Bool) {
        self.isExpanded = expanded
    }
    
    /// Handle pan gesture
    /// - Parameter gesture: The pan gesture recognizer
    func handlePanGesture(_ gesture: UIPanGestureRecognizer, in containerView: UIView) {
        let position = gesture.translation(in: containerView).x
        let velocity = gesture.velocity(in: containerView).x
        
        switch gesture.state {
        case .began:
            handlePanBegan(position: position, velocity: velocity)
            
        case .changed:
            if isDragging {
                handlePanChanged(position: position)
            }
            
        case .ended, .cancelled, .failed:
            if isDragging {
                handlePanEnded(position: position, velocity: velocity)
            }
            isDragging = false
            
        default:
            break
        }
    }
    
    /// Check if gesture should begin
    /// - Parameters:
    ///   - gesture: The pan gesture recognizer
    ///   - containerView: The container view
    /// - Returns: True if gesture should begin
    func shouldBeginGesture(_ gesture: UIPanGestureRecognizer, in containerView: UIView) -> Bool {
        let velocity = gesture.velocity(in: containerView)
        let translation = gesture.translation(in: containerView)
        let location = gesture.location(in: containerView)
        
        // Check if gesture started from left edge (increase threshold for easier detection)
        let isFromLeftEdge = location.x <= edgeThreshold * 2 // Increased from 20 to 40 points
        
        // Check if gesture is on a scroll view and if it's at the left/top edge
        var isScrollViewAtEdge = false
        if let scrollView = gesture.view as? UIScrollView {
            isScrollViewAtEdge = scrollView.contentOffset.x <= 0 || scrollView.contentOffset.y <= 0
        }
        
        // Check if it's a horizontal swipe
        // Be more lenient - allow if horizontal movement is greater than vertical, or if from left edge
        let isHorizontalSwipe = abs(velocity.x) > abs(velocity.y) || abs(translation.x) > abs(translation.y)
        
        // If menu is collapsed and swiping from left edge, always allow (even if not perfectly horizontal yet)
        if !isExpanded && isFromLeftEdge && translation.x > 0 {
            return true
        }
        
        // If menu is collapsed and swiping right, allow if horizontal
        if !isExpanded && isHorizontalSwipe && (velocity.x > 0 || translation.x > 0) {
            return true
        }
        
        // If menu is collapsed and on scroll view at edge, allow right swipe
        if !isExpanded && isScrollViewAtEdge && (velocity.x > 0 || translation.x > 0) {
            return true
        }
        
        // If menu is expanded and swiping left, allow
        if isExpanded && isHorizontalSwipe && velocity.x < 0 {
            return true
        }
        
        return false
    }
    
    /// Check if gesture should receive touch
    /// - Parameters:
    ///   - gesture: The gesture recognizer
    ///   - touch: The touch
    ///   - sideMenuView: The side menu view to exclude from touches
    /// - Returns: True if gesture should receive touch
    func shouldReceiveTouch(_ gesture: UIGestureRecognizer, touch: UITouch, sideMenuView: UIView) -> Bool {
        guard let touchView = touch.view else { return true }
        
        // Don't receive touch if it's on the side menu view
        if touchView.isDescendant(of: sideMenuView) {
            return false
        }
        
        return true
    }
    
    // MARK: - Private Methods
    
    private func handlePanBegan(position: CGFloat, velocity: CGFloat) {
        // If the user tries to expand the menu more than the reveal width, don't allow
        if velocity > 0 && isExpanded {
            return
        }
        
        // If the user swipes right but the side menu hasn't expanded yet, enable dragging
        // Also check position (translation) in case velocity is 0 at start
        if (velocity > 0 || position > 0) && !isExpanded {
            isDragging = true
            dragStartPosition = 0.0
        }
        // If user swipes left and the side menu is already expanded, enable dragging
        else if (velocity < 0 || position < 0) && isExpanded {
            isDragging = true
            dragStartPosition = revealWidth
        }
        
        if isDragging {
            // If swipe is fast, trigger fast swipe callback instead of dragging
            if abs(velocity) > velocityThreshold {
                onFastSwipe?(velocity > 0)
                isDragging = false
                return
            }
            
            onDragBegan?()
        }
    }
    
    private func handlePanChanged(position: CGFloat) {
        guard isDragging else { return }
        
        // Calculate new position based on drag start
        let newPosition = dragStartPosition + position
        
        // Clamp between 0 and revealWidth
        let clampedPosition = max(0.0, min(revealWidth, newPosition))
        
        // Calculate progress (0.0 = collapsed, 1.0 = expanded)
        let progress = clampedPosition / revealWidth
        
        onDragChanged?(progress)
    }
    
    private func handlePanEnded(position: CGFloat, velocity: CGFloat) {
        guard isDragging else { return }
        
        // Calculate final position
        let finalPosition = dragStartPosition + position
        
        // Check if moved more than half
        let movedMoreThanHalf = finalPosition > revealWidth * 0.5
        
        // Consider velocity - if fast swipe, use velocity direction
        let shouldExpand: Bool
        if abs(velocity) > velocityThreshold {
            shouldExpand = velocity > 0
        } else {
            shouldExpand = movedMoreThanHalf
        }
        
        onDragEnded?(shouldExpand)
    }
}

