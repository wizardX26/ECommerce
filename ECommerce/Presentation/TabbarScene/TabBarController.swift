//
//  TabBarController.swift
//  MyKiot
//
//  Created by Nguyen Duc Hung on 3/6/25.
//

import UIKit

class TabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Tab 0: Home (ContentViewController với SegmentedPageContainer)
        let contentVC = ContentViewController()
        
        // Tab 1: Search - SearchViewController
        let appDIContainer = AppDIContainer.shared
        let searchSceneDIContainer = appDIContainer.makeSearchSceneDIContainer()
        let searchVC = searchSceneDIContainer.makeSearchViewController()
        
        // Setup search callbacks để navigate đến ProductsViewController
        setupSearchCallbacks(searchVC, searchSceneDIContainer: searchSceneDIContainer)
        
        // Tab 2: Cart - CartViewController
        let cartSceneDIContainer = appDIContainer.makeCartSceneDIContainer()
        let cartVC = cartSceneDIContainer.makeCartViewController()
        
        // Tab 3: Notification - NotificationViewController
        let notificationSceneDIContainer = appDIContainer.makeNotificationSceneDIContainer()
        let notificationVC = notificationSceneDIContainer.makeNotificationViewController()
        
        // Wrap in Navigation Controllers
        let navTabContainer = UINavigationController(rootViewController: contentVC)
        let navSearch = UINavigationController(rootViewController: searchVC)
        let navCart = UINavigationController(rootViewController: cartVC)
        let navNotification = UINavigationController(rootViewController: notificationVC)
        
        // Set delegates to track navigation
        navTabContainer.delegate = self
        navSearch.delegate = self
        navCart.delegate = self
        navNotification.delegate = self
        
        // Hide system navigation bar since we use custom EcoNavigationBar
        navTabContainer.isNavigationBarHidden = true
        navSearch.isNavigationBarHidden = true
        navCart.isNavigationBarHidden = true
        navNotification.isNavigationBarHidden = true
        
        /// Set TabBar item - Home (Trang chủ), Search, Cart, Notification
        contentVC.tabBarItem = UITabBarItem(title: "Trang chủ", image: UIImage(systemName: "house"), tag: 0)
        searchVC.tabBarItem = UITabBarItem(title: "search".localized(), image: UIImage(systemName: "magnifyingglass"), tag: 1)
        cartVC.tabBarItem = UITabBarItem(title: "cart".localized(), image: UIImage(systemName: "cart"), tag: 2)
        notificationVC.tabBarItem = UITabBarItem(title: "notification".localized(), image: UIImage(systemName: "bell"), tag: 3)
        
        // Set ViewControllers
        self.setViewControllers([navTabContainer, navSearch, navCart, navNotification], animated: true)
        
        // Add child view controllers (QUAN TRỌNG - theo best practice)
        self.addChild(navTabContainer)
        self.addChild(navSearch)
        self.addChild(navCart)
        self.addChild(navNotification)
        
        // Configure TabBar appearance
        configureTabBarAppearance()
    }
    
    // MARK: - TabBar Appearance Configuration
    
    private func configureTabBarAppearance() {
        // Màu nền TabBar
        UITabBar.appearance().barTintColor = UIColor.white
        
        // Màu tint cho selected item
        self.tabBar.tintColor = .black
        
        // Font cho tab bar items (system font)
        let font = UIFont.systemFont(ofSize: 12, weight: .regular)
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.gray
        ]
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.black
        ]
        
        UITabBarItem.appearance().setTitleTextAttributes(normalAttributes, for: .normal)
        UITabBarItem.appearance().setTitleTextAttributes(selectedAttributes, for: .selected)
        
        // iOS 13+ Appearance
        if #available(iOS 13.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.white
            
            // Màu cho selected state
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor.black
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor.black
            ]
            
            // Màu cho normal state
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor.gray
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor.gray
            ]
            
            self.tabBar.standardAppearance = appearance
            if #available(iOS 15.0, *) {
                self.tabBar.scrollEdgeAppearance = appearance
            }
        }
        
        // Add shadow to tabBar
        self.tabBar.layer.shadowColor = UIColor.black.cgColor
        self.tabBar.layer.shadowOffset = CGSize(width: 0, height: -2)
        self.tabBar.layer.shadowRadius = 4
        self.tabBar.layer.shadowOpacity = 0.1
    }
    
    // MARK: - TabBar Visibility Methods (for sideMenu)
    
    func hideTabBar() {
        tabBar.isHidden = true
    }
    
    func showTabBar() {
        tabBar.isHidden = false
    }
    
    // MARK: - Search Callbacks Setup
    
    private func setupSearchCallbacks(_ searchViewController: SearchViewController, searchSceneDIContainer: SearchSceneDIContainer) {
        guard var searchController = searchViewController.controller as? SearchController else {
            return
        }
        
        searchController.onSearchResult = { [weak self] productPage, query in
            guard let self = self else { return }
            
            // Tìm navigation controller của Search tab
            guard let navSearch = self.viewControllers?[1] as? UINavigationController else {
                return
            }
            
            // Create ProductsViewController
            let productsViewController = searchSceneDIContainer.makeProductsViewController()
            
            // Push ProductsViewController
            navSearch.pushViewController(productsViewController, animated: true)
            
            // Load products from search result and set title
            if let productsController = productsViewController.controller as? DefaultProductsController {
                // Set flag để đánh dấu được push từ search
                productsController.setPushedFromOtherScreen(true)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // Cancel any default loading
                    productsController.didCancelSearch()
                    
                    // Load products from search result
                    productsController.loadProductsFromPage(productPage, query: query)
                    
                    // Set navigation bar title to "Result for {query}"
                    var currentState = productsController.navigationState.value
                    currentState.title = "Result for \(query)"
                    productsController.navigationState.value = currentState
                }
            }
        }
    }
}

// MARK: - UINavigationControllerDelegate

extension TabBarController: UINavigationControllerDelegate {
    
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        // Navigation delegate - có thể thêm logic khác nếu cần
    }
}

