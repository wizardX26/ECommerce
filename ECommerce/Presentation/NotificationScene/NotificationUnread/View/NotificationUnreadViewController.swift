//
//  NotificationUnreadViewController.swift
//  ECommerce
//
//  Created by wizard.os25 on 19/1/26.
//

import UIKit

final class NotificationUnreadViewController: EcoViewController {
    
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
        button.backgroundColor = Colors.tokenRainbowBlueEnd
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.setTitle("Mark as read", for: .normal)
        button.isHidden = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private var actionButtonBottomConstraint: NSLayoutConstraint?
    
    // Timer for auto-updating relative time
    private var timer: Timer?
    
    private var notificationUnreadController: NotificationUnreadController! {
        get { controller as? NotificationUnreadController }
    }
    
    // MARK: - Lifecycle
    
    static func create(
        with notificationUnreadController: NotificationUnreadController
    ) -> NotificationUnreadViewController {
        let view = NotificationUnreadViewController.instantiateViewController()
        view.controller = notificationUnreadController
        return view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        bindNotificationUnreadSpecific()
        setupNavigation()
        setupTimeChangeObservers()
        notificationUnreadController.didLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Refresh data when view appears (in case new notifications arrived)
        notificationUnreadController.didRefresh()
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
    
    private func bindNotificationUnreadSpecific() {
        notificationUnreadController.items.observe(on: self) { [weak self] _ in
            self?.tableView.reloadData()
        }
        
        notificationUnreadController.isSelectionMode.observe(on: self) { [weak self] isSelectionMode in
            self?.actionButton.isHidden = !isSelectionMode
        }
        
        notificationUnreadController.selectedItems.observe(on: self) { [weak self] selectedItems in
            self?.actionButton.isEnabled = !selectedItems.isEmpty
        }
        
        notificationUnreadController.loading.observe(on: self) { [weak self] isLoading in
            if isLoading {
                // Show loading indicator
            } else {
                // Hide loading indicator
            }
        }
        
        notificationUnreadController.error.observe(on: self) { [weak self] error in
            guard let error = error else { return }
            self?.showAlert(title: "Error", message: error.localizedDescription)
        }
    }
    
    @objc private func actionButtonTapped() {
        notificationUnreadController.didMarkAllAsRead()
    }
    
    // MARK: - Common Binding Override
    
    override func bindCommon() {
        super.bindCommon()
        bindNotificationUnreadSpecific()
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
            notificationUnreadController.didRefresh()
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

extension NotificationUnreadViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notificationUnreadController.items.value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NotificationCell", for: indexPath) as! NotificationCell
        
        guard indexPath.row < notificationUnreadController.items.value.count else {
            return cell
        }
        
        let item = notificationUnreadController.items.value[indexPath.row]
        cell.configure(with: item)
        cell.onSelectionButtonTap = { [weak self] in
            self?.notificationUnreadController.didSelectItem(at: indexPath.row)
        }
        return cell
    }
}

// MARK: - UITableViewDelegate

extension NotificationUnreadViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        notificationUnreadController.didSelectItem(at: indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.row < notificationUnreadController.items.value.count else {
            return nil
        }
        
        let item = notificationUnreadController.items.value[indexPath.row]
        
        let markAsReadAction = UIContextualAction(style: .normal, title: "Mark as read") { [weak self] _, _, completion in
            self?.notificationUnreadController.markAsRead(id: item.id)
            completion(true)
        }
        markAsReadAction.backgroundColor = Colors.tokenRainbowBlueEnd
        
        return UISwipeActionsConfiguration(actions: [markAsReadAction])
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.row < notificationUnreadController.items.value.count else {
            return nil
        }
        
        let item = notificationUnreadController.items.value[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            guard let self = self else {
                completion(false)
                return
            }
            self.notificationUnreadController.deleteNotification(id: item.id) { success in
                DispatchQueue.main.async {
                    if success {
                        var items = self.notificationUnreadController.items.value
                        items.removeAll { $0.id == item.id }
                        self.notificationUnreadController.items.value = items
                        self.notificationUnreadController.onNotificationRead?()
                    }
                    completion(success)
                }
            }
        }
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}