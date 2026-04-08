//
//  SideMenuViewController.swift
//  ECommerce
//
//  Created by wizard.os25 on 17/11/25.
//

import UIKit

final class SideMenuViewController: UIViewController, StoryboardInstantiable {
    
    @IBOutlet weak var sideMenuContainer: UIView!
    @IBOutlet private var headerImageView: UIImageView!
    
    @IBOutlet weak var userEmailLabel: UILabel!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet private var footerLabel: UILabel!
    
    private var controller: SideMenuController!
    private var sideMenuTableViewController: SideMenuTableViewController?
    
    // MARK: - Lifecycle
    
    static func create(
        with controller: SideMenuController
    ) -> SideMenuViewController {
        let view = SideMenuViewController.instantiateViewController()
        view.controller = controller
        return view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupChildViewController()
        bind(to: controller)
        controller.viewDidLoad()
        loadUserInfo()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Refresh user info when view appears (in case user updated profile)
        loadUserInfo()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Set corner radius after layout (when bounds are available)
        headerImageView.layer.cornerRadius = headerImageView.bounds.width / 2
    }
    
    // MARK: - Private
    
    private func setupViews() {
        // Footer setup
        footerLabel.textColor = UIColor.white
        footerLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        footerLabel.text = controller.footerText
        
        // Setup header image view
        headerImageView.contentMode = .scaleAspectFill
        headerImageView.clipsToBounds = true
    }
    
    private func loadUserInfo() {
        let utilities = Utilities()
        
        // Load user name
        if let userName = utilities.getUserFullName() {
            userNameLabel.text = userName
        } else {
            userNameLabel.text = "User name here"
        }
        
        // Load user email
        if let userEmail = utilities.getUserEmail() {
            userEmailLabel.text = userEmail
        } else {
            userEmailLabel.text = "Email@email.com"
        }
        
        // Load user avatar
        if let avatarURL = utilities.getUserAvatarURL() {
            loadAvatarImage(from: avatarURL)
        } else {
            // Set default placeholder avatar
            headerImageView.image = UIImage(systemName: "person.circle.fill")
            headerImageView.tintColor = .white
        }
    }
    
    private func loadAvatarImage(from url: URL) {
        // Construct full URL if needed (handle relative paths)
        let fullURL: URL
        if url.absoluteString.hasPrefix("http") {
            fullURL = url
        } else {
            // If relative path, prepend base URL
            let appConfiguration = AppConfiguration()
            if let baseURL = URL(string: appConfiguration.apiBaseURL),
               let fullURLString = URL(string: url.absoluteString, relativeTo: baseURL) {
                fullURL = fullURLString
            } else {
                fullURL = url
            }
        }
        
        // Use DefaultImageCacheService to load image
        let imageCache = DefaultImageCacheService.shared
        imageCache.loadImage(from: fullURL) { [weak self] image in
            DispatchQueue.main.async {
                if let image = image {
                    self?.headerImageView.image = image
                    self?.headerImageView.tintColor = nil
                } else {
                    // If failed to load, show placeholder
                    self?.headerImageView.image = UIImage(systemName: "person.circle.fill")
                    self?.headerImageView.tintColor = .white
                }
            }
        }
    }
    
    private func setupChildViewController() {
        // Create SideMenuTableViewController using the same controller
        let tableViewController = SideMenuTableViewController.create(with: controller)
        
        // Add as child view controller using extension
        add(tableViewController, to: sideMenuContainer)
        sideMenuTableViewController = tableViewController
    }
    
    private func bind(to controller: SideMenuController) {
        // Binding is handled by SideMenuTableViewController
        // No need to bind here as the table view controller manages its own updates
    }
}

extension SideMenuViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.controller.horizontalScrollOffset.value = scrollView.contentOffset.x
        }
}
