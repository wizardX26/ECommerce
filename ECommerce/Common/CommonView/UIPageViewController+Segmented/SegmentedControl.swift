//
//  SegmentedControl.swift
//  ECommerce
//
//  Created by Nguyen Duc Hung on 13/6/25.
//

import UIKit

@IBDesignable
public final class SegmentedControl: UIControl {
    
    // MARK: - Properties
    
    private var labels: [UILabel] = []
    private let underlineLayer = CALayer()
    private var tabWidths: [CGFloat] = []
    
    // MARK: - Public Properties
    
    /// Callback when segment is selected
    public var didSelectIndex: ((Int) -> Void)?
    
    /// Array of segment titles
    public var items: [String] = [] {
        didSet {
            // Reset selectedIndex if it's out of bounds
            if selectedIndex >= items.count {
                selectedIndex = max(0, items.count - 1)
            }
            setupLabels()
        }
    }
    
    /// Currently selected segment index
    public var selectedIndex: Int = 0 {
        didSet {
            guard selectedIndex >= 0 && selectedIndex < items.count else {
                selectedIndex = oldValue
                return
            }
            displayNewSelectedIndex()
        }
    }
    
    // MARK: - Initialization
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    
    // MARK: - Public Methods
    
    /// Calculate total width of all tabs
    public func totalTabWidth() -> CGFloat {
        return tabWidths.reduce(0, +)
    }
    
    /// Update underline position based on scroll progress
    /// - Parameter progress: Progress value (0.0 to items.count - 1)
    /// - Parameter animated: Whether to animate the transition (default: false for smooth drag following)
    public func updateThumbPosition(progress: CGFloat, animated: Bool = false) {
        guard items.count > 1,
              !tabWidths.isEmpty,
              bounds.width > 0,
              tabWidths.count == items.count else { return }
        
        let clamped = min(CGFloat(items.count - 1), max(0, progress))
        
        let spacing = Spacing.tokenSpacing12
        let targetIndex = Int(floor(clamped))
        let fraction = clamped - CGFloat(targetIndex)
        
        // Clamp targetIndex to valid range
        let safeIndex = min(max(0, targetIndex), items.count - 1)
        let nextIndex = min(safeIndex + 1, items.count - 1)
        
        // Calculate starting position of current segment
        var currentX: CGFloat = 0
        for i in 0..<safeIndex {
            currentX += tabWidths[i] + spacing
        }
        
        // Get widths for interpolation
        let currentWidth = tabWidths[safeIndex]
        let nextWidth = safeIndex < items.count - 1 ? tabWidths[nextIndex] : currentWidth
        
        // Interpolate position and width
        if safeIndex < items.count - 1 && fraction > 0 {
            // Moving to next segment
            currentX += (currentWidth + spacing) * fraction
        }
        
        // Interpolate underline width
        let underlineWidth = currentWidth + (nextWidth - currentWidth) * fraction
        
        // Calculate underline frame (at bottom of control)
        let underlineHeight: CGFloat = 2 // Border width = 2
        let underlineY = bounds.height - underlineHeight
        let newFrame = CGRect(x: currentX, y: underlineY, width: underlineWidth, height: underlineHeight)
        
        if animated {
            // Use animation for programmatic changes (e.g., after drag ends)
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.12)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .linear))
            underlineLayer.frame = newFrame
            CATransaction.commit()
        } else {
            // No animation for real-time drag following (smooth and responsive)
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            underlineLayer.frame = newFrame
            CATransaction.commit()
        }
    }
    
    // MARK: - Setup
    
    private func setupView() {
        layer.borderColor = UIColor.clear.cgColor
        backgroundColor = UIColor.clear
        
        // Setup underline layer
        underlineLayer.backgroundColor = Colors.tokenBlack.cgColor
        underlineLayer.isHidden = false
        layer.addSublayer(underlineLayer)
        
        setupLabels()
    }
    
    private func setupLabels() {
        // Remove old labels
        labels.forEach { $0.removeFromSuperview() }
        labels.removeAll(keepingCapacity: true)
        tabWidths.removeAll()
        
        // Create new labels
        for (index, item) in items.enumerated() {
            let label = UILabel()
            label.text = item
            label.textAlignment = .center
            label.textColor = Colors.tokenDark40
            label.font = Typography.fontMedium16
            label.isUserInteractionEnabled = true
            label.tag = index
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(labelTapped(_:)))
            label.addGestureRecognizer(tap)
            
            addSubview(label)
            labels.append(label)
            
            label.sizeToFit()
            let width = label.intrinsicContentSize.width + Spacing.tokenSpacing16
            tabWidths.append(width)
        }
        
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    // MARK: - Actions
    
    @objc private func labelTapped(_ gesture: UITapGestureRecognizer) {
        guard let tappedLabel = gesture.view as? UILabel else { return }
        let index = tappedLabel.tag
        guard index >= 0 && index < items.count else { return }
        
        // Only update if different to avoid unnecessary callbacks
        if selectedIndex != index {
            selectedIndex = index
            sendActions(for: .valueChanged)
            didSelectIndex?(index)
        }
    }
    
    // MARK: - Layout
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        let spacingBetweenLabels = Spacing.tokenSpacing12
        var xOffset: CGFloat = 0
        
        for (index, label) in labels.enumerated() {
            guard index < tabWidths.count else { break }
            let labelWidth = tabWidths[index]
            label.frame = CGRect(x: xOffset, y: 0, width: labelWidth, height: bounds.height)
            xOffset += labelWidth + spacingBetweenLabels
        }
        
        // Update underline frame
        updateUnderlineFrame()
        
        // Update scrollView contentSize if needed
        if let scrollView = superview as? UIScrollView {
            scrollView.contentSize = CGSize(width: xOffset, height: bounds.height)
        }
    }
    
    private func updateUnderlineFrame() {
        guard selectedIndex < labels.count,
              selectedIndex < tabWidths.count else { return }
        
        let selectedLabel = labels[selectedIndex]
        let underlineWidth = tabWidths[selectedIndex]
        let underlineHeight: CGFloat = 2 // Border width = 2
        let underlineX = selectedLabel.frame.origin.x
        let underlineY = bounds.height - underlineHeight
        
        underlineLayer.frame = CGRect(
            x: underlineX,
            y: underlineY,
            width: underlineWidth,
            height: underlineHeight
        )
    }
    
    // MARK: - Display Selected Index
    
    private func displayNewSelectedIndex() {
        // Update label colors
        for (index, label) in labels.enumerated() {
            label.textColor = index == selectedIndex ? Colors.tokenBlack : Colors.tokenDark40
        }
        
        // Animate underline position
        guard selectedIndex < labels.count,
              selectedIndex < tabWidths.count else { return }
        
        let selectedLabel = labels[selectedIndex]
        let underlineWidth = tabWidths[selectedIndex]
        let underlineHeight: CGFloat = 2
        let underlineX = selectedLabel.frame.origin.x
        let underlineY = bounds.height - underlineHeight
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.12)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .linear))
        underlineLayer.frame = CGRect(
            x: underlineX,
            y: underlineY,
            width: underlineWidth,
            height: underlineHeight
        )
        CATransaction.commit()
        
        // Auto-scroll to center selected label
        scrollToSelectedLabel()
    }
    
    private func scrollToSelectedLabel() {
        guard let scrollView = superview as? UIScrollView,
              selectedIndex < labels.count else { return }
        
        let selectedLabel = labels[selectedIndex]
        let labelMidX = selectedLabel.frame.midX
        let scrollViewWidth = scrollView.bounds.width
        
        // Calculate offset to center the selected label
        var targetOffsetX = labelMidX - scrollViewWidth / 2
        
        // Clamp to valid range
        targetOffsetX = max(0, min(targetOffsetX, scrollView.contentSize.width - scrollViewWidth))
        
        scrollView.setContentOffset(CGPoint(x: targetOffsetX, y: 0), animated: true)
    }
}
