//
//  ProductModel.swift
//  ExampleMVVM
//
//  Created by wizard.os25 on 15/11/25.
//

import Foundation

struct ProductItemModel: Equatable {
    let id: Int
    let name: String
    let description: String
    let price: String
    let stars: Int?
    let location: String
    let imageUrl: String?
    let imageBlurhash: String?
}

extension ProductItemModel {
    init(product: Product) {
        self.id = product.id
        self.name = product.name ?? ""
        self.description = product.description ?? ""
        self.price = product.price ?? ""
        self.stars = product.stars
        self.location = product.location ?? ""
        self.imageUrl = product.image.url
        self.imageBlurhash = product.image.blurhash
    }
}
