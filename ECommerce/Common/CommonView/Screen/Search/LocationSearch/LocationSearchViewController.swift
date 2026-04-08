//
//  LocationSearchViewController.swift
//  ECommerce
//
//  Created by wizard.os25 on 11/1/26.
//

import UIKit

final class LocationSearchViewController: EcoViewController {
    
    // MARK: - UI Components
    
    private let tableView = UITableView()
    
    private var locationSearchController: LocationSearchController! {
        get { controller as? LocationSearchController }
    }
    
    // MARK: - Lifecycle
    
    static func create(
        with locationSearchController: LocationSearchController
    ) -> LocationSearchViewController {
        let view = LocationSearchViewController.instantiateViewController()
        view.controller = locationSearchController
        return view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        bindLocationSearchSpecific()
    }
    
    // MARK: - Common Binding Override
    
    override func bindCommon() {
        super.bindCommon()
        bindLocationSearchSpecific()
    }
    
    override func applyNavigation(_ state: EcoNavigationState) {
        super.applyNavigation(state)
        // Setup search field callbacks
        DispatchQueue.main.async { [weak self] in
            if let navBarController = self?.navigationBarViewController?.controller as? DefaultEcoNavigationBarController {
                navBarController.onSearchTextChange = { [weak self] text in
                    self?.locationSearchController.didSearch(keyword: text)
                }
                navBarController.onSearchSubmit = { [weak self] text in
                    // Khi submit từ search bar, chỉ search lại keyword (không chọn vì chưa có coordinate)
                    // User cần chọn từ suggestions để có coordinate
                    if !text.isEmpty {
                        self?.locationSearchController.didSearch(keyword: text)
                    }
                }
                navBarController.onSearchClear = { [weak self] in
                    self?.locationSearchController.didClearSearch()
                }
            }
        }
    }
    
    // MARK: - LocationSearch-Specific Binding
    
    private func bindLocationSearchSpecific() {
        locationSearchController.searchSuggestions.observe(on: self) { [weak self] _ in
            self?.tableView.reloadData()
        }
        
        locationSearchController.recentSearches.observe(on: self) { [weak self] _ in
            self?.tableView.reloadData()
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
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "KeywordCell")
        
        // Constraints - navbar luôn 80pt, không collapse
        let navBarHeight = locationSearchController.navigationBarInitialHeight
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: navBarHeight),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Không cần bind navigation bar vì scrollBehavior là .sticky (luôn hiển thị)
    }
}

// MARK: - UITableViewDataSource

extension LocationSearchViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return locationSearchController.searchSuggestions.value.count
        } else {
            return locationSearchController.recentSearches.value.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "KeywordCell", for: indexPath)
        
        if indexPath.section == 0 {
            let keyword = locationSearchController.searchSuggestions.value[indexPath.row]
            cell.textLabel?.text = keyword.keyword
        } else {
            let keyword = locationSearchController.recentSearches.value[indexPath.row]
            cell.textLabel?.text = keyword.keyword
        }
        
        cell.textLabel?.font = UIFont.systemFont(ofSize: 16)
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return locationSearchController.searchSuggestions.value.isEmpty ? nil : "Suggestions"
        } else {
            return locationSearchController.recentSearches.value.isEmpty ? nil : "Recent Search"
        }
    }
}

// MARK: - UITableViewDelegate

extension LocationSearchViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 {
            // Section 0: Search suggestions (có coordinate) - cho phép chọn
            let keyword = locationSearchController.searchSuggestions.value[indexPath.row]
            locationSearchController.didSelectKeyword(keyword)
        } else {
            // Section 1: Recent searches - chọn keyword đó (có coordinate từ history)
            let recentKeyword = locationSearchController.recentSearches.value[indexPath.row]
            // Nếu recent search có coordinate, chọn luôn; nếu không, search lại
            if recentKeyword.coordinate != nil {
                locationSearchController.didSelectKeyword(recentKeyword)
            } else {
                // Không có coordinate, search lại để lấy suggestions
                locationSearchController.didSearch(keyword: recentKeyword.keyword)
            }
        }
    }
}
