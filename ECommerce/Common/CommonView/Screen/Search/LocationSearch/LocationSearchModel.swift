//
//  LocationSearchModel.swift
//  ECommerce
//
//  Created by wizard.os25 on 11/1/26.
//

import Foundation
import CoreLocationstruct LocationSearchKeyword {
    public let id: String
    public let keyword: String
    public let timestamp: Date
    public let coordinate: CLLocationCoordinate2D? // Tọa độ của vị trí
    
    public init(
        id: String = UUID().uuidString,
        keyword: String,
        timestamp: Date = Date(),
        coordinate: CLLocationCoordinate2D? = nil
    ) {
        self.id = id
        self.keyword = keyword
        self.timestamp = timestamp
        self.coordinate = coordinate
    }
}
