//
//  DefaultOrderRepository.swift
//  ECommerce
//
//  Created by wizard.os25 on 14/1/26.
//

import Foundation

final class DefaultOrderRepository {
    
    private let dataTransferService: DataTransferService
    private let backgroundQueue: DataTransferDispatchQueue
    
    init(
        dataTransferService: DataTransferService,
        backgroundQueue: DataTransferDispatchQueue = DispatchQueue.global(qos: .userInitiated)
    ) {
        self.dataTransferService = dataTransferService
        self.backgroundQueue = backgroundQueue
    }
}

extension DefaultOrderRepository: OrderRepository {
    
    func placeOrder(
        cart: [CartItem],
        orderNote: String?,
        deliveryAddressId: Int?,
        addressDetail: String?,
        countryId: Int?,
        provinceId: Int?,
        districtId: Int?,
        wardId: Int?,
        contactPersonName: String?,
        contactPersonNumber: String?,
        completion: @escaping (Result<Order, Error>) -> Void
    ) -> Cancellable? {
        let task = RepositoryTask()
        
        guard !task.isCancelled else { return nil }
        
        let cartDTOs = cart.map { CartItemDTO(id: $0.id, quantity: $0.quantity) }
        let requestDTO = PlaceOrderRequestDTO(
            cart: cartDTOs,
            orderNote: orderNote,
            deliveryAddressId: deliveryAddressId,
            addressDetail: addressDetail,
            countryId: countryId,
            provinceId: provinceId,
            districtId: districtId,
            wardId: wardId,
            contactPersonName: contactPersonName,
            contactPersonNumber: contactPersonNumber
        )
        
        let endpoint = APIEndpoints.placeOrder(with: requestDTO)
        task.networkTask = dataTransferService.request(
            with: endpoint,
            on: backgroundQueue
        ) { result in
            guard !task.isCancelled else { return }
            
            switch result {
            case .success(let responseDTO):
                completion(.success(responseDTO.data.toDomain()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
        return task
    }
}
