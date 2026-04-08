//
//  ProductsTableViewController.swift
//  ExampleMVVM
//
//  Created by wizard.os25 on 14/11/25.
//

import UIKit

final class ProductsTableViewController: UITableViewController, StoryboardInstantiable {
    
    var productsController: ProductsController!
    
    var nextPageLoadingSpinner: UIActivityIndicatorView?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        bind(to: self.productsController)
        setupSidebarGesture()
        // viewDidLoad() của controller đã được gọi tự động bởi ProductsViewController (EcoViewController)
    }
    
    // MARK: - Sidebar Integration
    
    /// Setup sidebar reveal gesture using SidebarRevealBehavior
    private func setupSidebarGesture() {
        // Use SidebarRevealBehavior with custom action to find parent MainViewController and reveal sidebar
        addSidebarRevealBehavior { [weak self] in
            if let mainVC: MainViewController = self?.findParentViewController() {
                mainVC.revealSidebar()
            }
        }
        
        // For table view, also add swipe gesture directly to tableView
        let swipeRightGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeRight))
        swipeRightGesture.direction = .right
        tableView.addGestureRecognizer(swipeRightGesture)
        
        // Add pan gesture to detect horizontal scroll for sidebar reveal
        // Set requiresExclusiveTouchType to false to allow tap gestures to work
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        panGesture.delegate = self
        panGesture.cancelsTouchesInView = false // Allow tap gestures to work
        tableView.addGestureRecognizer(panGesture)
    }
    
    @objc private func handleSwipeRight() {
        // Find parent MainViewController and reveal sidebar
        if let mainVC: MainViewController = self.findParentViewController() {
            mainVC.revealSidebar()
        }
    }
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: tableView)
        let velocity = gesture.velocity(in: tableView)
        
        // Only handle horizontal pan gestures (right swipe)
        guard abs(velocity.x) > abs(velocity.y), velocity.x > 0 else {
            // Reset horizontal scroll offset if not horizontal or scrolling left
            updateHorizontalScrollOffset(0)
            return
        }
        
        // Update horizontal scroll offset based on translation
        // Only track positive (right) translation
        let horizontalOffset = max(0, translation.x)
        updateHorizontalScrollOffset(horizontalOffset)
        
        // Reset offset when gesture ends
        if gesture.state == .ended || gesture.state == .cancelled {
            updateHorizontalScrollOffset(0)
        }
    }
    
    /// Update horizontal scroll offset in SideMenuController
    /// - Parameter offset: The horizontal scroll offset
    private func updateHorizontalScrollOffset(_ offset: CGFloat) {
        // Find MainViewController and update horizontal scroll offset
        guard let mainVC: MainViewController = self.findParentViewController() else { return }
        mainVC.updateHorizontalScrollOffset(offset)
    }
    
    func reload() {
        tableView.reloadData()
    }
    
    func updateLoading(_ loading: Bool) {
        if loading && nextPageLoadingSpinner == nil {
            nextPageLoadingSpinner = makeActivityIndicator(size: .init(width: tableView.frame.width, height: 44))
            tableView.tableFooterView = nextPageLoadingSpinner
        } else if !loading {
            nextPageLoadingSpinner?.removeFromSuperview()
            nextPageLoadingSpinner = nil
            tableView.tableFooterView = nil
        }
    }
    
    // MARK: - Private
    
    private func setupViews() {
        tableView.estimatedRowHeight = ProductItemCell.height
        tableView.rowHeight = UITableView.automaticDimension
    }
    
    private func bind(to productsController: ProductsController) {
        productsController.items.observe(on: self) { [weak self] _ in
            self?.reload()
        }
        productsController.loading.observe(on: self) { [weak self] loading in
            self?.updateLoading(loading)
        }
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension ProductsTableViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.productsController.items.value.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: ProductItemCell = tableView.dequeueReusableCell(at: indexPath)
        
        cell.fill(with: self.productsController.items.value[indexPath.row])
        
        if indexPath.row == self.productsController.items.value.count - 1 {
            self.productsController.didLoadNextPage()
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.productsController.isEmpty ? tableView.frame.height : super.tableView(tableView, heightForRowAt: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // ✅ QUAN TRỌNG: Delegate đã được set từ ProductsViewController
        // didSelectRowAt sẽ được xử lý bởi ProductsViewController
        // Giữ lại method này để đảm bảo không có conflict, nhưng logic sẽ được xử lý ở view cha
    }
}

// MARK: - UIGestureRecognizerDelegate

extension ProductsTableViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Allow pan gesture to work simultaneously with table view scrolling
        // But don't interfere with tap gestures
        if otherGestureRecognizer is UITapGestureRecognizer {
            return false // Don't interfere with tap
        }
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Only handle pan gestures when table view is at the left edge
        guard let panGesture = gestureRecognizer as? UIPanGestureRecognizer else {
            // Allow other gestures (like tap) to work normally
            return true
        }
        
        let location = touch.location(in: tableView)
        
        // Only trigger pan gesture if touch is near left edge (within 20 points)
        // This allows tap gestures in the middle of the screen to work normally
        return location.x <= 20
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // Only allow pan gesture to begin if it's a horizontal swipe from left edge
        guard let panGesture = gestureRecognizer as? UIPanGestureRecognizer else {
            return true
        }
        
        let location = panGesture.location(in: tableView)
        let velocity = panGesture.velocity(in: tableView)
        
        // Only allow if:
        // 1. Touch is near left edge (within 20 points)
        // 2. Horizontal velocity is greater than vertical (swiping horizontally)
        // 3. Swiping right (positive x velocity)
        let isNearLeftEdge = location.x <= 20
        let isHorizontalSwipe = abs(velocity.x) > abs(velocity.y)
        let isRightSwipe = velocity.x > 0
        
        // If not a horizontal right swipe from left edge, don't begin
        // This allows tap gestures to work normally
        return isNearLeftEdge && isHorizontalSwipe && isRightSwipe
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Pan gesture should fail if tap gesture is recognized
        // This ensures tap gestures have priority
        if otherGestureRecognizer is UITapGestureRecognizer {
            return true
        }
        
        return false
    }
}
