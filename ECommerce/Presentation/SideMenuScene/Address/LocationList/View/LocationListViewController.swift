//
//  LocationListViewController.swift
//  ECommerce
//
//  Created by wizard.os25 on 13/1/26.
//

import UIKit

final class LocationListViewController: EcoViewController {
    
    // MARK: - UI Components
    
    private let tableView = UITableView()
    
    private var locationListController: LocationListController! {
        get { controller as? LocationListController }
    }
    
    // MARK: - Lifecycle
    
    static func create(
        with locationListController: LocationListController
    ) -> LocationListViewController {
        let view = LocationListViewController.instantiateViewController()
        view.controller = locationListController
        return view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        bindLocationListSpecific()
        locationListController.viewDidLoad()
    }
    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        locationListController.onViewWillAppear()
//    }
    
    // MARK: - Common Binding Override
    
    override func bindCommon() {
        super.bindCommon()
        bindLocationListSpecific()
    }
    
    override func applyNavigation(_ state: EcoNavigationState) {
        super.applyNavigation(state)
        // Setup right button callback
        DispatchQueue.main.async { [weak self] in
            if let navBarController = self?.navigationBarViewController?.controller as? DefaultEcoNavigationBarController {
                // Right button "Save" action - dismiss card
                navBarController.onRightItemTap = { [weak self] index in
                    // Dismiss card if embedded in CardViewController
                    if let cardVC = self?.parent as? CardViewController {
                        cardVC.dismiss()
                    } else if let cardVC = self?.parent?.parent as? CardViewController {
                        cardVC.dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - LocationList-Specific Binding
    
    private func bindLocationListSpecific() {
        locationListController.addresses.observe(on: self) { [weak self] _ in
            self?.tableView.reloadData()
        }
        
        locationListController.error.observe(on: self) { [weak self] error in
            guard let self = self, let error = error else { return }
            self.showAlert(title: "Error", message: error.localizedDescription)
        }
        
        locationListController.loading.observe(on: self) { [weak self] isLoading in
            // Show/hide loading indicator if needed
        }
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        view.backgroundColor = .systemBackground
        
        // TableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .singleLine
        tableView.backgroundColor = .systemBackground
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        // Register cell
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "AddressCell")
        
        // Constraints
        let navBarHeight = locationListController.navigationBarInitialHeight
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: navBarHeight),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - Helper Methods
    
    private func getAddressesByType(_ type: String) -> [Address] {
        return locationListController.addresses.value.filter { $0.addressType == type }
    }
    
    private func getSectionTitle(for section: Int) -> String {
        switch section {
        case 0:
            return "Shipping Address"
        case 1:
            return "Shop Address"
        case 2:
            return "Other"
        default:
            return ""
        }
    }
    
    private func getAddressType(for section: Int) -> String {
        switch section {
        case 0:
            return "shipping"
        case 1:
            return "shop"
        case 2:
            return "other"
        default:
            return ""
        }
    }
}

// MARK: - UITableViewDataSource

extension LocationListViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3 // Shipping Address, Shop Address, Other
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let addressType = getAddressType(for: section)
        return getAddressesByType(addressType).count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AddressCell", for: indexPath)
        
        let addressType = getAddressType(for: indexPath.section)
        let addresses = getAddressesByType(addressType)
        
        guard indexPath.row < addresses.count else {
            return cell
        }
        
        let address = addresses[indexPath.row]
        cell.textLabel?.text = address.address
        cell.textLabel?.font = UIFont.systemFont(ofSize: 16)
        cell.detailTextLabel?.text = "\(address.contactPersonName) - \(address.contactPersonNumber)"
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 14)
        cell.detailTextLabel?.textColor = .gray
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let addressType = getAddressType(for: section)
        let addresses = getAddressesByType(addressType)
        return addresses.isEmpty ? nil : getSectionTitle(for: section)
    }
}

// MARK: - UITableViewDelegate

extension LocationListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let addressType = getAddressType(for: indexPath.section)
        let addresses = getAddressesByType(addressType)
        
        guard indexPath.row < addresses.count else {
            return
        }
        
        let address = addresses[indexPath.row]
        locationListController.didSelectAddress(address)
    }
}
