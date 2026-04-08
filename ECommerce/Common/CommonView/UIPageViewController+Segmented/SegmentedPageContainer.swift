//
//  SegmentedPageContainer.swift
//  ECommerce
//
//  Created by wizard.os25 on 8/1/26.
//

import UIKit

/// Container view that combines a segmented control with a page view controller
/// Provides synchronized navigation between tabs and pages
public final class SegmentedPageContainer: UIView {
    
    // MARK: - Properties
    
    /// Callback when tab/page changes
    public var onTabChanged: ((Int) -> Void)?
    
    /// Current selected index (read-only from outside)
    public private(set) var currentIndex: Int = 0
    
    /// View controllers for each page
    public var viewControllers: [UIViewController] = []
    
    // MARK: - Private Properties
    
    private var isSetupDone: Bool = false
    private let tabScrollView = UIScrollView()
    private let segmentedControl = SegmentedControl()
    private var pageViewController: UIPageViewController?
    private weak var parentVC: UIViewController?
    private var segmentedControlWidthConstraint: NSLayoutConstraint?
    private var previousIndex: Int = 0
    private var isTransitioning: Bool = false
    
    // MARK: - Initialization
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    deinit {
        pageViewController?.willMove(toParent: nil)
        pageViewController?.view.removeFromSuperview()
        pageViewController?.removeFromParent()
    }
    
    // MARK: - Public API
    
    /// Configure the container with titles, view controllers, and parent
    /// - Parameters:
    ///   - titles: Array of segment titles
    ///   - viewControllers: Array of view controllers for each page
    ///   - parent: Parent view controller that will contain the page view controller
    ///   - defaultIndex: Initial selected index (default: 0)
    public func configUI(
        titles: [String],
        viewControllers: [UIViewController],
        parent: UIViewController,
        defaultIndex: Int = 0
    ) {
        guard !titles.isEmpty, !viewControllers.isEmpty else {
            assertionFailure("Titles and viewControllers must not be empty")
            return
        }
        
        guard titles.count == viewControllers.count else {
            assertionFailure("Titles count must match viewControllers count")
            return
        }
        
        // Validate defaultIndex
        let validDefaultIndex = max(0, min(defaultIndex, viewControllers.count - 1))
        
        // Set items before layout
        segmentedControl.items = titles
        self.viewControllers = viewControllers
        parentVC = parent
        currentIndex = validDefaultIndex
        previousIndex = validDefaultIndex
        
        // Setup callback for segmented control selection
        segmentedControl.didSelectIndex = { [weak self] index in
            guard let self = self else { return }
            // Allow tap even during transition to handle rapid taps
            self.setPage(index: index, animated: true)
            // Don't call onTabChanged here - it will be called in delegate
        }
        
        setupView()
        setupPageViewController()
        
        // Set default selection after setup
        segmentedControl.selectedIndex = validDefaultIndex
        
        // Set initial page (no animation)
        setPage(index: validDefaultIndex, animated: false)
    }
    
    // MARK: - Setup Views
    
    private func setupView() {
        guard !isSetupDone else { return }
        isSetupDone = true
        
        configureScrollView()
        configureSegmentedControl()
        setupConstraints()
    }
    
    private func configureScrollView() {
        tabScrollView.showsHorizontalScrollIndicator = false
        tabScrollView.bounces = true
        tabScrollView.alwaysBounceHorizontal = true
        tabScrollView.delaysContentTouches = false
        tabScrollView.canCancelContentTouches = true
        tabScrollView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func configureSegmentedControl() {
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupConstraints() {
        addSubview(tabScrollView)
        tabScrollView.addSubview(segmentedControl)
        
        NSLayoutConstraint.activate([
            tabScrollView.topAnchor.constraint(equalTo: topAnchor),
            tabScrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tabScrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tabScrollView.heightAnchor.constraint(equalToConstant: Sizing.tokenSizing32),
            
            segmentedControl.leadingAnchor.constraint(
                equalTo: tabScrollView.contentLayoutGuide.leadingAnchor,
                constant: Spacing.tokenSpacing16
            ),
            segmentedControl.topAnchor.constraint(
                equalTo: tabScrollView.contentLayoutGuide.topAnchor
            ),
            segmentedControl.heightAnchor.constraint(equalToConstant: Sizing.tokenSizing32)
        ])
        
        // Create width constraint (will be updated in layoutSubviews)
        let widthConstraint = segmentedControl.widthAnchor.constraint(equalToConstant: 0)
        widthConstraint.isActive = true
        segmentedControlWidthConstraint = widthConstraint
    }
    
    private func setupPageViewController() {
        guard let parent = parentVC else { return }
        
        let pageVC = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: nil
        )
        
        pageVC.delegate = self
        pageVC.dataSource = self
        
        self.pageViewController = pageVC
        
        parent.addChild(pageVC)
        addSubview(pageVC.view)
        
        pageVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pageVC.view.topAnchor.constraint(
                equalTo: segmentedControl.bottomAnchor,
                constant: Spacing.tokenSpacing04
            ),
            pageVC.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            pageVC.view.trailingAnchor.constraint(equalTo: trailingAnchor),
            pageVC.view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        pageVC.didMove(toParent: parent)
        
        // Find and configure UIPageViewController's internal scroll view
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            for subview in pageVC.view.subviews {
                if let scrollView = subview as? UIScrollView {
                    scrollView.delegate = self
                    
                    // ✅ QUAN TRỌNG: Configure để tap gestures hoạt động tốt hơn
                    // delaysContentTouches = false: Không delay touches, cho phép tap gesture nhận touch ngay
                    // canCancelContentTouches = true: Cho phép scrollView cancel touches nếu cần
                    scrollView.delaysContentTouches = false
                    scrollView.canCancelContentTouches = true
                    
                    // Note: Cannot set delegate for UIScrollView's built-in pan gesture recognizer
                    // It must have the scrollView as its delegate
                    // Instead, we'll handle gesture conflicts through other means
                    print("✅ [SegmentedPageContainer] Configured PageViewController scrollView: delaysContentTouches=false, canCancelContentTouches=true")
                    break
                }
            }
        }
    }
    
    // MARK: - Page Navigation
    
    private func setPage(index: Int, animated: Bool) {
        guard index >= 0,
              index < viewControllers.count,
              let pageVC = pageViewController else { return }
        
        // Don't set if already at this index (unless not animated)
        if index == currentIndex && animated {
            return
        }
        
        // Determine direction based on current index
        let direction: UIPageViewController.NavigationDirection = 
            (index > currentIndex) ? .forward : .reverse
        
        isTransitioning = animated
        
        pageVC.setViewControllers(
            [viewControllers[index]],
            direction: direction,
            animated: animated,
            completion: { [weak self] finished in
                guard let self = self else { return }
                self.isTransitioning = false
                // Only update if transition completed or was not animated
                if finished || !animated {
                    self.previousIndex = self.currentIndex
                    self.currentIndex = index
                    // Sync segmented control
                    if self.segmentedControl.selectedIndex != index {
                        self.segmentedControl.selectedIndex = index
                    }
                }
            }
        )
    }
    
    // MARK: - Layout
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        // Calculate and update segmented control width
        // Only update if labels have been laid out
        guard let widthConstraint = segmentedControlWidthConstraint,
              !segmentedControl.items.isEmpty else { return }
        
        // Force layout of segmented control to get accurate measurements
        segmentedControl.setNeedsLayout()
        segmentedControl.layoutIfNeeded()
        
        let measuredTotal = segmentedControl.totalTabWidth() + Spacing.tokenSpacing32
        if measuredTotal > 0 && abs(widthConstraint.constant - measuredTotal) > 0.1 {
            widthConstraint.constant = measuredTotal
            segmentedControl.layoutIfNeeded()
            tabScrollView.layoutIfNeeded()
        }
    }
}

// MARK: - UIPageViewControllerDataSource

extension SegmentedPageContainer: UIPageViewControllerDataSource {
    
    public func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        guard let index = viewControllers.firstIndex(of: viewController),
              index > 0 else {
            return nil
        }
        return viewControllers[index - 1]
    }
    
    public func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        guard let index = viewControllers.firstIndex(of: viewController),
              index < viewControllers.count - 1 else {
            return nil
        }
        return viewControllers[index + 1]
    }
}

// MARK: - UIPageViewControllerDelegate

extension SegmentedPageContainer: UIPageViewControllerDelegate {
    
    public func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        guard completed,
              let visibleVC = pageViewController.viewControllers?.first,
              let index = viewControllers.firstIndex(of: visibleVC),
              index != currentIndex else {
            return
        }
        
        isTransitioning = false
        previousIndex = currentIndex
        currentIndex = index
        
        // Update segmented control if needed
        if segmentedControl.selectedIndex != index {
            segmentedControl.selectedIndex = index
        }
        
        onTabChanged?(index)
    }
}

// MARK: - UIScrollViewDelegate

extension SegmentedPageContainer: UIScrollViewDelegate {
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Update thumb position during manual scroll (swipe gesture)
        // Skip if we're programmatically setting page to avoid conflicts
        guard let viewWidth = scrollView.superview?.frame.width,
              viewWidth > 0,
              viewControllers.count > 1 else { return }
        
        let offsetX = scrollView.contentOffset.x
        
        // UIPageViewController's internal scrollView behavior:
        // The scrollView uses a special offset system where:
        // - contentOffset.x = viewWidth * (pageIndex + 1) when at a page
        // - When scrolling: offset changes smoothly between pages
        //
        // To get page index as float: pageIndex = offsetX / viewWidth - 1
        // But we want 0-based index, so: pageIndex = offsetX / viewWidth - 1 + 1 = offsetX / viewWidth
        // However, this gives us values like 1.0 for page 0, 2.0 for page 1
        // So we need: pageIndex = (offsetX / viewWidth) - 1
        
        let rawPageIndex = offsetX / viewWidth - 1
        
        // Clamp to valid range
        let clampedProgress = max(0, min(CGFloat(viewControllers.count - 1), rawPageIndex))
        
        // Only update if significantly different to avoid jitter
        let currentProgress = CGFloat(currentIndex)
        if abs(clampedProgress - currentProgress) > 0.01 {
            // Update thumb position WITHOUT animation for smooth drag following
            // This ensures thumb follows finger immediately without delay
            segmentedControl.updateThumbPosition(progress: clampedProgress, animated: false)
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // When drag ends, optionally animate thumb to final position for polish
        // This is optional - the thumb should already be at correct position
        // But we can add a subtle animation if needed
    }
}
