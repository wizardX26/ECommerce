//
//  ProductsViewController.swift
//  ExampleMVVM
//
//  Created by wizard.os25 on 14/11/25.
//

import UIKit

final class ProductsViewController: EcoViewController {
    
    @IBOutlet private var productsListContainer: UIView!
    @IBOutlet private var emptyDataLabel: UILabel!
    
    @IBOutlet weak var productListConstraint: NSLayoutConstraint!
    
    private var productsController: ProductsController! {
        get { controller as? ProductsController }
    }
    private var productsTableViewController: ProductsTableViewController?
    
    // Card View Controller
    private var cardViewController: CardViewController?
    
    // MARK: - Lifecycle
    
    static func create(
        with productsController: ProductsController
    ) -> ProductsViewController {
        let view = ProductsViewController.instantiateViewController()
        // Inject controller for EcoViewController
        view.controller = productsController
        return view
    }
    
    override func viewDidLoad() {
        // Setup callbacks TRƯỚC super.viewDidLoad() để đảm bảo callback được setup trước khi navigation bar được setup
        setupCardButton()
        setupProductSelection()
        
        super.viewDidLoad()
        setupViews()
        bindProductsSpecific()
        setupChildViewController()
        setupSidebarGesture()
        // viewDidLoad will be called on mediatingController by ProductsTableViewController
    }
    
    // MARK: - Common Binding Override
    
    override func bindCommon() {
        super.bindCommon()
        bindProductsSpecific()
    }
    
    // MARK: - Products-Specific Binding
    
    private func bindProductsSpecific() {
        productsController.items.observe(on: self) { [weak self] items in
            self?.updateItems()
        }
    }
    
    // MARK: - Loading Handler Override
    
    override func handleLoading(_ isLoading: Bool) {
        super.handleLoading(isLoading)
        
        emptyDataLabel.isHidden = true
        productsListContainer.isHidden = true
        
        if !isLoading {
            // Sử dụng updateUIAfterFilter để xử lý cả toggle state và AI search info
            updateUIAfterFilter()
        }
        
        productsTableViewController?.updateLoading(isLoading)
    }
    
    // MARK: - Error Handler Override
    
    override func handleError(_ error: Error?) {
        guard let error else { return }
        showAlert(title: productsController.errorTitle, message: error.localizedDescription)
    }
    
    // MARK: - Sidebar Integration
    
    /// Setup sidebar reveal gesture using SidebarRevealBehavior
    private func setupSidebarGesture() {
        // Use SidebarRevealBehavior with custom action to find parent MainViewController and reveal sidebar
        addSidebarRevealBehavior { [weak self] in
            // Find parent MainViewController and reveal sidebar
            if let mainVC: MainViewController = self?.findParentViewController() {
                mainVC.revealSidebar()
            }
        }
    }
    
    private func setupViews() {
        title = productsController.screenTitle
        emptyDataLabel.text = productsController.emptyDataTitle
    }
    
    private func setupChildViewController() {
        let tableViewController = ProductsTableViewController.instantiateViewController()
        tableViewController.productsController = productsController
        
        // Add as child view controller
        addChild(tableViewController)
        productsListContainer.addSubview(tableViewController.view)
        tableViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        // Get navigation bar height for top padding
        let navBarHeight = productsController.navigationBarInitialHeight
        let navBarCollap = self.productsController.navigationBarCollapsedHeight
        
        self.productListConstraint.constant = navBarHeight
        
        // Setup constraints with top padding equal to navbar height
//        NSLayoutConstraint.activate([
//            tableViewController.view.topAnchor.constraint(equalTo: productsListContainer.topAnchor, constant: navBarHeight),
//            tableViewController.view.leadingAnchor.constraint(equalTo: productsListContainer.leadingAnchor),
//            tableViewController.view.trailingAnchor.constraint(equalTo: productsListContainer.trailingAnchor),
//            tableViewController.view.bottomAnchor.constraint(equalTo: productsListContainer.bottomAnchor)
//        ])
        
        tableViewController.didMove(toParent: self)
        productsTableViewController = tableViewController
        
        // ✅ QUAN TRỌNG: Set delegate để ProductsViewController xử lý didSelectRowAt trực tiếp
        // Điều này tránh gesture conflicts và cho phép view cha xử lý navigation
        if let tableView = tableViewController.tableView {
            tableView.delegate = self
            bindNavigationBar(to: tableView)
            // Bind scroll để thay đổi alpha của tabBar
            bindTabBarScroll(to: tableView)
        }
        
        // Đảm bảo label nằm dưới tableView trong z-order
        // Bằng cách đưa tableView lên trên label
        if let parentView = productsListContainer.superview {
            parentView.bringSubviewToFront(productsListContainer)
            // Label sẽ tự động nằm dưới vì được add vào view hierarchy trước
        }
    }
    
    /// Bind scroll để thay đổi alpha của tabBar khi scroll
    private func bindTabBarScroll(to scrollView: UIScrollView) {
        // TabBar alpha sẽ được update trong scrollViewDidScroll override
        // Store reference để sử dụng sau
    }
    
    // Track previous scroll offset để detect scroll direction
    private var previousScrollOffset: CGFloat = 0
    
    /// Khôi phục TabBar appearance ban đầu (không trong suốt)
    private func restoreTabBarAppearance(tabBar: UITabBar) {
        UIView.animate(withDuration: 0.2) {
            if #available(iOS 13.0, *) {
                let appearance = UITabBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = UIColor.white
                appearance.stackedLayoutAppearance.selected.iconColor = UIColor.black
                appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                    .foregroundColor: UIColor.black
                ]
                appearance.stackedLayoutAppearance.normal.iconColor = UIColor.gray
                appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                    .foregroundColor: UIColor.gray
                ]
                tabBar.standardAppearance = appearance
                if #available(iOS 15.0, *) {
                    tabBar.scrollEdgeAppearance = appearance
                }
            } else {
                tabBar.barTintColor = UIColor.white
                tabBar.isTranslucent = false
            }
        }
    }
    
    /// Reference đến TabBar để update alpha
    private var tabBarReference: UITabBar? {
        return findTabBarController()?.tabBar
    }
    
    /// Find TabBarController từ parent hierarchy
    private func findTabBarController() -> UITabBarController? {
        var responder: UIResponder? = self
        while responder != nil {
            responder = responder?.next
            if let tabBarController = responder as? UITabBarController {
                return tabBarController
            }
        }
        return nil
    }
    
    private func updateItems() {
        productsTableViewController?.reload()
        
        // Cập nhật UI khi items thay đổi (sau khi filter hoặc load)
        updateUIAfterFilter()
    }
    
    /// Cập nhật emptyDataLabel với thông tin AI search (luôn hiển thị để người dùng nhìn kết quả model một cách trực quan)
    private func updateEmptyDataLabelForAISearch() {
        guard let defaultProductsController = productsController as? DefaultProductsController else {
            // Nếu không phải AI search mode, dùng text mặc định
            emptyDataLabel.text = productsController.emptyDataTitle
            emptyDataLabel.numberOfLines = 1
            emptyDataLabel.textAlignment = .center
            return
        }
        
        // Kiểm tra xem có đang ở chế độ AI search không
        guard defaultProductsController.isAISearchMode,
              !defaultProductsController.aiSearchLabels.isEmpty else {
            // Không phải AI search mode, dùng text mặc định
            emptyDataLabel.text = productsController.emptyDataTitle
            emptyDataLabel.numberOfLines = 1
            emptyDataLabel.textAlignment = .center
            return
        }
        
        // Màu theme từ navigation bar
        let themeBlueColor = Colors.tokenRainbowBlueEnd
        let darkGreenColor = UIColor(red: 34/255.0, green: 139/255.0, blue: 34/255.0, alpha: 1.0) // Màu xanh lá hơi tối và dễ chịu
        let redColor = UIColor.systemRed
        
        // Font sizes
        let largeFont = UIFont.systemFont(ofSize: 18, weight: .bold)
        let mediumFont = UIFont.systemFont(ofSize: 16, weight: .bold)
        let regularFont = UIFont.systemFont(ofSize: 16, weight: .regular)
        let italicFont = UIFont.italicSystemFont(ofSize: 16)
        
        // Tạo attributed string
        let attributedString = NSMutableAttributedString()
        
        // 1. "MobileNetV2's result:" (chữ lớn, bold)
        let titleText = "MobileNetV2's result:\n"
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: largeFont,
            .foregroundColor: UIColor.label
        ]
        attributedString.append(NSAttributedString(string: titleText, attributes: titleAttributes))
        
        // 2. Danh sách labels với confidence (in nghiêng, màu xanh)
        for (index, (label, confidence)) in defaultProductsController.aiSearchLabels.enumerated() {
            let confidencePercent = String(format: "%.1f", confidence * 100)
            
            // Số thứ tự và label name (normal)
            let labelText = "\(index + 1). \(label) "
            let labelAttributes: [NSAttributedString.Key: Any] = [
                .font: regularFont,
                .foregroundColor: UIColor.label
            ]
            attributedString.append(NSAttributedString(string: labelText, attributes: labelAttributes))
            
            // Confidence (in nghiêng, màu xanh)
            let confidenceText = "(confidence: \(confidencePercent)%)\n"
            let confidenceAttributes: [NSAttributedString.Key: Any] = [
                .font: italicFont,
                .foregroundColor: themeBlueColor
            ]
            attributedString.append(NSAttributedString(string: confidenceText, attributes: confidenceAttributes))
        }
        
        // 3. "Từ khoá đã tokenization:" (chữ nhỏ hơn, bold)
        if !defaultProductsController.aiSearchKeywords.isEmpty {
            attributedString.append(NSAttributedString(string: "\n", attributes: [:]))
            
            let keywordsTitleText = "Từ khoá đã tokenization:\n"
            let keywordsTitleAttributes: [NSAttributedString.Key: Any] = [
                .font: mediumFont,
                .foregroundColor: UIColor.label
            ]
            attributedString.append(NSAttributedString(string: keywordsTitleText, attributes: keywordsTitleAttributes))
            
            // Danh sách keywords
            let keywordsText = defaultProductsController.aiSearchKeywords.joined(separator: ", ")
            let keywordsAttributes: [NSAttributedString.Key: Any] = [
                .font: regularFont,
                .foregroundColor: UIColor.label
            ]
            attributedString.append(NSAttributedString(string: keywordsText, attributes: keywordsAttributes))
        }
        
        // 4. Kết quả tìm kiếm
        let itemCount = productsController.items.value.count
        attributedString.append(NSAttributedString(string: "\n\n", attributes: [:]))
        
        if itemCount > 0 {
            // "Tìm thấy X sản phẩm phù hợp" (in nghiêng, màu xanh lá hơi tối)
            let resultText = "Tìm thấy \(itemCount) sản phẩm phù hợp"
            let resultAttributes: [NSAttributedString.Key: Any] = [
                .font: italicFont,
                .foregroundColor: darkGreenColor
            ]
            attributedString.append(NSAttributedString(string: resultText, attributes: resultAttributes))
        } else {
            // "Không tìm thấy sản phẩm nào" (màu đỏ, in nghiêng)
            let resultText = "Không tìm thấy sản phẩm nào"
            let resultAttributes: [NSAttributedString.Key: Any] = [
                .font: italicFont,
                .foregroundColor: redColor
            ]
            attributedString.append(NSAttributedString(string: resultText, attributes: resultAttributes))
        }
        
        emptyDataLabel.attributedText = attributedString
        emptyDataLabel.numberOfLines = 0 // Cho phép nhiều dòng
        emptyDataLabel.textAlignment = .left
    }
    
    // MARK: - Card Setup
    
    private func setupCardButton() {
        // Setup callback for card button tap - cast to implementation type to set callback
        if let defaultProductsController = productsController as? DefaultProductsController {
            defaultProductsController.onOpenCard = { [weak self] in
                self?.openCardViewController()
            }
            // Setup callback for camera button tap
            defaultProductsController.onOpenCamera = { [weak self] in
                self?.openAISearchCamera()
            }
            // Setup callback for back button tap (khi được push từ màn khác)
            defaultProductsController.onBack = { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
            // Setup callback for toggle tableView
            defaultProductsController.onToggleTableView = { [weak self] isHidden in
                self?.toggleTableView(isHidden: isHidden)
            }
        } else {
        }
    }
    
    /// Toggle ẩn/hiện tableView (chạy trên main thread)
    private func toggleTableView(isHidden: Bool) {
        // Đảm bảo chạy trên main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            UIView.animate(withDuration: 0.3) {
                self.productsListContainer.isHidden = isHidden
                self.productsListContainer.alpha = isHidden ? 0 : 1
                
                // Đảm bảo label luôn hiển thị để người dùng nhìn kết quả model
                self.emptyDataLabel.isHidden = false
                
                // Đảm bảo label nằm dưới tableView trong z-order
                // Khi tableView ẩn, label sẽ hiển thị phía dưới
                if let parentView = self.productsListContainer.superview {
                    if isHidden {
                        // Khi tableView ẩn, đưa label lên trên để hiển thị
                        parentView.bringSubviewToFront(self.emptyDataLabel)
                    } else {
                        // Khi tableView hiện, đưa tableView lên trên label
                        parentView.bringSubviewToFront(self.productsListContainer)
                    }
                }
                
                // Cập nhật label với thông tin AI search nếu có
                self.updateEmptyDataLabelForAISearch()
            }
        }
    }
    
    // Flag để tránh dismiss nhiều lần
    private var isDismissingCamera = false
    // Flag để tránh present camera nhiều lần
    private var isPresentingCamera = false
    
    private func openAISearchCamera() {
        
        // Kiểm tra xem đã có camera đang được present chưa
        if presentedViewController != nil {
            return
        }
        
        // Kiểm tra flag để tránh present nhiều lần
        guard !isPresentingCamera else {
            return
        }
        
        isPresentingCamera = true
        // Reset flag
        isDismissingCamera = false
        
        // Mở camera với chế độ .aiSearch
        presentAISearchCamera(
            onImageCaptured: { [weak self] image in
                // Image captured - labels will be handled separately
            },
            onLabelsDetected: { [weak self] labels in
                guard let self = self else { return }
                
                // Tránh dismiss nhiều lần
                guard !self.isDismissingCamera else {
                    return
                }
                
                self.isDismissingCamera = true
                
                // Filter items trước, sau đó mới dismiss camera
                self.handleAISearchLabels(labels)
                
                // Đợi một chút để đảm bảo filter đã hoàn thành, sau đó dismiss camera
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                    guard let self = self else { return }
                    
                    // Dismiss camera sau khi filter xong
                    if let presentedVC = self.presentedViewController {
                        presentedVC.dismiss(animated: true) { [weak self] in
                            guard let self = self else { return }
                            self.isDismissingCamera = false
                            
                            // Đảm bảo UI được cập nhật sau khi camera dismiss
                            DispatchQueue.main.async {
                                self.updateUIAfterFilter()
                            }
                        }
                    } else {
                        self.isDismissingCamera = false
                        
                        // Đảm bảo UI được cập nhật ngay cả khi không có presentedVC
                        DispatchQueue.main.async {
                            self.updateUIAfterFilter()
                        }
                    }
                }
            },
            onDismiss: { [weak self] in
                // Reset flag khi camera dismissed
                self?.isPresentingCamera = false
            }
        )
        
        // Reset flag sau một khoảng thời gian để tránh stuck
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.isPresentingCamera = false
        }
    }
    
    private func handleAISearchLabels(_ labels: [(String, Double)]) {
        // Filter items dựa trên labels từ camera model
        if let defaultProductsController = productsController as? DefaultProductsController {
            defaultProductsController.filterItemsByLabels(labels)
            
            // Reload tableView và cập nhật UI sau khi filter xong
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                // Reload tableView
                self.productsTableViewController?.reload()
                
                // Cập nhật UI (ẩn/hiện tableView và label)
                self.updateUIAfterFilter()
            }
        } else {
        }
    }
    
    /// Cập nhật UI sau khi filter (ẩn tableView nếu không có kết quả, hiển thị label với thông tin AI search)
    private func updateUIAfterFilter() {
        let isEmpty = productsController.isEmpty
        let defaultProductsController = productsController as? DefaultProductsController
        
        // Kiểm tra xem tableView có đang bị ẩn bởi toggle button không
        let isManuallyHidden = defaultProductsController?.isTableViewHidden ?? false
        
        // Ẩn tableView khi:
        // 1. Không có kết quả (vì label nằm dưới tableView trong z-stack-order)
        // 2. Hoặc đang bị ẩn bởi toggle button
        productsListContainer.isHidden = isEmpty || isManuallyHidden
        
        // Luôn hiển thị label để người dùng nhìn kết quả model một cách trực quan
        // Label sẽ luôn hiển thị thông tin AI search nếu có
        emptyDataLabel.isHidden = false
        
        // Cập nhật nội dung label với thông tin AI search (luôn hiển thị, không chỉ khi empty)
        updateEmptyDataLabelForAISearch()
    }
    
    private func setupProductSelection() {
        // Setup callback for product item selection
        if let defaultProductsController = productsController as? DefaultProductsController {
            defaultProductsController.onSelectProductItem = { [weak self] productItem in
                self?.navigateToProductDetail(productItem: productItem)
            }
        } else {
        }
    }
    
    private func navigateToProductDetail(productItem: ProductItemModel) {
        
        // Try to get navigation controller from different sources
        var navController: UINavigationController?
        
        // Method 1: Direct navigationController property
        navController = navigationController
        if navController != nil {
        } else {
        }
        
        // Method 2: Find ContentViewController (parent of SegmentedPageContainer) and get its navigation controller
        if navController == nil {
            // Find ContentViewController in parent hierarchy
            var currentVC: UIViewController? = self
            var depth = 0
            while currentVC != nil && depth < 10 {
                if let contentVC = currentVC as? ContentViewController {
                    navController = contentVC.navigationController
                    break
                }
                currentVC = currentVC?.parent ?? currentVC?.presentingViewController
                depth += 1
            }
            if navController == nil {
            }
        }
        
        // Method 3: Find parent navigation controller
        if navController == nil {
            if let parentVC = findParentViewController() {
                navController = parentVC.navigationController
                if navController != nil {
                } else {
                }
            } else {
            }
        }
        
        // Method 4: Find from parent view controller hierarchy
        if navController == nil {
            var parentVC = parent
            var depth = 0
            while parentVC != nil && depth < 10 {
                if let nav = parentVC?.navigationController {
                    navController = nav
                    break
                }
                parentVC = parentVC?.parent
                depth += 1
            }
            if navController == nil {
            }
        }
        
        // Method 5: Find TabBarController and get selected navigation controller
        if navController == nil {
            if let tabBarController: UITabBarController = findParentViewController() {
                if let selectedNav = tabBarController.selectedViewController as? UINavigationController {
                    navController = selectedNav
                } else {
                }
            } else {
            }
        }
        
        guard let navigationController = navController else {
            return
        }
        
        
        // Create ProductDetailDIContainer and CoordinatingController
        let appDIContainer = AppDIContainer()
        let productDetailDIContainer = appDIContainer.makeProductDetailDIContainer()
        
        let productDetailCoordinatingController = productDetailDIContainer.makeProductDetailCoordinatingController(
            navigationController: navigationController
        )
        
        // Navigate to ProductDetail
        productDetailCoordinatingController.start(productItem: productItem)
    }
}

// MARK: - UITableViewDelegate

extension ProductsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // ✅ QUAN TRỌNG: Xử lý push trực tiếp từ view cha
        // Điều này tránh gesture conflicts và cho phép navigation hoạt động ngay
        guard indexPath.row >= 0, indexPath.row < productsController.items.value.count else {
            return
        }
        
        let productItem = productsController.items.value[indexPath.row]
        
        navigateToProductDetail(productItem: productItem)
    }
}

// MARK: - UIScrollViewDelegate Override

extension ProductsViewController {
    
    // Override scrollViewDidScroll từ EcoBaseViewController để thêm logic cho tabBar alpha
    public override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Gọi super để xử lý navigation bar scroll
        super.scrollViewDidScroll(scrollView)
        
        // Update productListConstraint based on scroll progress
        updateProductListConstraint(for: scrollView)
        
        // Update tabBar alpha dựa trên scroll direction
        let currentOffset = scrollView.contentOffset.y
        let threshold: CGFloat = 50 // Ngưỡng để bắt đầu thay đổi alpha
        
        if let tabBar = tabBarReference {
            // Detect scroll direction
            let isScrollingDown = currentOffset > previousScrollOffset
            let isScrollingUp = currentOffset < previousScrollOffset
            
            if currentOffset > threshold {
                if isScrollingDown {
                    // Scroll xuống: Làm TabBar trong suốt để nhìn thấy nội dung phía sau
                    UIView.animate(withDuration: 0.2) {
                        if #available(iOS 13.0, *) {
                            // Tạo appearance mới với transparent background
                            let appearance = UITabBarAppearance()
                            appearance.configureWithTransparentBackground()
                            appearance.backgroundColor = UIColor.white.withAlphaComponent(0.6)
                            
                            // Giữ nguyên icon và text colors
                            appearance.stackedLayoutAppearance.selected.iconColor = UIColor.black
                            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                                .foregroundColor: UIColor.black
                            ]
                            appearance.stackedLayoutAppearance.normal.iconColor = UIColor.gray
                            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                                .foregroundColor: UIColor.gray
                            ]
                            
                            tabBar.standardAppearance = appearance
                            if #available(iOS 15.0, *) {
                                tabBar.scrollEdgeAppearance = appearance
                            }
                        } else {
                            // iOS 12 và trước: set barTintColor với alpha
                            tabBar.barTintColor = UIColor.white.withAlphaComponent(0.6)
                            tabBar.isTranslucent = true
                        }
                    }
                } else if isScrollingUp {
                    // Scroll lên: Khôi phục TabBar không trong suốt
                    restoreTabBarAppearance(tabBar: tabBar)
                }
            } else {
                // Ở đầu trang: Khôi phục TabBar không trong suốt
                restoreTabBarAppearance(tabBar: tabBar)
            }
        }
        
        // Update previous offset
        previousScrollOffset = currentOffset
    }
    
    /// Update productListConstraint based on scroll progress
    /// Constraint sẽ giảm từ navBarHeight xuống navBarCollapsedHeight khi scroll
    private func updateProductListConstraint(for scrollView: UIScrollView) {
        guard let productsController = productsController else { return }
        
        let navBarHeight = productsController.navigationBarInitialHeight
        let navBarCollapsed = productsController.navigationBarCollapsedHeight
        
        // Tính progress tương tự như trong EcoNavigationBarView.handleCollapseWithSearch
        let threshold: CGFloat = 50
        let maxOffset: CGFloat = 100
        let currentOffset = scrollView.contentOffset.y
        let progress = min(max((currentOffset - threshold) / (maxOffset - threshold), 0), 1)
        
        // Tính target constant: từ navBarHeight giảm dần xuống navBarCollapsed
        let heightDifference = navBarHeight - navBarCollapsed
        let targetConstant = navBarHeight - (heightDifference * progress)
        
        // Update constraint với animation mượt
        if abs(productListConstraint.constant - targetConstant) > 0.1 {
            productListConstraint.constant = targetConstant
            view.layoutIfNeeded()
        }
    }
}

extension ProductsViewController {
    
    private func openCardViewController() {
        
        // Check if card already exists and is still attached
        if let existingCard = cardViewController, existingCard.parent != nil {
            existingCard.show()
            return
        }
        
        // If card exists but is not attached (was dismissed), clean it up first
        if cardViewController != nil {
            cardViewController?.detach()
            cardViewController = nil
        }
        
        
        // Create Card Configuration
        // Expanded height: cách đỉnh 80pt (phủ gần đầy màn hình)
        // Collapsed height: không dùng vì chỉ có expanded và hidden
        let screenHeight = view.bounds.height
        let topPadding: CGFloat = 12
        let cardConfig = CardConfiguration(
            expandedHeight: screenHeight - topPadding,
            collapsedHeight: screenHeight - topPadding, // Same as expanded for full-screen-like behavior
            presentationMode: .onDemand,
            enableGesture: true
        )
        
        // Create Card Controller
        let cardController = DefaultCardController(configuration: cardConfig)
        
        // Create Card View Controller
        let cardVC = CardViewController.create(with: cardController)
        
        // Attach to current view controller
        cardVC.attach(to: self)
        
        // Create and set SignUpViewController as content
        setupSignUpContent(for: cardVC)
        
        // Store reference
        cardViewController = cardVC
        
        // Ensure view is laid out and parent view height is set before showing
        // Wait for next run loop to ensure view hierarchy is ready
        view.layoutIfNeeded()
        
        DispatchQueue.main.async { [weak cardVC, weak self] in
            guard let cardVC = cardVC, let self = self else { return }
            // Update parent view height to ensure it's correct (view bounds should be ready now)
            let height = self.view.bounds.height
            if height > 0 {
                cardVC.updateParentViewHeightIfNeeded()
                // Now show the card - this will animate from hidden to collapsed
                cardVC.show()
            } else {
                // If height is still 0, wait a bit more
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    cardVC.updateParentViewHeightIfNeeded()
                    cardVC.show()
                }
            }
        }
    }
    
    private func setupSignUpContent(for cardVC: CardViewController) {
        // Create AuthSceneDIContainer to get SignUpViewController
        let appDIContainer = AppDIContainer()
        let authSceneDIContainer = appDIContainer.makeAuthSceneDIContainer()
        
        // Create SignUpController and SignUpViewController
        let signUpController = authSceneDIContainer.makeSignUpController()
        let signUpVC = authSceneDIContainer.makeSignUpViewController()
        
        // Set SignUpViewController as content of CardViewController
        cardVC.setContent(signUpVC)
        
        // Setup callback for dismiss - cleanup when card is dismissed
        if let defaultCardController = cardVC.controller as? DefaultCardController {
            defaultCardController.onDismissed = { [weak self, weak cardVC] in
                // Option 1: Keep card for reuse (current behavior)
                // Card stays in memory, can be shown again quickly
                // deinit will only be called when ProductsViewController is deallocated
                
                // Option 2: Auto-cleanup on dismiss (uncomment to enable)
                // This will fully remove the card, requiring recreation on next show
                // guard let self = self, let cardVC = cardVC else { return }
                // cardVC.detach()
                // self.cardViewController = nil
                // print("🔵 [ProductsViewController] Card fully cleaned up - deinit should be called")
            }
        }
    }
    
//    deinit {
//        print("🔵 [ProductsViewController] deinit called")
//        // Cleanup card view controller when ProductsViewController is deallocated
//        cardViewController?.detach()
//        cardViewController = nil
//    }
}
