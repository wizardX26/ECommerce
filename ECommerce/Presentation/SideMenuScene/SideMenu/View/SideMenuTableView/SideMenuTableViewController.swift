//
//  SideMenuTableViewController.swift
//  ECommerce
//
//  Created by wizard.os25 on 18/11/25.
//

import UIKit

final class SideMenuTableViewController: UITableViewController, StoryboardInstantiable {
    
    private var controller: SideMenuController!
    
    // MARK: - Lifecycle
    
    static func create(
        with controller: SideMenuController
    ) -> SideMenuTableViewController {
        let viewController = SideMenuTableViewController.instantiateViewController()
        viewController.controller = controller
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        bind(to: controller)
        controller.viewDidLoad()
    }
    
    // MARK: - Private
    
    private func setupViews() {
        // TableView setup
        tableView.backgroundColor = #colorLiteral(red: 0, green: 0.3827145161, blue: 1, alpha: 1)
        tableView.separatorStyle = .none
        tableView.allowsMultipleSelection = false // Default behavior: only one cell selected at a time
        
        // Register TableView Cell
        tableView.register(cell: SideMenuCell.self)
        
        // Register divider cell
        tableView.register(cell: DividerCell.self)
    }
    
    private func bind(to controller: SideMenuController) {
        controller.firstSectionMenuItems.observe(on: self) { [weak self] _ in
            self?.updateMenuItems()
        }
        controller.secondSectionMenuItems.observe(on: self) { [weak self] _ in
            self?.updateMenuItems()
        }
        controller.selectedIndex.observe(on: self) { [weak self] selectedIndex in
            self?.updateSelectedIndex(controller.selectedSection.value, index: selectedIndex)
        }
        controller.selectedSection.observe(on: self) { [weak self] selectedSection in
            self?.updateSelectedIndex(selectedSection, index: controller.selectedIndex.value)
        }
    }
    
    private func updateMenuItems() {
        tableView.reloadData()
        updateSelectedIndex(controller.selectedSection.value, index: controller.selectedIndex.value)
    }
    
    private func updateSelectedIndex(_ section: Int, index: Int) {
        guard section >= 0 && section <= 1 else { return }
        let items = section == 0 ? controller.firstSectionMenuItems.value : controller.secondSectionMenuItems.value
        guard index >= 0 && index < items.count else { return }
        
        // Only update selection if it's different from current selection
        let indexPath = IndexPath(row: index, section: section)
        if let selectedIndexPaths = tableView.indexPathsForSelectedRows,
           selectedIndexPaths.contains(indexPath) {
            return // Already selected, no need to change
        }
        
        // Deselect all rows first to ensure only one item is selected
        if let selectedIndexPaths = tableView.indexPathsForSelectedRows {
            for selectedIndexPath in selectedIndexPaths {
                tableView.deselectRow(at: selectedIndexPath, animated: false)
            }
        }
        
        // Select the new row
        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
    }
}

// MARK: - UITableViewDelegate

extension SideMenuTableViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Divider row between sections
        if indexPath.section == 0 && indexPath.row == controller.firstSectionMenuItems.value.count {
            return 1 // Divider height
        }
        return 44
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Skip divider row
        if indexPath.section == 0 && indexPath.row == controller.firstSectionMenuItems.value.count {
            tableView.deselectRow(at: indexPath, animated: false)
            return
        }
        
        // Check if item should be selected
        guard controller.shouldSelectItem(at: indexPath.section, index: indexPath.row) else {
            tableView.deselectRow(at: indexPath, animated: false)
            return
        }
        
        // Let UITableView handle selection naturally, just update controller state
        controller.didSelectMenuItem(at: indexPath.section, index: indexPath.row)
        
        // Deselect certain items if needed (e.g., logout)
        if controller.shouldDeselectItem(at: indexPath.section, index: indexPath.row) {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        // Add spacing between sections to push section 2 closer to footer
        if section == 0 {
            let spacerView = UIView()
            spacerView.backgroundColor = .clear
            return spacerView
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        // Large spacing between section 0 and section 1 to push section 2 closer to footer
        if section == 0 {
            return 200 // Large spacing
        }
        return 0
    }
}

// MARK: - UITableViewDataSource

extension SideMenuTableViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            // Section 0: first section items + divider
            return controller.firstSectionMenuItems.value.count + 1
        } else {
            // Section 1: second section items
            return controller.secondSectionMenuItems.value.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Divider row between sections
        if indexPath.section == 0 && indexPath.row == controller.firstSectionMenuItems.value.count {
            let dividerCell: DividerCell = tableView.dequeueReusableCell(at: indexPath)
            return dividerCell
        }
        
        let cell: SideMenuCell = tableView.dequeueReusableCell(at: indexPath)
        let items = indexPath.section == 0 ? controller.firstSectionMenuItems.value : controller.secondSectionMenuItems.value
        let menuItem = items[indexPath.row]
        cell.fill(with: menuItem)
        
        // Section 2 items have smaller font and icon
        if indexPath.section == 1 {
            cell.titleLabel.font = Typography.fontRegular14
            // Icon size can be adjusted if needed
        } else {
            cell.titleLabel.font = Typography.fontRegular16
        }
        
        // Highlighted color
        let selectionColorView = UIView()
        selectionColorView.backgroundColor = #colorLiteral(red: 0.6196078431, green: 0.1098039216, blue: 0.2509803922, alpha: 1)
        cell.selectedBackgroundView = selectionColorView
        
        return cell
    }
}
