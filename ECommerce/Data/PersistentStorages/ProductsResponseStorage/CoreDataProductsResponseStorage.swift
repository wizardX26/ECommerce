import Foundation
import CoreData

final class CoreDataProductsResponseStorage {

    private let coreDataStorage: CoreDataStorage

    init(coreDataStorage: CoreDataStorage = CoreDataStorage.shared) {
        self.coreDataStorage = coreDataStorage
    }

    // MARK: - Private

    private func fetchRequest(
        for requestDto: ProductsRequestDTO
    ) -> NSFetchRequest<ProductsRequestEntity> {
        let request: NSFetchRequest = ProductsRequestEntity.fetchRequest()
        // Cache key: query + page (pageSize không được dùng trong predicate theo cacheLayer.md)
        request.predicate = NSPredicate(format: "%K = %@ AND %K = %d",
                                        #keyPath(ProductsRequestEntity.query), requestDto.query,
                                        #keyPath(ProductsRequestEntity.page), requestDto.page)
        return request
    }

    private func deleteResponse(
        for requestDto: ProductsRequestDTO,
        in context: NSManagedObjectContext
    ) {
        let request = fetchRequest(for: requestDto)

        do {
            if let result = try context.fetch(request).first {
                context.delete(result)
            }
        } catch {
            print(error)
        }
    }
}

extension CoreDataProductsResponseStorage: ProductsResponseStorage {

    func getResponse(
        for requestDto: ProductsRequestDTO,
        completion: @escaping (Result<ProductsResponseDTO?, Error>) -> Void
    ) {
        printIfDebug("[Cache] Reading cache - Query: '\(requestDto.query)', Page: \(requestDto.page), PageSize: \(requestDto.pageSize)")
        
        coreDataStorage.performBackgroundTask { context in
            do {
                let fetchRequest = self.fetchRequest(for: requestDto)
                let requestEntity = try context.fetch(fetchRequest).first

                if let entity = requestEntity, let response = entity.response {
                    let dto = response.toDTO()
                    printIfDebug("[Cache] Cache found - Query: '\(requestDto.query)', Page: \(requestDto.page), Items: \(dto.contents.count)")
                    completion(.success(dto))
                } else {
                    printIfDebug("[Cache] Cache not found - Query: '\(requestDto.query)', Page: \(requestDto.page)")
                    completion(.success(nil))
                }
            } catch {
                printIfDebug("[Cache] Cache read error - Query: '\(requestDto.query)', Page: \(requestDto.page), Error: \(error.localizedDescription)")
                completion(.failure(CoreDataStorageError.readError(error)))
            }
        }
    }

    func save(
        response responseDto: ProductsResponseDTO,
        for requestDto: ProductsRequestDTO
    ) {
        printIfDebug("[Cache] Saving to cache - Query: '\(requestDto.query)', Page: \(requestDto.page), Items: \(responseDto.contents.count)")
        
        coreDataStorage.performBackgroundTask { context in
            do {
                self.deleteResponse(for: requestDto, in: context)

                let requestEntity = requestDto.toEntity(in: context)
                requestEntity.response = responseDto.toEntity(in: context)

                try context.save()
                printIfDebug("[Cache] Cache saved - Query: '\(requestDto.query)', Page: \(requestDto.page), Items: \(responseDto.contents.count)")
            } catch {
                printIfDebug("[Cache] Cache save error - Query: '\(requestDto.query)', Page: \(requestDto.page), Error: \(error.localizedDescription)")
                debugPrint("CoreDataProductsResponseStorage Unresolved error \(error), \((error as NSError).userInfo)")
            }
        }
    }
}
