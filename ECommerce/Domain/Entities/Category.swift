//
//  Category.swift
//  ECommerce
//
//  Created by wizard.os25 on 7/1/26.
//

import Foundation

struct Category: Identifiable {
    typealias Identifier = Int
    
    let id: Identifier
    let name: String
    let title: String
    let description: String?
    let parentId: Int?
    let order: Int
}
