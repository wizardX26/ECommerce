// ContentViewController.swift (small fix)
import UIKit

class ContentViewController: UIViewController {
    
    // Helper to get AppDIContainer from parent hierarchy or create new one
    private func getAppDIContainer() -> AppDIContainer? {
        // Try to find MainContainerViewController in parent hierarchy
        if let _: MainContainerViewController = findParentViewController() {
            // MainContainer might have appDIContainer property in the future
            // For now, create new one as fallback
        }
        
        // Create new AppDIContainer as fallback
        // In production, you might want to pass DIContainer as dependency
        return AppDIContainer()
    }

    // MARK: - Properties

    private var segmentedPageContainer: SegmentedPageContainer!

    // Lưu index page hiện tại — lấy trực tiếp từ container
    var currentPageIndex: Int {
        return segmentedPageContainer.currentIndex
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupSegmentedPageContainer()
    }

    // MARK: - Setup Methods

    private func setupView() {
        view.backgroundColor = .systemBackground
    }

    private func setupSegmentedPageContainer() {
        // Create SegmentedPageContainer
        segmentedPageContainer = SegmentedPageContainer()
        segmentedPageContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(segmentedPageContainer)

        // Setup constraints
        NSLayoutConstraint.activate([
            segmentedPageContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            segmentedPageContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            segmentedPageContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            segmentedPageContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Create view controllers for SegmentedPageContainer
        // Tab 0: ProductsViewController
        // Tab 1: CategoryViewController
        guard let appDIContainer = getAppDIContainer() else {
            // Fallback: Create simple view controllers
            let productsVC = UIViewController()
            productsVC.view.backgroundColor = .systemBlue
            
            let categoryVC = UIViewController()
            categoryVC.view.backgroundColor = .systemPurple
            
            segmentedPageContainer.configUI(
                titles: ["products".localized(), "Category"],
                viewControllers: [productsVC, categoryVC],
                parent: self,
                defaultIndex: 0
            )
            return
        }
        
        // Use DI Container to create ProductsViewController
        let productsSceneDIContainer = appDIContainer.makeProductsSceneDIContainer()
        let productsViewController = productsSceneDIContainer.makeProductsViewController()
        
        // Use DI Container to create CategoryViewController
        let categorySceneDIContainer = appDIContainer.makeCategorySceneDIContainer()
        let categoryViewController = categorySceneDIContainer.makeCategoryViewController()
        
        // Configure SegmentedPageContainer
        segmentedPageContainer.configUI(
            titles: ["Products", "Category"],
            viewControllers: [productsViewController, categoryViewController],
            parent: self,
            defaultIndex: 0
        )

        // Optional: Handle tab change callback
        segmentedPageContainer.onTabChanged = { [weak self] index in
        }
    }
}
