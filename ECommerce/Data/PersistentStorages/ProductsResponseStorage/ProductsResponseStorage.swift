import Foundation

protocol ProductsResponseStorage {
    func getResponse(
        for request: ProductsRequestDTO,
        completion: @escaping (Result<ProductsResponseDTO?, Error>) -> Void
    )
    func save(response: ProductsResponseDTO, for requestDto: ProductsRequestDTO)
}
