//
//  SideMenuAnimator.swift
//  ECommerce
//
//  Created by wizard.os25 on 18/11/25.
//

import UIKit

/// Handles all side menu animations using UIViewPropertyAnimator for smooth and consistent transitions
final class SideMenuAnimator {
    
    // MARK: - Properties
    
    private var currentAnimator: UIViewPropertyAnimator?
    private let revealWidth: CGFloat
    private let animationDuration: TimeInterval = 0.5
    private let springDamping: CGFloat = 0.8
    private let initialSpringVelocity: CGFloat = 0.5
    
    // MARK: - Callbacks
    
    var onAnimationComplete: (() -> Void)?
    
    // MARK: - Init
    
    init(revealWidth: CGFloat) {
        self.revealWidth = revealWidth
    }
    
    // MARK: - Animation Methods
    
    /// Animate side menu to expanded state
    /// - Parameters:
    ///   - sideMenuView: The side menu view to animate
    ///   - contentView: The content view to animate
    ///   - shadowView: The shadow overlay view
    func animateToExpanded(
        sideMenuView: UIView,
        contentView: UIView?,
        shadowView: UIView
    ) {
        // Cancel any ongoing animation
        cancelCurrentAnimation()
        
        // Ensure views use frame-based positioning for animation
        if sideMenuView.translatesAutoresizingMaskIntoConstraints == false {
            sideMenuView.translatesAutoresizingMaskIntoConstraints = true
        }
        if let contentView = contentView, contentView.translatesAutoresizingMaskIntoConstraints == false {
            contentView.translatesAutoresizingMaskIntoConstraints = true
        }
        
        // Create property animator with spring animation
        let animator = UIViewPropertyAnimator(
            duration: animationDuration,
            dampingRatio: springDamping,
            animations: {
                // Move side menu from left (-width) to visible (0)
                sideMenuView.frame.origin.x = 0
                
                // Move content view to the right
                contentView?.frame.origin.x = self.revealWidth
            }
        )
        
        // Add shadow fade-in animation
        animator.addAnimations {
            shadowView.alpha = 0.6
        }
        
        // Handle completion
        animator.addCompletion { [weak self] _ in
            self?.currentAnimator = nil
            self?.onAnimationComplete?()
        }
        
        currentAnimator = animator
        animator.startAnimation()
    }
    
    /// Animate side menu to collapsed state
    /// - Parameters:
    ///   - sideMenuView: The side menu view to animate
    ///   - contentView: The content view to animate
    ///   - shadowView: The shadow overlay view
    func animateToCollapsed(
        sideMenuView: UIView,
        contentView: UIView?,
        shadowView: UIView
    ) {
        // Cancel any ongoing animation
        cancelCurrentAnimation()
        
        // Ensure views use frame-based positioning for animation
        if sideMenuView.translatesAutoresizingMaskIntoConstraints == false {
            sideMenuView.translatesAutoresizingMaskIntoConstraints = true
        }
        if let contentView = contentView, contentView.translatesAutoresizingMaskIntoConstraints == false {
            contentView.translatesAutoresizingMaskIntoConstraints = true
        }
        
        // Create property animator with spring animation
        let animator = UIViewPropertyAnimator(
            duration: animationDuration,
            dampingRatio: springDamping,
            animations: {
                // Move side menu back to hidden position (left)
                sideMenuView.frame.origin.x = -self.revealWidth
                
                // Move content view back to original position
                contentView?.frame.origin.x = 0
            }
        )
        
        // Add shadow fade-out animation
        animator.addAnimations {
            shadowView.alpha = 0.0
        }
        
        // Handle completion
        animator.addCompletion { [weak self] _ in
            self?.currentAnimator = nil
            self?.onAnimationComplete?()
        }
        
        currentAnimator = animator
        animator.startAnimation()
    }
    
    /// Update positions during drag gesture
    /// - Parameters:
    ///   - sideMenuView: The side menu view
    ///   - contentView: The content view
    ///   - shadowView: The shadow overlay view
    ///   - progress: Progress from 0.0 (collapsed) to 1.0 (expanded)
    func updateDragProgress(
        sideMenuView: UIView,
        contentView: UIView?,
        shadowView: UIView,
        progress: CGFloat
    ) {
        // Clamp progress between 0 and 1
        let clampedProgress = max(0.0, min(1.0, progress))
        
        // Calculate positions
        let sideMenuX = -revealWidth + (revealWidth * clampedProgress)
        let contentX = revealWidth * clampedProgress
        
        // Ensure views use frame-based positioning for smooth drag
        if sideMenuView.translatesAutoresizingMaskIntoConstraints == false {
            sideMenuView.translatesAutoresizingMaskIntoConstraints = true
        }
        if let contentView = contentView, contentView.translatesAutoresizingMaskIntoConstraints == false {
            contentView.translatesAutoresizingMaskIntoConstraints = true
        }
        
        // Update positions immediately (no animation during drag)
        sideMenuView.frame.origin.x = sideMenuX
        contentView?.frame.origin.x = contentX
        
        // Update shadow alpha based on progress
        // Use smooth curve for alpha transition
        let shadowAlpha = clampedProgress * 0.6
        shadowView.alpha = shadowAlpha
    }
    
    /// Cancel any ongoing animation
    func cancelCurrentAnimation() {
        currentAnimator?.stopAnimation(true)
        currentAnimator = nil
    }
    
    /// Pause current animation (useful for interactive transitions)
    func pauseAnimation() {
        currentAnimator?.pauseAnimation()
    }
    
    /// Continue paused animation
    func continueAnimation() {
        currentAnimator?.continueAnimation(withTimingParameters: nil, durationFactor: 0)
    }
    
    /// Get current animation progress (0.0 to 1.0)
    var currentProgress: CGFloat {
        return currentAnimator?.fractionComplete ?? 0.0
    }
}

