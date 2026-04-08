//
//  CategoriesResponseDTO+Mapping.swift
//  ECommerce
//
//  Created by wizard.os25 on 7/1/26.
//

import Foundation

// MARK: - Data Transfer Object

// Category DTO
struct CategoryDTO: Decodable {
    let id: Int
    let name: String
    let title: String
    let description: String?
    let parentId: Int?
    let order: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case title
        case description
        case parentId
        case order
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        
        // Handle parentId - can be null in JSON
        if let parentIdValue = try? container.decodeIfPresent(Int.self, forKey: .parentId) {
            parentId = parentIdValue
        } else {
            parentId = nil
        }
        
        order = try container.decode(Int.self, forKey: .order)
    }
}

// API Response Wrapper
struct CategoriesAPIResponseWrapper: Decodable {
    let statusCode: Int
    let success: Bool
    let message: String
    let data: [CategoryDTO]
    
    enum CodingKeys: String, CodingKey {
        case statusCode
        case success
        case message
        case data
    }
}

// CategoriesResponseDTO - main DTO used by Endpoint<CategoriesResponseDTO>
struct CategoriesResponseDTO: Decodable {
    let categories: [CategoryDTO]
    
    // Init from decoder (API response)
    init(from decoder: Decoder) throws {
        // Decode the wrapper first to extract "data" key
        let wrapper = try CategoriesAPIResponseWrapper(from: decoder)
        self.categories = wrapper.data
    }
    
    // Init for manual creation (used by cache mapping if needed)
    init(categories: [CategoryDTO]) {
        self.categories = categories
    }
}

// MARK: - Mappings to Domain

extension CategoriesResponseDTO {
    func toDomain() -> [Category] {
        return categories.map { $0.toDomain() }
    }
}

extension CategoryDTO {
    func toDomain() -> Category {
        return .init(
            id: id,
            name: name,
            title: title,
            description: description,
            parentId: parentId,
            order: order
        )
    }
}
