//
//  CategoryViewController.swift
//  ECommerce
//
//  Created by wizard.os25 on 7/1/26.
//

import UIKit

final class CategoryViewController: EcoViewController {
    
    private var categoryController: CategoryController! {
        get { controller as? CategoryController }
    }
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .white
        cv.delegate = self
        cv.dataSource = self
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.register(CategoryItemCell.self, forCellWithReuseIdentifier: CategoryItemCell.cellReuseIdentifier)
        return cv
    }()
    
    // MARK: - Lifecycle
    
    static func create(
        with categoryController: CategoryController
    ) -> CategoryViewController {
        let view = CategoryViewController.instantiateViewController()
        view.controller = categoryController
        return view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        bindCategorySpecific()
        setupCategorySelection()
    }
    
    // MARK: - Common Binding Override
    
    override func bindCommon() {
        super.bindCommon()
        bindCategorySpecific()
    }
    
    // MARK: - Category-Specific Binding
    
    private func bindCategorySpecific() {
        categoryController.items.observe(on: self) { [weak self] _ in
            self?.updateItems()
        }
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        view.backgroundColor = .white
        view.addSubview(collectionView)
        
        // Get navigation bar height for top padding
        let navBarHeight = categoryController.navigationBarInitialHeight
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: navBarHeight),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupCategorySelection() {
        if let defaultCategoryController = categoryController as? DefaultCategoryController {
            defaultCategoryController.onSelectCategory = { [weak self] categoryItem in
                self?.navigateToProducts(categoryItem: categoryItem)
            }
        }
    }
    
    private func updateItems() {
        DispatchQueue.main.async { [weak self] in
            self?.collectionView.reloadData()
        }
    }
    
    // MARK: - Navigation
    
    private func navigateToProducts(categoryItem: CategoryItemModel) {
        // Find navigation controller
        guard let navigationController = findNavigationController() else {
            return
        }
        
        // Create ProductsViewController with order query and title
        let appDIContainer = AppDIContainer()
        let productsSceneDIContainer = appDIContainer.makeProductsSceneDIContainer()
        let productsViewController = productsSceneDIContainer.makeProductsViewController()
        
        // Push ProductsViewController first
        navigationController.pushViewController(productsViewController, animated: true)
        
        // Update products query with order value after view is fully loaded
        // Use DispatchQueue.main.asyncAfter to ensure onViewDidLoad has completed and initial load has started
        // This allows us to cancel the default query load and load the correct query
        if let productsController = productsViewController.controller as? DefaultProductsController {
            // Set flag để đánh dấu được push từ category
            productsController.setPushedFromOtherScreen(true)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // Cancel any task that was started by onViewDidLoad (default query "")
                productsController.didCancelSearch()
                
                // Now update query with order value - this calls update(productQuery:) 
                // which resets pages and loads fresh data from network (not cache for different query)
                productsController.didSearch(query: "\(categoryItem.order)")
                
                // Set navigation bar title to category title
                var currentState = productsController.navigationState.value
                currentState.title = categoryItem.title
                productsController.navigationState.value = currentState
            }
        }
    }
    
    private func findNavigationController() -> UINavigationController? {
        // Method 1: Direct navigationController property
        if let navController = navigationController {
            return navController
        }
        
        // Method 2: Find from parent hierarchy
        var currentVC: UIViewController? = self
        var depth = 0
        while currentVC != nil && depth < 10 {
            if let navController = currentVC?.navigationController {
                return navController
            }
            currentVC = currentVC?.parent ?? currentVC?.presentingViewController
            depth += 1
        }
        
        return nil
    }
}

// MARK: - UICollectionViewDataSource

extension CategoryViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categoryController.items.value.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: CategoryItemCell.cellReuseIdentifier,
            for: indexPath
        ) as! CategoryItemCell
        
        let categoryItem = categoryController.items.value[indexPath.item]
        cell.configure(with: categoryItem)
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension CategoryViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        categoryController.didSelectItem(at: indexPath.item)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension CategoryViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // 3 items per row with 12pt spacing and 12pt margins on each side
        let totalSpacing: CGFloat = 12 * 4 // 12pt left + 12pt between items (2 gaps) + 12pt right = 48pt
        let width = (collectionView.frame.width - totalSpacing) / 3
        let height: CGFloat = 144 // Fixed height: 120 + 24pt
        
        return CGSize(width: width, height: height)
    }
}

// MARK: - CategoryItemCell

final class CategoryItemCell: UICollectionViewCell {
    
    static let cellReuseIdentifier = String(describing: CategoryItemCell.self)
    
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // Shadow container for circular image with shadow effect
    private let shadowContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        // Shadow will be applied to this container
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.2
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.layer.masksToBounds = false
        return view
    }()
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .systemGray5
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .black
        label.textAlignment = .center
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(shadowContainerView)
        shadowContainerView.addSubview(imageView)
        containerView.addSubview(titleLabel)
        
        // Setup container view
        containerView.backgroundColor = .clear
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            shadowContainerView.topAnchor.constraint(equalTo: containerView.topAnchor),
            shadowContainerView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            shadowContainerView.widthAnchor.constraint(equalTo: shadowContainerView.heightAnchor),
            shadowContainerView.heightAnchor.constraint(lessThanOrEqualToConstant: 80), // Max size for circular image
            
            imageView.topAnchor.constraint(equalTo: shadowContainerView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: shadowContainerView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: shadowContainerView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: shadowContainerView.bottomAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: shadowContainerView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Make image and shadow container circular after layout
        let containerSize = min(shadowContainerView.frame.width, shadowContainerView.frame.height)
        
        // Set corner radius for image view (clips to bounds for circular shape)
        imageView.layer.cornerRadius = containerSize / 2
        
        // Set corner radius for shadow container (for shadow shape)
        shadowContainerView.layer.cornerRadius = containerSize / 2
    }
    
    // MARK: - Configuration
    
    func configure(with categoryItem: CategoryItemModel) {
        titleLabel.text = categoryItem.title
        
        // Load image from Assets.xcassets based on category id
        // Compare id with imageset name (e.g., id=3 → "3.imageset", id=4 → "4.imageset")
        let imageName = "\(categoryItem.id)"
        if let image = UIImage(named: imageName) {
            imageView.image = image
            imageView.backgroundColor = nil
        } else {
            // If image not found in assets, use placeholder
            imageView.image = nil
            imageView.backgroundColor = .systemGray5
        }
    }
}
