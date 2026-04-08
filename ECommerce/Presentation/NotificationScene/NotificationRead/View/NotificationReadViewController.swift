//
//  NotificationReadViewController.swift
//  ECommerce
//
//  Created by wizard.os25 on 19/1/26.
//

import UIKit

final class NotificationReadViewController: EcoViewController {
    
    // MARK: - UI Components
    
    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .systemBackground
        tv.separatorStyle = .none
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.estimatedRowHeight = NotificationCell.height
        tv.rowHeight = UITableView.automaticDimension
        return tv
    }()
    
    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = Colors.tokenRed100
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.setTitle("Delete notification", for: .normal)
        button.isHidden = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private var actionButtonBottomConstraint: NSLayoutConstraint?
    
    // Timer for auto-updating relative time
    private var timer: Timer?
    
    private var notificationReadController: NotificationReadController! {
        get { controller as? NotificationReadController }
    }
    
    // MARK: - Lifecycle
    
    static func create(
        with notificationReadController: NotificationReadController
    ) -> NotificationReadViewController {
        let view = NotificationReadViewController.instantiateViewController()
        view.controller = notificationReadController
        return view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        bindNotificationReadSpecific()
        setupNavigation()
        setupTimeChangeObservers()
        notificationReadController.didLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Refresh data when view appears (in case new notifications arrived)
        notificationReadController.didRefresh()
        // Refresh relative time when view appears (in case device time changed)
        refreshRelativeTime()
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
    
    // MARK: - Setup
    
    private func setupViews() {
        view.backgroundColor = .systemBackground
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(NotificationCell.self, forCellReuseIdentifier: "NotificationCell")
        view.addSubview(tableView)
        
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        view.addSubview(actionButton)
        
        let bottomConstraint = actionButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        actionButtonBottomConstraint = bottomConstraint
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: actionButton.topAnchor),
            
            actionButton.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            actionButton.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            actionButton.heightAnchor.constraint(equalToConstant: 50),
            bottomConstraint
        ])
    }
    
    private func setupNavigation() {
        // Navigation is handled by controller
    }
    
    // MARK: - Binding
    
    private func bindNotificationReadSpecific() {
        notificationReadController.items.observe(on: self) { [weak self] _ in
            self?.tableView.reloadData()
        }
        
        notificationReadController.isSelectionMode.observe(on: self) { [weak self] isSelectionMode in
            self?.actionButton.isHidden = !isSelectionMode
        }
        
        notificationReadController.selectedItems.observe(on: self) { [weak self] selectedItems in
            self?.actionButton.isEnabled = !selectedItems.isEmpty
        }
        
        notificationReadController.loading.observe(on: self) { [weak self] isLoading in
            if isLoading {
                // Show loading indicator
            } else {
                // Hide loading indicator
            }
        }
        
        notificationReadController.error.observe(on: self) { [weak self] error in
            guard let error = error else { return }
            self?.showAlert(title: "Error", message: error.localizedDescription)
        }
    }
    
    @objc private func actionButtonTapped() {
        notificationReadController.didDeleteSelectedNotifications()
    }
    
    // MARK: - Common Binding Override
    
    override func bindCommon() {
        super.bindCommon()
        bindNotificationReadSpecific()
    }
    
    // MARK: - Timer for Relative Time Update
    
    private func startTimer() {
        // Update relative time every minute (60 seconds)
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.refreshRelativeTime()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func refreshRelativeTime() {
        tableView.reloadData()
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
    }
    
    private func removeTimeChangeObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleAppEnterForeground() {
        // Refresh data when app enters foreground (new notifications might have arrived)
        if !view.isHidden {
            notificationReadController.didRefresh()
        }
        // Refresh relative time when device time changes
        DispatchQueue.main.async { [weak self] in
            self?.refreshRelativeTime()
        }
    }
    
    @objc private func handleTimeChange() {
        // Refresh relative time when device time changes
        DispatchQueue.main.async { [weak self] in
            self?.refreshRelativeTime()
        }
    }
    
    // MARK: - Public Methods
    
    func refreshTableView() {
        refreshRelativeTime()
    }
}

// MARK: - UITableViewDataSource

extension NotificationReadViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notificationReadController.items.value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NotificationCell", for: indexPath) as! NotificationCell
        
        guard indexPath.row < notificationReadController.items.value.count else {
            return cell
        }
        
        let item = notificationReadController.items.value[indexPath.row]
        cell.configure(with: item)
        cell.onSelectionButtonTap = { [weak self] in
            self?.notificationReadController.didSelectItem(at: indexPath.row)
        }
        return cell
    }
}

// MARK: - UITableViewDelegate

extension NotificationReadViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        notificationReadController.didSelectItem(at: indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // No leading swipe actions for read notifications
        return nil
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.row < notificationReadController.items.value.count else {
            return nil
        }
        
        let item = notificationReadController.items.value[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            guard let self = self else {
                completion(false)
                return
            }
            
            // Store the item ID before deletion
            let itemId = item.id
            
            self.notificationReadController.deleteNotification(id: itemId) { success in
                DispatchQueue.main.async {
                    if success {
                        // Remove from items safely
                        var items = self.notificationReadController.items.value
                        items.removeAll { $0.id == itemId }
                        self.notificationReadController.items.value = items
                        
                        // Reload tableView to ensure UI is updated
                        self.tableView.reloadData()
                    }
                    completion(success)
                }
            }
        }
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}