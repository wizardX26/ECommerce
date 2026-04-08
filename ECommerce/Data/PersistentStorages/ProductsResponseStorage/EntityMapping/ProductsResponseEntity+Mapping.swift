import Foundation
import CoreData

extension ProductsResponseEntity {
    func toDTO() -> ProductsResponseDTO {
        return .init(
            contents: products?.allObjects.map { ($0 as! ProductResponseEntity).toDTO() } ?? [],
            page: Int(page),
            pageSize: Int(pageSize),
            totalElements: Int(totalElements),
            hasMore: hasMore,
            totalPages: totalPages > 0 ? Int(totalPages) : nil
        )
    }
}

extension ProductResponseEntity {
    func toDTO() -> ProductDTO {
        return ProductDTO(
            id: Int(id),
            name: name,
            description: productDescription,
            price: price,
            stars: stars > 0 ? Int(stars) : nil,
            location: location,
            image: ProductImageDTO(
                url: imageUrl,
                blurhash: imageBlurhash,
                width: imageWidth > 0 ? Int(imageWidth) : nil,
                height: imageHeight > 0 ? Int(imageHeight) : nil
            )
        )
    }
}

extension ProductsRequestDTO {
    func toEntity(in context: NSManagedObjectContext) -> ProductsRequestEntity {
        let entity: ProductsRequestEntity = .init(context: context)
        entity.query = query
        entity.page = Int32(page)
        entity.pageSize = Int32(pageSize)
        return entity
    }
}

extension ProductsResponseDTO {
    func toEntity(in context: NSManagedObjectContext) -> ProductsResponseEntity {
        let entity: ProductsResponseEntity = .init(context: context)
        entity.page = Int32(page)
        entity.pageSize = Int32(pageSize)
        entity.totalElements = Int32(totalElements)
        entity.hasMore = hasMore
        entity.totalPages = Int32(totalPages ?? 0)
        contents.forEach {
            entity.addToProducts($0.toEntity(in: context))
        }
        return entity
    }
}

extension ProductDTO {
    func toEntity(in context: NSManagedObjectContext) -> ProductResponseEntity {
        let entity: ProductResponseEntity = .init(context: context)
        entity.id = Int64(id)
        entity.name = name
        entity.productDescription = description
        entity.price = price
        entity.stars = Int32(stars ?? 0)
        entity.location = location
        entity.imageUrl = image.url
        entity.imageBlurhash = image.blurhash
        entity.imageWidth = Int32(image.width ?? 0)
        entity.imageHeight = Int32(image.height ?? 0)
        return entity
    }
}

