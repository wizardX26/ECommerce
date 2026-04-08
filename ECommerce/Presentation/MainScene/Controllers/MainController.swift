//
//  MainController.swift
//  ECommerce
//
//  Created by wizard.os25 on 18/11/25.
//

import Foundation

protocol MainControllerInput {
    func viewDidLoad()
    func setSidebarExpanded(_ expanded: Bool)
    func toggleSidebar()
}

protocol MainControllerOutput {
    var isSidebarExpanded: Observable<Bool> { get }
}

protocol MainControllerDelegate: AnyObject {
    func didSelectMenuItem(at index: Int)
}

typealias MainController = MainControllerInput & MainControllerOutput

final class DefaultMainController: MainController {
    
    // MARK: - OUTPUT
    
    let isSidebarExpanded: Observable<Bool> = Observable(false)
    
    // MARK: - Private
    
    private weak var delegate: MainControllerDelegate?
    
    // MARK: - Init
    
    init(delegate: MainControllerDelegate?) {
        self.delegate = delegate
    }
    
    // MARK: - INPUT
    
    func viewDidLoad() {
        // Initialize if needed
        // Sidebar starts collapsed by default
    }
    
    func setSidebarExpanded(_ expanded: Bool) {
        isSidebarExpanded.value = expanded
    }
    
    func toggleSidebar() {
        isSidebarExpanded.value.toggle()
    }
    
    func didSelectMenuItem(at index: Int) {
        delegate?.didSelectMenuItem(at: index)
    }
}
