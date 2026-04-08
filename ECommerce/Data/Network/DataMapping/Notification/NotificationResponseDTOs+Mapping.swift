//
//  NotificationResponseDTOs+Mapping.swift
//  ECommerce
//
//  Created by wizard.os25 on 19/1/26.
//

import Foundation

// MARK: - API Response Wrapper

struct NotificationResponseDTO: Decodable {
    let statusCode: Int
    let success: Bool
    let message: String
    let data: NotificationPageDTO
    
    enum CodingKeys: String, CodingKey {
        case statusCode
        case success
        case message
        case data
    }
}

struct NotificationPageDTO: Decodable {
    let contents: [NotificationDataDTO]
    let page: Int
    let pageSize: Int
    let totalElements: Int
    let hasMore: Bool
    
    enum CodingKeys: String, CodingKey {
        case contents
        case page
        case pageSize
        case totalElements
        case hasMore
    }
    
    // Computed property for backward compatibility
    var totalPages: Int {
        // Calculate total pages from totalElements and pageSize
        guard pageSize > 0 else { return 1 }
        return (totalElements + pageSize - 1) / pageSize
    }
}

// MARK: - Notification Data DTO

struct NotificationDataDTO: Decodable {
    let id: Int
    let type: String?
    let title: String
    let body: String
    let data: NotificationDataContentDTO?
    let isRead: Bool
    let readAt: String?
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case title
        case body
        case data
        case isRead = "is_read"
        case readAt = "read_at"
        case createdAt = "created_at"
    }
}

// MARK: - Notification Data Content DTO (for data field)

struct NotificationDataContentDTO: Decodable {
    let type: String?
    let email: String?
    let orderId: Int?
    let orderStatus: String?
    let errorMessage: String?
    let paymentStatus: String?
    let totalAmount: Double?
    
    enum CodingKeys: String, CodingKey {
        case type
        case email
        case orderId = "order_id"
        case orderStatus = "order_status"
        case errorMessage = "error_message"
        case paymentStatus = "payment_status"
        case totalAmount = "total_amount"
    }
}

// MARK: - Unread Count Response DTO

struct UnreadCountResponseDTO: Decodable {
    let statusCode: Int
    let success: Bool
    let message: String
    let data: UnreadCountDataDTO
    
    enum CodingKeys: String, CodingKey {
        case statusCode
        case success
        case message
        case data
    }
}

struct UnreadCountDataDTO: Decodable {
    let unreadCount: Int
    
    enum CodingKeys: String, CodingKey {
        case unreadCount = "unread_count"
    }
}

// MARK: - Mappings to Domain

extension NotificationDataDTO {
    func toDomain() -> Notification {
        return Notification(
            id: id,
            title: title,
            description: body, // Map body to description for domain
            createdAt: createdAt,
            isRead: isRead
        )
    }
}

extension UnreadCountDataDTO {
    func toDomain() -> UnreadCount {
        return UnreadCount(count: unreadCount)
    }
}