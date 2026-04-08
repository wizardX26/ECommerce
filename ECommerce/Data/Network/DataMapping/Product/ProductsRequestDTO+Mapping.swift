//
//  ProductsRequestDTO+Mapping.swift
//  ExampleMVVM
//
//  Created by wizard.os25 on 14/11/25.
//

import Foundation

struct ProductsRequestDTO: Encodable {
    let query: String
    let page: Int
    let pageSize: Int
}
