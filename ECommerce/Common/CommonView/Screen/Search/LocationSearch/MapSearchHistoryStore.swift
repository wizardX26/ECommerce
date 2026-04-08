//
//  MapSearchHistoryStore.swift
//  ECommerce
//
//  Created by wizard.os25 on 12/1/26.
//

import Foundation
import CoreLocation

/// Codable wrapper for LocationSearchKeyword để lưu vào UserDefaults
private struct LocationSearchKeywordCodable: Codable {
    let id: String
    let keyword: String
    let timestamp: Date
    let latitude: Double?
    let longitude: Double?
    
    init(from keyword: LocationSearchKeyword) {
        self.id = keyword.id
        self.keyword = keyword.keyword
        self.timestamp = keyword.timestamp
        self.latitude = keyword.coordinate?.latitude
        self.longitude = keyword.coordinate?.longitude
    }
    
    func toLocationSearchKeyword() -> LocationSearchKeyword {
        let coordinate: CLLocationCoordinate2D?
        if let lat = latitude, let lon = longitude {
            coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        } else {
            coordinate = nil
        }
        return LocationSearchKeyword(
            id: id,
            keyword: keyword,
            timestamp: timestamp,
            coordinate: coordinate
        )
    }
}

final class MapSearchHistoryStore {

    static let shared = MapSearchHistoryStore()
    private init() {}

    private let key = "map.search.history"
    private let maxItems = 10

    /// Load search history từ UserDefaults
    func load() -> [LocationSearchKeyword] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let codables = try? JSONDecoder().decode([LocationSearchKeywordCodable].self, from: data)
        else { return [] }
        return codables.map { $0.toLocationSearchKeyword() }
            .sorted { $0.timestamp > $1.timestamp }
    }

    /// Save search keyword vào UserDefaults
    func save(_ keyword: LocationSearchKeyword) {
        var items = load()

        // Remove duplicate (same keyword)
        items.removeAll { $0.keyword.lowercased() == keyword.keyword.lowercased() }

        items.insert(keyword, at: 0)

        // Limit
        if items.count > maxItems {
            items = Array(items.prefix(maxItems))
        }

        // Convert to codable và save
        let codables = items.map { LocationSearchKeywordCodable(from: $0) }
        if let data = try? JSONEncoder().encode(codables) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    /// Clear all search history
    func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
