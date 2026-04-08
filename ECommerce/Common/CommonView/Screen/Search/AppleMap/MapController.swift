//
//  MapController.swift
//  ECommerce
//
//  Created by wizard.os25 on 11/1/26.
//

import Foundation
import UIKit
import MapKit
import CoreLocation

// MARK: - Map Controller Input Protocol

public protocol MapControllerInput {
    func enableUserLocation()
    func showLocation(_ location: MapLocationModel)
    func showLocations(_ locations: [MapLocationModel])
    func search(keyword: String)
    func showRoute(to destination: CLLocationCoordinate2D)
    func clearLocations()
    func clearRoute()
}

// MARK: - Map Controller Output Protocol

public protocol MapControllerOutput {
    var locations: Observable<[MapLocationModel]> { get }
    var currentLocation: Observable<CLLocationCoordinate2D?> { get }
    var isLocationEnabled: Observable<Bool> { get }
    var screenTitle: String { get }
}

// MARK: - Map Controller Typealias

public typealias MapController = MapControllerInput & MapControllerOutput & EcoController

// MARK: - Default Map Controller

public final class DefaultMapController: NSObject, MapController {
    
    // MARK: - OUTPUT (Map-specific)
    
    public let locations: Observable<[MapLocationModel]> = Observable([])
    public let currentLocation: Observable<CLLocationCoordinate2D?> = Observable(nil)
    public let isLocationEnabled: Observable<Bool> = Observable(false)
    public var screenTitle: String { "map".localized() }
    
    // MARK: - EcoController Output (common to all controllers)
    
    public let loading: Observable<Bool> = Observable(false)
    public let error: Observable<Error?> = Observable(nil)
    public let navigationState: Observable<EcoNavigationState> = Observable(.init())
    
    // MARK: - Private
    
    private weak var mapViewController: MapViewController?
    private let locationManager = CLLocationManager()
    private let mainQueue: DispatchQueueType
    
    // Callback for back button tap
    var onNavigationBarLeftItemTap: (() -> Void)?
    
    // MARK: - Init
    
    init(
        mainQueue: DispatchQueueType = DispatchQueue.main
    ) {
        self.mainQueue = mainQueue
        super.init()
        setupLocation()
    }
    
    deinit {
        locationManager.stopUpdatingLocation()
        locationManager.delegate = nil
    }
    
    // MARK: - Internal Methods (for MapViewController to call)
    
    /// Set the map view controller reference (called by MapViewController)
    internal func setMapViewController(_ viewController: MapViewController) {
        self.mapViewController = viewController
    }
    
    // MARK: - Private Setup
    
    private func setupLocation() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    private func handle(error: Error) {
        mainQueue.async { [weak self] in
            self?.error.value = error
        }
    }
}

// MARK: - INPUT Implementation

extension DefaultMapController {
    
    /// Request permission + start tracking user location
    public func enableUserLocation() {
        guard CLLocationManager.locationServicesEnabled() else {
            let error = NSError(
                domain: "MapController",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Location services are not enabled"]
            )
            handle(error: error)
            return
        }
        
        // Check authorization status - compatible with iOS 13.0+
        let status: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            status = locationManager.authorizationStatus
        } else {
            status = CLLocationManager.authorizationStatus()
        }
        
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
            isLocationEnabled.value = true
        case .denied, .restricted:
            let error = NSError(
                domain: "MapController",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Location permission denied"]
            )
            handle(error: error)
        @unknown default:
            break
        }
    }
    
    /// Show one location
    public func showLocation(_ location: MapLocationModel) {
        showLocations([location])
        // Camera movement will be handled by binding in MapViewController
        if let coordinate = locations.value.first?.coordinate {
            currentLocation.value = coordinate
        }
    }
    
    /// Show multiple locations
    public func showLocations(_ locations: [MapLocationModel]) {
        mainQueue.async { [weak self] in
            guard let self = self else { return }
            self.locations.value = locations
            // Rendering will be handled by binding in MapViewController
        }
    }
    
    /// Search place by keyword
    public func search(keyword: String) {
        guard !keyword.isEmpty else { return }
        guard let mapViewController = mapViewController else {
            let error = NSError(
                domain: "MapController",
                code: -6,
                userInfo: [NSLocalizedDescriptionKey: "Map view controller not set"]
            )
            handle(error: error)
            return
        }
        
        loading.value = true
        let region = mapViewController.mapView.region
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = keyword
        request.region = region
        
        MKLocalSearch(request: request).start { [weak self] response, error in
            self?.mainQueue.async {
                self?.loading.value = false
                
                if let error = error {
                    self?.handle(error: error)
                    return
                }
                
                guard let response = response else {
                    let noResultsError = NSError(
                        domain: "MapController",
                        code: -3,
                        userInfo: [NSLocalizedDescriptionKey: "No results found"]
                    )
                    self?.handle(error: noResultsError)
                    return
                }
                
                let results = response.mapItems.map {
                    MapLocationModel(
                        id: UUID().uuidString,
                        coordinate: $0.placemark.coordinate,
                        title: $0.name,
                        subtitle: $0.placemark.title
                    )
                }
                
                self?.showLocations(results)
            }
        }
    }
    
    /// Build and show route from user to destination
    public func showRoute(to destination: CLLocationCoordinate2D) {
        guard let mapViewController = mapViewController,
              let userLocation = mapViewController.mapView.userLocation.location else {
            let error = NSError(
                domain: "MapController",
                code: -4,
                userInfo: [NSLocalizedDescriptionKey: "User location not available"]
            )
            handle(error: error)
            return
        }
        
        loading.value = true
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .automobile
        
        MKDirections(request: request).calculate { [weak self] response, error in
            self?.mainQueue.async {
                self?.loading.value = false
                
                if let error = error {
                    self?.handle(error: error)
                    return
                }
                
                guard let route = response?.routes.first else {
                    let noRouteError = NSError(
                        domain: "MapController",
                        code: -5,
                        userInfo: [NSLocalizedDescriptionKey: "No route found"]
                    )
                    self?.handle(error: noRouteError)
                    return
                }
                
                let routeModel = MapRouteModel(
                    polyline: route.polyline,
                    distance: route.distance,
                    expectedTravelTime: route.expectedTravelTime
                )
                
                self?.mapViewController?.renderRoute(routeModel)
            }
        }
    }
    
    /// Clear all locations from map
    public func clearLocations() {
        mainQueue.async { [weak self] in
            guard let self = self else { return }
            self.locations.value = []
            // MapViewController will handle clearing annotations through binding
        }
    }
    
    /// Clear route from map
    public func clearRoute() {
        mainQueue.async { [weak self] in
            guard let self = self else { return }
            self.mapViewController?.clearRoute()
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension DefaultMapController: CLLocationManagerDelegate {
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
            isLocationEnabled.value = true
        case .denied, .restricted:
            isLocationEnabled.value = false
            let error = NSError(
                domain: "MapController",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Location permission denied"]
            )
            handle(error: error)
        default:
            break
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        mainQueue.async { [weak self] in
            guard let self = self else { return }
            self.currentLocation.value = location.coordinate
            // Camera movement will be handled by binding in MapViewController
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        handle(error: error)
    }
}

// MARK: - EcoController Implementation

extension DefaultMapController {
    
    public func onViewDidLoad() {
        // Initialize navigation state with clear background and back button
        // Use same height as AddressViewController (140pt)
        let leftItem = EcoNavItem.back { [weak self] in
            // Back action will be handled by MapViewController
            print("🗺️ [MapController] Back button action called")
            self?.onNavigationBarLeftItemTap?()
        }
        
        print("🗺️ [MapController] onViewDidLoad - Setting navigation state with leftItem")
        navigationState.value = EcoNavigationState(
            title: nil,
            showsSearch: false,
            searchState: nil,
            leftItem: leftItem,
            rightItems: [],
            background: .transparent, // Clear color to show map behind
            backgroundColor: .clear,
            height: 140, // Same height as AddressViewController
            collapsedHeight: 140
        )
        print("🗺️ [MapController] Navigation state set - leftItem: EXISTS, height: 140")
    }
    
    public func onViewWillAppear() {
        // Handle view will appear if needed
    }
    
    public func onViewDidDisappear() {
        // Stop location updates when view disappears to save battery
        locationManager.stopUpdatingLocation()
    }
}
