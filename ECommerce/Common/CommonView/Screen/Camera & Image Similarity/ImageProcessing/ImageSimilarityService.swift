//
//  ImageSimilarityService.swift
//  AI integration sample
//
//  Created by Nguyen Duc Hung on 28/9/25.
//
//  ⚠️ LEGACY FILE - NOT USED IN CAMERA MODULE
//  This file uses RxSwift Observable and is NOT used by Camera & Image Similarity module.
//  Camera module is completely independent and does not use this service.
//  This file may be used elsewhere in the project but should NOT be imported in Camera module.
//

import UIKit
import CoreData


final class ImageLabelMatchingService {
    private let labelService: AILabelServiceType
    private var searchCache: [String: [Product]] = [:]
    
    init(labelService: AILabelServiceType) {
        self.labelService = labelService
    }
    
    // Helper function để tạo hash cho ảnh - tối ưu với hash nhanh hơn
    private func getImageHash(_ image: UIImage) -> String {
        // Tối ưu: Sử dụng hash thay vì base64 để nhanh hơn
        guard let data = image.pngData() else { return UUID().uuidString }
        return String(data.hashValue)
    }
    
//    func findMatchingProducts(
//        from image: UIImage,
//        in products: [Product],
//        keyPath: String = "name"
//    ) -> Observable<[Product]> {
//        // Cache check - tối ưu với hash nhanh hơn
//        let imageHash = getImageHash(image)
//        if let cachedResults = searchCache[imageHash] {
//            print("[Search] 💾 Cache hit: \(cachedResults.count) products")
//            return .just(cachedResults)
//        }
//        
//        // Tối ưu: Pre-filter products để giảm dataset
//        let filteredProducts = products.filter { product in
//            // Chỉ search trong products có name không rỗng
//            switch keyPath {
//            case "name": return !product.name.isEmpty
//            case "description": return !product.description.isEmpty
//            default: return true
//            }
//        }
//        
//        print("[Search] 🔍 Searching in \(filteredProducts.count)/\(products.count) products")
//        
//        return labelService.extractLabel(from: image)
//            .map { [weak self] predictedLabel in
//                guard let self = self else { return [] }
//                // Chuẩn hóa label → token
//                let normalizedLabel = predictedLabel.ai_normalized()
//                let labelTokens = normalizedLabel.ai_tokens().filter { !$0.isEmpty }
//                if labelTokens.isEmpty { return [] }
//
//                // Duyệt sản phẩm đã filter, chuẩn hóa field và tính score
//                let scored: [(Product, Int)] = filteredProducts.compactMap { product in
//                    let fieldValue: String
//                    switch keyPath {
//                    case "name":
//                        fieldValue = product.name
//                    case "description":
//                        fieldValue = product.description
//                    default:
//                        return nil
//                    }
//
//                    let normalizedField = fieldValue.ai_normalized()
//                    let fieldTokens = Set(normalizedField.ai_tokens())
//
//                    // Tính điểm: match theo token + bonus cho prefix/substring
//                    var score = 0
//                    for token in labelTokens {
//                        if fieldTokens.contains(token) { score += 3 }
//                        if normalizedField.hasPrefix(token) { score += 2 }
//                        if normalizedField.contains(token) { score += 1 }
//                    }
//
//                    return score > 0 ? (product, score) : nil
//                }
//
//                // Tối ưu: Sắp xếp nhanh hơn với limit kết quả
//                let results = scored
//                    .sorted { (l, r) in
//                        if l.1 != r.1 { return l.1 > r.1 }
//                        return l.0.name.count < r.0.name.count
//                    }
//                    .prefix(20) // Chỉ lấy top 20 kết quả
//                    .map { $0.0 }
//                
//                // Cache results
//                self.searchCache[imageHash] = results
//                
//                return results
//            }
//    }
}

// MARK: - String helpers for normalization and tokenization
private extension String {
    func ai_normalized() -> String {
        return self
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func ai_tokens() -> [String] {
        // Tách theo ký tự không chữ và số; loại token rất ngắn
        let separators = CharacterSet.alphanumerics.inverted
        return self.components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count >= 2 }
    }
}
