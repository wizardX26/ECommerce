//
//  CategoriesEndpoints.swift
//  ECommerce
//
//  Created by wizard.os25 on 7/1/26.
//

import Foundation

enum CategoriesEndpoints {
    
    // MARK: - Categories
    
    static func getCategories() -> Endpoint<CategoriesResponseDTO> {
        return Endpoint(
            path: "api/v1/categories",
            method: .get,
            headerParameters: [:]
        )
    }
}
