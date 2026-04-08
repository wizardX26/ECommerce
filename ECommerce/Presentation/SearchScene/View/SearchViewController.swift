//
//  SearchViewController.swift
//  ECommerce
//
//  Created by wizard.os25 on 9/1/26.
//

import UIKit

final class SearchViewController: EcoViewController {
    
    // MARK: - UI Components
    
    private let tableView = UITableView()
    
    private var searchController: SearchController! {
        get { controller as? SearchController }
    }
    
    // MARK: - Lifecycle
    
    static func create(
        with searchController: SearchController
    ) -> SearchViewController {
        let view = SearchViewController.instantiateViewController()
        view.controller = searchController
        return view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        bindSearchSpecific()
    }
    
    // MARK: - Common Binding Override
    
    override func bindCommon() {
        super.bindCommon()
        bindSearchSpecific()
    }
    
    override func applyNavigation(_ state: EcoNavigationState) {
        super.applyNavigation(state)
        // Setup search field callbacks
        DispatchQueue.main.async { [weak self] in
            if let navBarController = self?.navigationBarViewController?.controller as? DefaultEcoNavigationBarController {
                navBarController.onSearchTextChange = { [weak self] text in
                    // Cập nhật text khi user nhập (không call API)
                    self?.searchController.didUpdateSearchText(text)
                }
                navBarController.onSearchSubmit = { [weak self] text in
                    // Call API khi user nhấn Done/Return để ẩn bàn phím
                    if !text.isEmpty {
                        self?.searchController.didSearch(query: text)
                    }
                }
                navBarController.onSearchClear = { [weak self] in
                    self?.searchController.didClearSearch()
                    self?.searchController.didUpdateSearchText("")
                }
            }
        }
    }
    
    // MARK: - Search-Specific Binding
    
    private func bindSearchSpecific() {
        searchController.recentQueries.observe(on: self) { [weak self] _ in
            self?.tableView.reloadData()
        }
        
        searchController.loading.observe(on: self) { [weak self] isLoading in
            // Handle loading state if needed
        }
        
        searchController.error.observe(on: self) { [weak self] error in
            // Handle error state if needed
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
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "RecentQueryCell")
        
        // Constraints
        let navBarHeight = searchController.navigationBarInitialHeight
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: navBarHeight),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

// MARK: - UITableViewDataSource

extension SearchViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchController.recentQueries.value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RecentQueryCell", for: indexPath)
        
        let query = searchController.recentQueries.value[indexPath.row]
        cell.textLabel?.text = query.query
        cell.textLabel?.font = UIFont.systemFont(ofSize: 16)
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return searchController.recentQueries.value.isEmpty ? nil : "Recent search"
    }
}

// MARK: - UITableViewDelegate

extension SearchViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let query = searchController.recentQueries.value[indexPath.row]
        searchController.didSelectRecentQuery(query)
    }
}
