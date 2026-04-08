//
//  NotificationViewController.swift
//  ECommerce
//
//  Created by wizard.os25 on 19/1/26.
//

import UIKit

class NotificationViewController: EcoViewController {
    
    // MARK: - Properties
    
    private let segmentedControl = UISegmentedControl(items: ["Read", "Unread"])
    var notificationContainerController: NotificationContainerController! {
        get { controller as? NotificationContainerController }
        set { controller = newValue }
    }
    
    // View Controllers for each tab
    private var readViewController: NotificationReadViewController!
    private var unreadViewController: NotificationUnreadViewController!
    
    private var currentViewController: UIViewController?
    
    // Timer for auto-updating relative time
    private var timer: Timer?
    
    // MARK: - Lifecycle
    
    static func create(
        with notificationContainerController: NotificationContainerController,
        readController: NotificationReadController,
        unreadController: NotificationUnreadController
    ) -> NotificationViewController {
        let view = NotificationViewController.instantiateViewController()
        view.controller = notificationContainerController
        view.configure(
            with: notificationContainerController,
            readController: readController,
            unreadController: unreadController
        )
        return view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupTimeChangeObservers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Refresh unread count when view appears
        notificationContainerController?.refreshUnreadCount()
        // Refresh relative time when view appears (in case device time changed)
        refreshRelativeTimes()
        // Start timer for auto-updating relative time
        startTimer()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Stop timer when view disappears
        stopTimer()
        // Remove observers
        removeTimeChangeObservers()
    }
    
    deinit {
        removeTimeChangeObservers()
    }
    
    // MARK: - Common Binding Override
    
    override func bindCommon() {
        super.bindCommon()
        bindUnreadCount()
    }
    
    // MARK: - Setup
    
    func configure(
        with notificationContainerController: NotificationContainerController,
        readController: NotificationReadController,
        unreadController: NotificationUnreadController
    ) {
        self.notificationContainerController = notificationContainerController
        
        // Create view controllers
        readViewController = NotificationReadViewController.create(with: readController)
        unreadViewController = NotificationUnreadViewController.create(with: unreadController)
        
        setupSegmentedControl()
        addChildViewControllers()
        updateSegmentTitles()
        
        // Show initial view controller (Unread)
        showViewController(unreadViewController)
        
        notificationContainerController.didLoad()
        
        // Setup callbacks for unread count refresh after a short delay to ensure controllers are initialized
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if let readController = readController as? DefaultNotificationReadController {
                readController.onNotificationDeleted = { [weak self] in
                    self?.notificationContainerController?.refreshUnreadCount()
                }
            }
            
            if let unreadController = unreadController as? DefaultNotificationUnreadController {
                unreadController.onNotificationRead = { [weak self] in
                    self?.notificationContainerController?.refreshUnreadCount()
                }
                
                // When notification is marked as read, add it to read list
                unreadController.onNotificationMarkedAsRead = { [weak self] notification in
                    if let readController = readController as? DefaultNotificationReadController {
                        readController.addNotification(notification)
                    }
                }
            }
        }
    }
    
    private func setupView() {
        view.backgroundColor = .systemBackground
    }
    
    private func setupSegmentedControl() {
        segmentedControl.selectedSegmentIndex = 1 // Default: "Unread"
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.addTarget(self, action: #selector(segmentControlValueChanged), for: .valueChanged)
        
        // Style segment control
        segmentedControl.backgroundColor = UIColor.white.withAlphaComponent(0.85)
        segmentedControl.selectedSegmentTintColor = UIColor.systemGray4
        
        // Set text attributes for normal state (unselected)
        segmentedControl.setTitleTextAttributes([
            .foregroundColor: UIColor.systemGray,
            .font: UIFont.systemFont(ofSize: 14, weight: .regular)
        ], for: .normal)
        
        // Set text attributes for selected state
        segmentedControl.setTitleTextAttributes([
            .foregroundColor: UIColor.black,
            .font: UIFont.systemFont(ofSize: 14, weight: .semibold)
        ], for: .selected)
        
        view.addSubview(segmentedControl)
        
        // Constraints: center horizontal, below navigation bar
        NSLayoutConstraint.activate([
            segmentedControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            segmentedControl.widthAnchor.constraint(equalToConstant: 200),
            segmentedControl.heightAnchor.constraint(equalToConstant: 32)
        ])
    }
    
    private func addChildViewControllers() {
        // Add both view controllers as child view controllers
        addChild(readViewController)
        readViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(readViewController.view)
        readViewController.didMove(toParent: self)
        
        addChild(unreadViewController)
        unreadViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(unreadViewController.view)
        unreadViewController.didMove(toParent: self)
        
        // Setup constraints for both views
        NSLayoutConstraint.activate([
            readViewController.view.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
            readViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            readViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            readViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            unreadViewController.view.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
            unreadViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            unreadViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            unreadViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc private func segmentControlValueChanged() {
        let index = segmentedControl.selectedSegmentIndex
        switch index {
        case 0:
            showViewController(readViewController)
        case 1:
            showViewController(unreadViewController)
        default:
            break
        }
    }
    
    private func showViewController(_ viewController: UIViewController) {
        // Hide current view controller
        if let current = currentViewController {
            current.view.isHidden = true
        }
        
        // Show new view controller
        viewController.view.isHidden = false
        currentViewController = viewController
    }
    
    private func bindUnreadCount() {
        notificationContainerController.unreadCount.observe(on: self) { [weak self] count in
            self?.updateSegmentTitles()
            // Refresh unread list when count changes (when new notification arrives)
            if let unreadViewController = self?.unreadViewController {
                // If unread tab is visible, refresh the list
                if unreadViewController.view.isHidden == false {
                    if let unreadController = unreadViewController.controller as? NotificationUnreadController {
                        unreadController.didRefresh()
                    }
                }
            }
        }
    }
    
    private func updateSegmentTitles() {
        let unreadCount = notificationContainerController.unreadCount.value
        let readTitle = "Read"
        let unreadTitle = unreadCount > 0 ? "Unread (\(unreadCount))" : "Unread"
        
        segmentedControl.setTitle(readTitle, forSegmentAt: 0)
        segmentedControl.setTitle(unreadTitle, forSegmentAt: 1)
    }
    
    // MARK: - Timer for Relative Time Update
    
    private func startTimer() {
        // Update relative time every minute (60 seconds)
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.refreshRelativeTimes()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func refreshRelativeTimes() {
        // Trigger reload for both read and unread views to update relative time
        DispatchQueue.main.async { [weak self] in
            self?.readViewController?.refreshTableView()
            self?.unreadViewController?.refreshTableView()
        }
    }
    
    // MARK: - Time Change Observers
    
    private func setupTimeChangeObservers() {
        // Observe when app enters foreground (time might have changed or new notifications arrived)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        // Observe when system timezone changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTimeChange),
            name: .NSSystemTimeZoneDidChange,
            object: nil
        )
        
        // Observe when a new push notification is received while app is running
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNewPushNotification),
            name: .newPushNotificationReceived,
            object: nil
        )
    }
    
    private func removeTimeChangeObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleAppEnterForeground() {
        // Refresh unread count and lists when app enters foreground
        notificationContainerController?.refreshUnreadCount()
        // Refresh relative time when device time changes
        refreshRelativeTimes()
    }
    
    @objc private func handleNewPushNotification() {
        // Refresh unread count when a new push notification arrives
        notificationContainerController?.refreshUnreadCount()
        
        // Refresh the currently visible tab's data
        if let unreadViewController = unreadViewController, !unreadViewController.view.isHidden {
            // If unread tab is visible, refresh its list
            if let unreadController = unreadViewController.controller as? NotificationUnreadController {
                unreadController.didRefresh()
            }
        } else if let readViewController = readViewController, !readViewController.view.isHidden {
            // If read tab is visible, refresh its list
            if let readController = readViewController.controller as? NotificationReadController {
                readController.didRefresh()
            }
        }
    }
    
    @objc private func handleTimeChange() {
        // Refresh relative time when device time changes
        refreshRelativeTimes()
    }
}