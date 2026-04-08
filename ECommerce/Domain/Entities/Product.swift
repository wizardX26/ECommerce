//
//  Product.swift
//  ExampleMVVM
//
//  Created by wizard.os25 on 14/11/25.
//

import Foundation

struct ProductPage {
    let contents: [Product]
    let page: Int
    let pageSize: Int
    let totalElements: Int
    let hasMore: Bool
    let additionalInfo: Any?
}

struct Product: Identifiable {
    typealias Identifier = Int
    
    let id: Identifier
    let name: String?
    let description: String?
    let price: String?
    let stars: Int?
    let location: String?
    let image: ProductImage
}

struct ProductImage {
    let url: String?
    let blurhash: String?
    let width: Int?
    let height: Int?
}
