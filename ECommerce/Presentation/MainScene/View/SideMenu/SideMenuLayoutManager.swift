//
//  SideMenuLayoutManager.swift
//  ECommerce
//
//  Created by wizard.os25 on 18/11/25.
//

import UIKit

/// Manages all side menu layout and constraints using unified Auto Layout approach
final class SideMenuLayoutManager {
    
    // MARK: - Properties
    
    private let revealWidth: CGFloat
    private weak var containerView: UIView?
    private weak var sideMenuView: UIView?
    private weak var contentView: UIView?
    private(set) weak var shadowView: UIView?
    
    // Constraints
    private var sideMenuLeadingConstraint: NSLayoutConstraint?
    private var sideMenuWidthConstraint: NSLayoutConstraint?
    private var sideMenuTopConstraint: NSLayoutConstraint?
    private var sideMenuBottomConstraint: NSLayoutConstraint?
    
    // MARK: - Init
    
    init(revealWidth: CGFloat) {
        self.revealWidth = revealWidth
    }
    
    // MARK: - Setup Methods
    
    /// Setup side menu layout in container view
    /// Uses frame-based positioning for smooth animations
    /// - Parameters:
    ///   - sideMenuView: The side menu view
    ///   - containerView: The container view
    func setupSideMenuLayout(sideMenuView: UIView, in containerView: UIView) {
        self.sideMenuView = sideMenuView
        self.containerView = containerView
        
        // Use frame-based positioning for smooth animations
        sideMenuView.translatesAutoresizingMaskIntoConstraints = true
        containerView.addSubview(sideMenuView)
        
        // Set initial frame (hidden on the left)
        sideMenuView.frame = CGRect(
            x: -revealWidth,
            y: 0,
            width: revealWidth,
            height: containerView.bounds.height
        )
        
        // Create constraints for reference (but not active)
        // These can be used for constraint-based layout if needed in the future
        sideMenuLeadingConstraint = sideMenuView.leadingAnchor.constraint(
            equalTo: containerView.leadingAnchor,
            constant: -revealWidth
        )
        sideMenuWidthConstraint = sideMenuView.widthAnchor.constraint(equalToConstant: revealWidth)
        sideMenuTopConstraint = sideMenuView.topAnchor.constraint(equalTo: containerView.topAnchor)
        sideMenuBottomConstraint = sideMenuView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        
        // Don't activate constraints - use frame-based positioning
    }
    
    /// Setup content view layout
    /// - Parameter contentView: The content view
    func setupContentViewLayout(contentView: UIView) {
        self.contentView = contentView
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        guard let containerView = containerView else { return }
        
        // Create constraints to fill container
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: containerView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        // If shadow view exists, add it to content view
        if let shadowView = shadowView {
            addShadowToContentView(contentView, shadowView: shadowView)
        }
    }
    
    /// Setup shadow view layout
    /// - Parameter shadowView: The shadow overlay view
    func setupShadowViewLayout(shadowView: UIView) {
        self.shadowView = shadowView
        
        shadowView.translatesAutoresizingMaskIntoConstraints = false
        shadowView.backgroundColor = .black
        shadowView.alpha = 0.0
        shadowView.isUserInteractionEnabled = true
        
        // If content view exists, add shadow to it
        // Otherwise, it will be added when content view is set up
        if let contentView = contentView {
            addShadowToContentView(contentView, shadowView: shadowView)
        }
    }
    
    /// Add shadow view to content view
    /// - Parameters:
    ///   - contentView: The content view
    ///   - shadowView: The shadow view
    private func addShadowToContentView(_ contentView: UIView, shadowView: UIView) {
        // Remove from previous parent if any
        shadowView.removeFromSuperview()
        
        // Add shadow to content view and create constraints
        contentView.addSubview(shadowView)
        contentView.bringSubviewToFront(shadowView)
        
        NSLayoutConstraint.activate([
            shadowView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            shadowView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            shadowView.topAnchor.constraint(equalTo: contentView.topAnchor),
            shadowView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    // MARK: - Update Methods
    
    /// Update side menu position (for frame-based animation during drag)
    /// Temporarily disables Auto Layout constraints for smooth frame-based animation
    /// - Parameter x: The x position
    func updateSideMenuPosition(x: CGFloat) {
        guard let sideMenuView = sideMenuView else { return }
        
        // Temporarily disable constraints for frame-based animation
        if sideMenuView.translatesAutoresizingMaskIntoConstraints == false {
            sideMenuView.translatesAutoresizingMaskIntoConstraints = true
            sideMenuLeadingConstraint?.isActive = false
        }
        
        sideMenuView.frame.origin.x = x
    }
    
    /// Update content view position (for frame-based animation during drag)
    /// - Parameter x: The x position
    func updateContentViewPosition(x: CGFloat) {
        guard let contentView = contentView else { return }
        
        // Ensure content view uses frame-based positioning for animation
        if contentView.translatesAutoresizingMaskIntoConstraints == false {
            contentView.translatesAutoresizingMaskIntoConstraints = true
        }
        
        contentView.frame.origin.x = x
    }
    
    /// Update side menu leading constraint (for constraint-based animation)
    /// - Parameter constant: The constant value
    func updateSideMenuLeadingConstraint(constant: CGFloat) {
        sideMenuLeadingConstraint?.constant = constant
        containerView?.layoutIfNeeded()
    }
    
    /// Update shadow view alpha
    /// - Parameter alpha: The alpha value (0.0 to 1.0)
    func updateShadowAlpha(_ alpha: CGFloat) {
        shadowView?.alpha = alpha
    }
    
    // MARK: - State Methods
    
    /// Set expanded state (updates constraints)
    /// - Parameter expanded: True if expanded, false if collapsed
    func setExpandedState(_ expanded: Bool, animated: Bool = false) {
        let constant = expanded ? 0.0 : -revealWidth
        
        if animated {
            UIView.animate(withDuration: 0.3) {
                self.sideMenuLeadingConstraint?.constant = constant
                self.containerView?.layoutIfNeeded()
            }
        } else {
            sideMenuLeadingConstraint?.constant = constant
            containerView?.layoutIfNeeded()
        }
    }
    
    /// Handle rotation - update layout
    /// - Parameters:
    ///   - size: New size
    ///   - isExpanded: Current expanded state
    ///   - coordinator: Transition coordinator
    func handleRotation(to size: CGSize, isExpanded: Bool, coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate { _ in
            // Update side menu height to match new size
            if let sideMenuView = self.sideMenuView {
                var frame = sideMenuView.frame
                frame.size.height = size.height
                sideMenuView.frame = frame
            }
            
            // Update side menu position based on expanded state (frame-based)
            if let sideMenuView = self.sideMenuView {
                sideMenuView.frame.origin.x = isExpanded ? 0 : -self.revealWidth
            }
            
            // Update content view position
            if let contentView = self.contentView {
                contentView.frame.origin.x = isExpanded ? self.revealWidth : 0
            }
            
            // Ensure shadow view matches content view bounds
            if let contentView = self.contentView {
                self.shadowView?.frame = contentView.bounds
            }
        }
    }
    
    /// Get current side menu frame
    var sideMenuFrame: CGRect {
        return sideMenuView?.frame ?? .zero
    }
    
    /// Get current content view frame
    var contentViewFrame: CGRect {
        return contentView?.frame ?? .zero
    }
}

