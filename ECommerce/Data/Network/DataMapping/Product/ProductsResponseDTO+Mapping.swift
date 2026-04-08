//
//  ProductsResponseDTO+Mapping.swift
//  ExampleMVVM
//
//  Created by wizard.os25 on 14/11/25.
//

import Foundation

// MARK: - Data Transfer Object

// Product DTOs (shared by both ProductsResponseDTOInternal and ProductsResponseDTO)
struct ProductDTO: Decodable {
    let id: Int
    let name: String?
    let description: String?
    let price: String?
    let stars: Int?
    let location: String?
    let image: ProductImageDTO
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case price
        case stars
        case location
        case image
    }
    
    // Custom decoder for price to handle both String and Number
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        stars = try container.decodeIfPresent(Int.self, forKey: .stars)
        location = try container.decodeIfPresent(String.self, forKey: .location)
        image = try container.decode(ProductImageDTO.self, forKey: .image)
        
        // Handle price as either String or Number (Int/Double)
        if let priceString = try? container.decode(String.self, forKey: .price) {
            price = priceString
        } else if let priceDouble = try? container.decode(Double.self, forKey: .price) {
            // Convert Double to String, removing trailing .00 if not needed
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.groupingSeparator = ","
            formatter.usesGroupingSeparator = true
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 2
            formatter.decimalSeparator = "."
            
            var formatted = formatter.string(from: NSNumber(value: priceDouble)) ?? String(priceDouble)
            // Remove trailing .00 if not needed
            if formatted.contains(".") {
                while formatted.hasSuffix("0") && formatted.contains(".") {
                    formatted = String(formatted.dropLast())
                }
                if formatted.hasSuffix(".") {
                    formatted = String(formatted.dropLast())
                }
            }
            price = formatted
        } else if let priceInt = try? container.decode(Int.self, forKey: .price) {
            // Convert Int to String
            price = String(priceInt)
        } else {
            price = nil
        }
    }
    
    // Manual initializer for creating ProductDTO from code (e.g., from CoreData entity)
    init(
        id: Int,
        name: String?,
        description: String?,
        price: String?,
        stars: Int?,
        location: String?,
        image: ProductImageDTO
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.price = price
        self.stars = stars
        self.location = location
        self.image = image
    }
}

struct ProductImageDTO: Decodable {
    let url: String?
    let blurhash: String?
    let width: Int?
    let height: Int?
}

// API Response Wrapper (top level response structure)
// Matches API response: { "statusCode": 200, "success": true, "message": "...", "data": {...} }
struct ProductsAPIResponseWrapper: Decodable {
    let statusCode: Int
    let success: Bool
    let message: String
    let data: ProductsResponseDTOInternal
    
    enum CodingKeys: String, CodingKey {
        case statusCode
        case success
        case message
        case data
    }
}

// Internal DTO for decoding nested "data" structure
struct ProductsResponseDTOInternal: Decodable {
    let contents: [ProductDTO]
    let page: Int
    let pageSize: Int
    let totalElements: Int
    let hasMore: Bool  // Converted from Int (1/0)
    let totalPages: Int?
    
    enum CodingKeys: String, CodingKey {
        case contents
        case page
        case pageSize
        case totalElements
        case hasMore
        case totalPages
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        contents = try container.decode([ProductDTO].self, forKey: .contents)
        page = try container.decode(Int.self, forKey: .page)
        pageSize = try container.decode(Int.self, forKey: .pageSize)
        totalElements = try container.decode(Int.self, forKey: .totalElements)
        
        // Handle hasMore as Int (1/0) or Bool
        if let hasMoreInt = try? container.decode(Int.self, forKey: .hasMore) {
            hasMore = hasMoreInt != 0
        } else {
            hasMore = try container.decode(Bool.self, forKey: .hasMore)
        }
        
        totalPages = try? container.decodeIfPresent(Int.self, forKey: .totalPages)
    }
}

// ProductsResponseDTO - main DTO used by Endpoint<ProductsResponseDTO>
// Decodes from API response wrapper and extracts "data" key
struct ProductsResponseDTO: Decodable {
    let contents: [ProductDTO]
    let page: Int
    let pageSize: Int
    let totalElements: Int
    let hasMore: Bool
    let totalPages: Int?
    let additionalInfo: Any?
    
    // Init from decoder (API response)
    init(from decoder: Decoder) throws {
        // Decode the wrapper first to extract "data" key
        let wrapper = try ProductsAPIResponseWrapper(from: decoder)
        let data = wrapper.data
        
        // Extract values from data
        self.contents = data.contents
        self.page = data.page
        self.pageSize = data.pageSize
        self.totalElements = data.totalElements
        self.hasMore = data.hasMore
        self.totalPages = data.totalPages
        self.additionalInfo = nil
    }
    
    // Init for manual creation (used by cache mapping)
    init(
        contents: [ProductDTO],
        page: Int,
        pageSize: Int,
        totalElements: Int,
        hasMore: Bool,
        totalPages: Int?,
        additionalInfo: Any? = nil
    ) {
        self.contents = contents
        self.page = page
        self.pageSize = pageSize
        self.totalElements = totalElements
        self.hasMore = hasMore
        self.totalPages = totalPages
        self.additionalInfo = additionalInfo
    }
}


// MARK: - Mappings to Domain

extension ProductsResponseDTO {
    func toDomain() -> ProductPage {
        return .init(
            contents: contents.map { $0.toDomain() },
            page: page,
            pageSize: pageSize,
            totalElements: totalElements,
            hasMore: hasMore,
            additionalInfo: additionalInfo
        )
    }
}

extension ProductDTO {
    func toDomain() -> Product {
        return .init(
            id: Product.Identifier(id),
            name: name,
            description: description,
            price: price,
            stars: stars,
            location: location,
            image: image.toDomain()
        )
    }
}

extension ProductImageDTO {
    func toDomain() -> ProductImage {
        return .init(
            url: url,
            blurhash: blurhash,
            width: width,
            height: height
        )
    }
}
