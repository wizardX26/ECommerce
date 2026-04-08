//
//  CategoryItemModel.swift
//  ECommerce
//
//  Created by wizard.os25 on 7/1/26.
//

import Foundation

struct CategoryItemModel: Equatable {
    let id: Int
    let name: String
    let title: String
    let description: String?
    let parentId: Int?
    let order: Int
}

extension CategoryItemModel {
    init(category: Category) {
        self.id = category.id
        self.name = category.name
        self.title = category.title
        self.description = category.description
        self.parentId = category.parentId
        self.order = category.order
    }
}
