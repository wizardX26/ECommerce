//
//  LocationManager.swift
//  ECommerce
//
//  Created by wizard.os25 on 11/1/26.
//

import CoreLocation
import MapKit

public struct MapLocationModel {
    public let id: String
    public let coordinate: CLLocationCoordinate2D
    public let title: String?
    public let subtitle: String?

    public init(
        id: String,
        coordinate: CLLocationCoordinate2D,
        title: String? = nil,
        subtitle: String? = nil
    ) {
        self.id = id
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
    }
}

public struct MapRouteModel {
    public let polyline: MKPolyline
    public let distance: CLLocationDistance
    public let expectedTravelTime: TimeInterval
}
