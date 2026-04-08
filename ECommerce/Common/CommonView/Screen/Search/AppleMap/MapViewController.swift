//
//  MapViewController.swift
//  ECommerce
//
//  Created by wizard.os25 on 11/1/26.
//

import UIKit
import MapKit

/// MapViewController - A simple, embeddable map view controller
/// Can be embedded into any parent view controller when needed to display a map
/// Follows the app's architecture pattern by inheriting from EcoViewController
public final class MapViewController: EcoViewController {
    
    // MARK: - Public Properties
    
    /// The map view instance - exposed for direct access if needed
    public let mapView = MKMapView()
    
    /// Map controller - accessed through controller property from EcoViewController
    private var mapController: MapController! {
        get { controller as? MapController }
    }
    
    // MARK: - Private Properties
    
    private var isInitialSetup = false
    private var cardViewController: CardViewController?
    private var cardController: CardController?
    
    // Callback khi chọn vị trí: (address: String, latitude: String, longitude: String, addressType: String) -> Void
    public var onLocationSelected: ((String, String, String, String) -> Void)?
    
    // Lưu selected location để truyền về AddressViewController khi back
    private var selectedLocation: (address: String, latitude: String, longitude: String)?
    
    // Segment control for address type
    private let addressTypeSegmentedControl = UISegmentedControl(items: ["Shipping", "Shop", "Other"])
    
    // Selected address type (default: "shipping")
    // Values must match backend keys: "shipping", "shop", "other"
    private var selectedAddressType: String = "shipping"
    
    // MARK: - Lifecycle
    
    /// Factory method to create MapViewController with MapController
    /// - Parameter mapController: The map controller instance
    /// - Returns: Configured MapViewController instance
    public static func create(
        with mapController: MapController
    ) -> MapViewController {
        let viewController = MapViewController.instantiateViewController()
        // Inject controller for EcoViewController - DI pattern
        viewController.controller = mapController
        
        // Set reference in controller for direct access if needed
        if let defaultController = mapController as? DefaultMapController {
            defaultController.setMapViewController(viewController)
        }
        
        return viewController
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        setupCardViewController()
        
        // Ensure navigation state is set after viewDidLoad completes
        // This ensures navigation bar is properly configured with back button
        DispatchQueue.main.async { [weak self] in
            // Navigation state should already be set in controller.onViewDidLoad()
            // But ensure it's applied if needed
            if let controller = self?.mapController,
               let navBarController = self?.navigationBarViewController?.controller as? DefaultEcoNavigationBarController {
                // Setup back button callback if leftItem exists
                if controller.navigationState.value.leftItem != nil {
                    navBarController.onLeftItemTap = { [weak self] in
                        self?.navigationController?.popViewController(animated: true)
                    }
                    print("🗺️ [MapViewController] Back button callback set in viewDidLoad")
                }
            }
        }
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mapController?.onViewWillAppear()
        
        // Ensure navigation bar is on top of map view
        if let navBarView = navigationBarViewController?.view {
            view.bringSubviewToFront(navBarView)
            print("🗺️ [MapViewController] Navigation bar brought to front in viewWillAppear")
        }
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Ensure navigation bar is always on top of map view (called after layout)
        if let navBarView = navigationBarViewController?.view {
            view.bringSubviewToFront(navBarView)
        }
        // Ensure segment control is on top (above navigation bar if needed, or just above map)
        view.bringSubviewToFront(addressTypeSegmentedControl)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Khi sắp back về AddressViewController, gọi callback với selected location và address type nếu có
        if let location = selectedLocation {
            onLocationSelected?(location.address, location.latitude, location.longitude, selectedAddressType)
            // Clear sau khi gọi để tránh gọi lại
            selectedLocation = nil
        }
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        mapController?.onViewDidDisappear()
    }
    
    deinit {
        mapView.delegate = nil
        cardViewController?.detach()
        cardViewController = nil
    }
    
    // MARK: - Common Binding Override
    
    public override func bindCommon() {
        super.bindCommon()
        bindMapSpecific()
    }
    
    // MARK: - Navigation Override
    
    public override func applyNavigation(_ state: EcoNavigationState) {
        super.applyNavigation(state)
        // Override left item tap callback to pop back to previous screen
        // Use async to ensure navigation bar is fully set up
        DispatchQueue.main.async { [weak self] in
            if let navBarController = self?.navigationBarViewController?.controller as? DefaultEcoNavigationBarController {
                navBarController.onLeftItemTap = { [weak self] in
                    print("🗺️ [MapViewController] Back button tapped")
                    self?.navigationController?.popViewController(animated: true)
                }
                print("🗺️ [MapViewController] Back button callback set in applyNavigation - leftItem: \(state.leftItem != nil ? "EXISTS" : "nil")")
            } else {
                print("⚠️ [MapViewController] navBarController is nil in applyNavigation")
            }
        }
    }
    
    // MARK: - Map-Specific Binding
    
    private func bindMapSpecific() {
        guard let controller = mapController else { return }
        
        // Bind locations
        controller.locations.observe(on: self) { [weak self] locations in
            self?.renderLocations(locations)
        }
        
        // Bind current location
        controller.currentLocation.observe(on: self) { [weak self] coordinate in
            guard let coordinate = coordinate else { return }
            self?.moveCamera(to: coordinate)
        }
    }
    
    // MARK: - Loading Handler Override
    
    public override func handleLoading(_ isLoading: Bool) {
        super.handleLoading(isLoading)
        // Handle loading state if needed
        // For example: show/hide loading indicator on map
    }
    
    // MARK: - Error Handler Override
    
    public override func handleError(_ error: Error?) {
        guard let error = error else { return }
        // Use default error handling from EcoViewController
        showAlert(title: mapController?.screenTitle ?? "Error", message: error.localizedDescription)
    }
    
    // MARK: - Setup
    
    private func setup() {
        guard !isInitialSetup else { return }
        isInitialSetup = true
        
        // Set view background to match AddressViewController to avoid showing underlying view during swipe back
        view.backgroundColor = .systemBackground
        
        view.addSubview(mapView)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none
        
        // Configure map appearance
        mapView.mapType = .standard
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.showsTraffic = false
        
        // Setup segment control
        setupSegmentControl()
    }
    
    private func setupSegmentControl() {
        addressTypeSegmentedControl.selectedSegmentIndex = 0 // Default: "Shipping"
        addressTypeSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        addressTypeSegmentedControl.addTarget(self, action: #selector(segmentControlValueChanged), for: .valueChanged)
        
        // Style segment control
        // Nền tổng thể sáng màu hơn để nổi bật trên nền map
        addressTypeSegmentedControl.backgroundColor = UIColor.white.withAlphaComponent(0.85) // Nền sáng hơn
        
        // Nền xám khi được chọn (khác so với không chọn)
        addressTypeSegmentedControl.selectedSegmentTintColor = UIColor.systemGray4 // Nền xám khi selected
        
        // Set text attributes cho normal state (unselected) - chữ màu nhám
        addressTypeSegmentedControl.setTitleTextAttributes([
            .foregroundColor: UIColor.systemGray, // Chữ màu nhám khi không chọn
            .font: UIFont.systemFont(ofSize: 14, weight: .regular)
        ], for: .normal)
        
        // Set text attributes cho selected state (selected) - chữ màu đen
        addressTypeSegmentedControl.setTitleTextAttributes([
            .foregroundColor: UIColor.black, // Chữ màu đen khi được chọn
            .font: UIFont.systemFont(ofSize: 14, weight: .semibold)
        ], for: .selected)
        
        view.addSubview(addressTypeSegmentedControl)
        
        // Constraints: center horizontal, 48pt from top safe area
        NSLayoutConstraint.activate([
            addressTypeSegmentedControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            addressTypeSegmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 48),
            addressTypeSegmentedControl.widthAnchor.constraint(equalToConstant: 280), // Reasonable width for 2 segments
            addressTypeSegmentedControl.heightAnchor.constraint(equalToConstant: 32)
        ])
    }
    
    @objc private func segmentControlValueChanged() {
        // Update selected address type based on segment index
        // Values must match backend keys exactly: "shipping", "shop", "other"
        // 0 = "Shipping" -> "shipping"
        // 1 = "Shop" -> "shop"
        // 2 = "Other" -> "other"
        let index = addressTypeSegmentedControl.selectedSegmentIndex
        switch index {
        case 0:
            selectedAddressType = "shipping"
        case 1:
            selectedAddressType = "shop"
        case 2:
            selectedAddressType = "other"
        default:
            selectedAddressType = "shipping"
        }
        print("🗺️ [MapViewController] Address type changed to: '\(selectedAddressType)' (segment index: \(index))")
    }
    
    private func setupCardViewController() {
        let screenHeight = view.bounds.height
        
        // Configuration:
        // - Peek: 64pt từ bottom (collapsedHeight) - hiển thị một phần phía dưới
        // - Intermediate: một nửa view cha (screenHeight / 2) - lần đầu tương tác
        // - Expanded: 80pt từ top của view cha (expandedHeight = screenHeight - 80) - lần thứ hai
        let cardConfig = CardConfiguration(
            expandedHeight: screenHeight - 160, // Final: 80pt từ top
            collapsedHeight: 164, // Peek: 164pt từ bottom
            presentationMode: .peek, // Start in peek mode
            intermediateY: screenHeight / 2, // Intermediate: một nửa view cha
            enableGesture: true // Enable gesture in CardView, it will handle smoothly
        )
        
        print("🗺️ [MapViewController] setupCardViewController - screenHeight: \(screenHeight)")
        print("🗺️ [MapViewController] Configuration - collapsedHeight: \(cardConfig.collapsedHeight), intermediateY: \(cardConfig.intermediateY ?? 0), expandedHeight: \(cardConfig.expandedHeight)")
        
        // Create Card Controller
        let cardController = DefaultCardController(configuration: cardConfig)
        self.cardController = cardController // Store reference
        
        // Create Card View Controller
        let cardVC = CardViewController.create(with: cardController)
        
        // Attach to current view controller
        cardVC.attach(to: self)
        print("🗺️ [MapViewController] CardViewController attached")
        
        // Create LocationSearchViewController as content
        let locationSearchController = DefaultLocationSearchController()
        let locationSearchVC = LocationSearchViewController.create(with: locationSearchController)
        
        // Setup callback khi chọn vị trí
        locationSearchController.onLocationSelected = { [weak self] keyword in
            guard let self = self,
                  let coordinate = keyword.coordinate,
                  let cardController = self.cardController else {
                return
            }
            
            // Lưu thông tin selected location (KHÔNG gọi callback ngay, KHÔNG back)
            let latitude = String(coordinate.latitude)
            let longitude = String(coordinate.longitude)
            self.selectedLocation = (address: keyword.keyword, latitude: latitude, longitude: longitude)
            
            // Kiểm tra state hiện tại của card
            let currentState = cardController.state.value
            let needsCollapse = currentState == .expanded || currentState == .intermediate
            
            if needsCollapse {
                // Đẩy CardView về trạng thái peek (collapsed) phía dưới TRƯỚC
                // Sử dụng callback để đợi animation hoàn tất
                if let defaultCardController = cardController as? DefaultCardController {
                    // Store original callback
                    let originalOnCollapsed = defaultCardController.onCollapsed
                    
                    // Set temporary callback để đợi collapse hoàn tất
                    defaultCardController.onCollapsed = { [weak self] in
                        guard let self = self else { return }
                        
                        // Restore original callback
                        defaultCardController.onCollapsed = originalOnCollapsed
                        
                        // Đợi một chút để đảm bảo animation hoàn tất hoàn toàn
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            // Xác định và chuyển camera + zoom vào vị trí đó trên map
                            self.moveCamera(to: coordinate, distance: 500) // Zoom vào với khoảng cách 500m
                            
                            // Tạo annotation cho vị trí đã chọn
                            let location = MapLocationModel(
                                id: keyword.id,
                                coordinate: coordinate,
                                title: keyword.keyword,
                                subtitle: nil
                            )
                            self.mapController?.showLocation(location)
                        }
                    }
                }
                
                // Trigger collapse
                cardVC.collapse()
            } else {
                // Card đã ở collapsed state, zoom ngay
                self.moveCamera(to: coordinate, distance: 500)
                
                let location = MapLocationModel(
                    id: keyword.id,
                    coordinate: coordinate,
                    title: keyword.keyword,
                    subtitle: nil
                )
                self.mapController?.showLocation(location)
            }
        }
        
        cardVC.setContent(locationSearchVC)
        print("🗺️ [MapViewController] LocationSearchViewController set as content")
        
        // Store reference
        cardViewController = cardVC
        
        // Ensure view is laid out
        DispatchQueue.main.async { [weak self] in
            self?.cardViewController?.updateParentViewHeightIfNeeded()
            print("🗺️ [MapViewController] Parent view height updated")
        }
    }
}

// MARK: - Public Map Methods

extension MapViewController {
    
    /// Render locations on the map
    /// - Parameter locations: Array of location models to display
    public func renderLocations(_ locations: [MapLocationModel]) {
        mapView.removeAnnotations(mapView.annotations)
        
        guard !locations.isEmpty else { return }
        
        let annotations = locations.map { model -> MKPointAnnotation in
            let pin = MKPointAnnotation()
            pin.coordinate = model.coordinate
            pin.title = model.title
            pin.subtitle = model.subtitle
            return pin
        }
        
        mapView.addAnnotations(annotations)
        
        // Show all annotations with appropriate padding
        if annotations.count == 1 {
            // Single location: center on it with default distance
            moveCamera(to: annotations[0].coordinate)
        } else {
            // Multiple locations: show all with padding
            mapView.showAnnotations(annotations, animated: true)
        }
    }
    
    /// Render route on the map
    /// - Parameter route: Route model containing polyline and route information
    public func renderRoute(_ route: MapRouteModel) {
        mapView.removeOverlays(mapView.overlays)
        mapView.addOverlay(route.polyline)
        
        // Adjust map to show the entire route
        let padding: CGFloat = 50
        let insets = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        mapView.setVisibleMapRect(
            route.polyline.boundingMapRect,
            edgePadding: insets,
            animated: true
        )
    }
    
    /// Move camera to a specific coordinate
    /// - Parameters:
    ///   - coordinate: Target coordinate
    ///   - distance: Distance in meters for the region (default: 800m)
    public func moveCamera(to coordinate: CLLocationCoordinate2D,
                          distance: CLLocationDistance = 800) {
        let region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: distance,
            longitudinalMeters: distance
        )
        mapView.setRegion(region, animated: true)
    }
    
    /// Clear all annotations from the map
    public func clearLocations() {
        mapView.removeAnnotations(mapView.annotations)
    }
    
    /// Clear all overlays (routes) from the map
    public func clearRoute() {
        mapView.removeOverlays(mapView.overlays)
    }
}

// MARK: - UIGestureRecognizerDelegate

extension MapViewController {
    
    /// Override to ensure CardView pan gesture has priority over MapView gestures
    /// And ensure map scroll gesture fails when swipe back from left edge
    public override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Check if other gesture is from MapView and current gesture is from CardView
        if let otherView = otherGestureRecognizer.view,
           otherView == mapView,
           let cardVC = cardViewController,
           let gestureView = gestureRecognizer.view,
           cardVC.view.isDescendant(of: gestureView) || gestureView == cardVC.view {
            // Require MapView gesture to fail when CardView pan is active
            return true
        }
        
        // Require map scroll gesture to fail when swipe back gesture should work (from left edge)
        if gestureRecognizer === navigationController?.interactivePopGestureRecognizer,
           let otherPan = otherGestureRecognizer as? UIPanGestureRecognizer,
           otherPan.view == mapView {
            // Check if swipe is from left edge
            let location = otherPan.location(in: view)
            let isFromLeftEdge = location.x < 20 // Within 20pt from left edge
            if isFromLeftEdge {
                print("🗺️ [MapViewController] shouldBeRequiredToFailBy - Map gesture from left edge → Require map gesture to FAIL")
                return true // Require map gesture to fail, allowing only swipe back
            }
        }
        
        // Use parent implementation for other cases
        return super.gestureRecognizer(gestureRecognizer, shouldBeRequiredToFailBy: otherGestureRecognizer)
    }
    
    /// Override to ensure swipe back gesture only works from left edge, not from map scroll
    public override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // For interactive pop gesture, only allow if touch is from left edge
        if gestureRecognizer === navigationController?.interactivePopGestureRecognizer {
            let location = touch.location(in: view)
            let isAtLeftEdge = location.x < 20 // Within 20pt from left edge
            print("🗺️ [MapViewController] shouldReceive touch - location: \(location), isAtLeftEdge: \(isAtLeftEdge)")
            // Only allow swipe back if touch starts from left edge
            // This ensures map scroll gesture is not interfered with
            return isAtLeftEdge
        }
        
        // Use parent implementation for other gestures
        return super.gestureRecognizer(gestureRecognizer, shouldReceive: touch)
    }
    
    /// Override to ensure swipe back gesture only begins when swiping from left edge
    /// This ensures only swipe back action is allowed from left edge, not map scroll
    public override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // For interactive pop gesture, check if it's a horizontal swipe from left edge
        if gestureRecognizer === navigationController?.interactivePopGestureRecognizer,
           let panGesture = gestureRecognizer as? UIPanGestureRecognizer {
            let location = panGesture.location(in: view)
            let velocity = panGesture.velocity(in: view)
            let translation = panGesture.translation(in: view)
            
            // Only allow if:
            // 1. Touch starts from left edge (x < 20)
            // 2. Horizontal velocity is positive (swiping right)
            // 3. Horizontal movement is greater than vertical movement
            let isAtLeftEdge = location.x < 20
            let isHorizontalSwipe = abs(velocity.x) > abs(velocity.y) && abs(translation.x) > abs(translation.y)
            let isSwipeRight = velocity.x > 0 && translation.x > 0
            
            let shouldBegin = isAtLeftEdge && isHorizontalSwipe && isSwipeRight
            
            print("🗺️ [MapViewController] gestureRecognizerShouldBegin - isAtLeftEdge: \(isAtLeftEdge), isHorizontalSwipe: \(isHorizontalSwipe), isSwipeRight: \(isSwipeRight), shouldBegin: \(shouldBegin)")
            
            // If should begin, this means we want swipe back, not map scroll
            return shouldBegin
        }
        
        // Use parent implementation for other gestures
        return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }
    
    /// Override to prevent simultaneous recognition between swipe back and map scroll
    /// When swipe back should work (from left edge), map scroll should not work
    public override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // For interactive pop gesture, don't allow simultaneous recognition with map gestures
        if gestureRecognizer === navigationController?.interactivePopGestureRecognizer,
           let otherPan = otherGestureRecognizer as? UIPanGestureRecognizer,
           otherPan.view == mapView {
            // Check if swipe is from left edge
            let location = otherPan.location(in: view)
            let isFromLeftEdge = location.x < 20
            if isFromLeftEdge {
                print("🗺️ [MapViewController] shouldRecognizeSimultaneouslyWith - Swipe from left edge → Don't allow simultaneous (only swipe back)")
                return false // Don't allow simultaneous - only swipe back should work
            }
        }
        
        // Use parent implementation for other cases
        return super.gestureRecognizer(gestureRecognizer, shouldRecognizeSimultaneouslyWith: otherGestureRecognizer)
    }
    
}

// MARK: - MKMapViewDelegate

extension MapViewController: MKMapViewDelegate {
    
    public func mapView(_ mapView: MKMapView,
                        rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .systemBlue
            renderer.lineWidth = 4
            renderer.lineCap = .round
            renderer.lineJoin = .round
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
    public func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        // Handle annotation selection if needed
    }
    
    public func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        // Handle annotation deselection if needed
    }
}
