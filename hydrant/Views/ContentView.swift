//
//  ContentView.swift
//  hydrant
//
//  Created by Yeba Teo on 18/08/26.
//

import MapKit
import SwiftUI

// Main screen for incident intake, hydrant recommendations, and in-app routing.
struct ContentView: View {
    @State private var viewModel = HydrantMapViewModel()
    @State private var locationProvider = LocationProvider()
    
    @State private var isPlacingIncident = false
    @State private var isShowingNearbyHydrants = false
    @State private var isShowingIncidentAuthorization = false
    @State private var isShowingIncidentLocation = false
    @State private var isShowingIncidentConfirmation = false
    @State private var isShowingIncidentDetails = false
    @State private var isShowingEndIncidentConfirmation = false
    
    @State private var isAuthorizingEndIncident = false
    @State private var pendingIncidentCoordinate: CLLocationCoordinate2D?
    @State private var incidentCoordinateToConfirm: CLLocationCoordinate2D?
    
    // These flags sequence sheets without presenting two at the same time.
    // Opens incident input after the authorization sheet finishes dismissing.
    @State private var shouldShowIncidentLocationAfterAuthorization = false
    @State private var shouldShowEndIncidentAuthorizationAfterDetails = false
    @State private var shouldShowEndIncidentConfirmationAfterAuthorization = false
    @State private var shouldShowIncidentConfirmationAfterLocation = false
    
    @State private var route: MKRoute?
    @State private var routedHydrant: Hydrant?
    @State private var isShowingRouteDetails = false
    @State private var routeErrorMessage: String?
    @State private var pendingRouteHydrant: Hydrant?
    
    // Connects custom MapKit controls to this map instance.
    @Namespace private var mapScope
    // Wraps MKDirections route and route-metric requests.
    private let routeService = RouteService()
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                mapView
                topControls
                bottomIncidentButton
            }
            .mapScope(mapScope)
            .navigationTitle("Hidran Jakarta")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isShowingIncidentAuthorization) {
                incidentAuthorizationSheet
            }
            .sheet(isPresented: $isShowingIncidentLocation) {
                incidentLocationSheet
            }
            .sheet(isPresented: $isShowingIncidentConfirmation) {
                incidentConfirmationSheet
            }
            .sheet(isPresented: $isShowingIncidentDetails) {
                incidentDetailsSheet
            }
            .sheet(isPresented: $isShowingNearbyHydrants) {
                nearbyHydrantsSheet
            }
            .sheet(isPresented: $isShowingRouteDetails) {
                routeDetailsSheet
            }
            .alert(
                "Unable to Calculate Route",
                isPresented: Binding(
                    get: { routeErrorMessage != nil },
                    set: { isPresented in
                        if !isPresented {
                            routeErrorMessage = nil
                        }
                    }
                )
            ) {
                Button("OK", role: .cancel) {
                    routeErrorMessage = nil
                }
            } message: {
                Text(routeErrorMessage ?? "A driving route to this hydrant could not be found.")
            }
            .alert(
                "End current incident?",
                isPresented: $isShowingEndIncidentConfirmation
            ) {
                Button("End Incident", role: .destructive) {
                    endIncident()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This clears the incident, hydrant recommendations, and active route.")
            }
            .overlay(alignment: .bottom) {
                // Appears when search and filter settings hide every hydrant.
                if viewModel.filteredHydrants.isEmpty {
                    ContentUnavailableView(
                        "Hidran tidak ditemukan",
                        systemImage: "magnifyingglass",
                        description: Text("Ubah pencarian atau filter kondisi.")
                    )
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                    .padding()
                }
            }
            .onAppear {
                locationProvider.requestAuthorization()
            }
            .onChange(of: locationProvider.currentLocation) { _, location in
                handleLocationChange(location)
            }
            .onChange(of: isShowingIncidentAuthorization) { _, isShowing in
                handleAuthorizationSheetChange(isShowing: isShowing)
            }
            .onChange(of: isShowingIncidentLocation) { _, isShowing in
                handleIncidentLocationSheetChange(isShowing: isShowing)
            }
            .onChange(of: isShowingIncidentConfirmation) { _, isShowing in
                handleIncidentConfirmationSheetChange(isShowing: isShowing)
            }
            .onChange(of: isShowingIncidentDetails) { _, isShowing in
                handleIncidentDetailsSheetChange(isShowing: isShowing)
            }
        }
    }
    
    // Shared passcode sheet for both starting and ending incident workflows.
    private var incidentAuthorizationSheet: some View {
        IncidentAuthorizationView(
            title: isAuthorizingEndIncident ? "End Incident Authorization" : "Command Center Authorization",
            message: isAuthorizingEndIncident ? "Enter the 4-digit code to end this incident" : "Enter the 4-digit incident code"
        ) {
            if isAuthorizingEndIncident {
                shouldShowEndIncidentConfirmationAfterAuthorization = true
            } else {
                shouldShowIncidentLocationAfterAuthorization = true
            }
            isShowingIncidentAuthorization = false
        }
        .presentationDetents([
            .medium,
            .large
        ])
        .presentationDragIndicator(.visible)
    }
    
    // Lets the user choose an incident by address search or map pinpoint.
    private var incidentLocationSheet: some View {
        IncidentLocationSheet(
            onSelectCoordinate: { coordinate in
                previewIncident(at: coordinate)
            },
            onPinpointOnMap: {
                isShowingIncidentLocation = false
                isPlacingIncident = true
            }
        )
        .presentationDetents([
            .medium,
            .large
        ])
        .presentationDragIndicator(.visible)
    }
    
    @ViewBuilder
    // Confirms a pending incident before it replaces the active incident.
    private var incidentConfirmationSheet: some View {
        if let coordinate = pendingIncidentCoordinate {
            IncidentConfirmationSheet(
                coordinate: coordinate,
                onConfirm: {
                    incidentCoordinateToConfirm = coordinate
                    isShowingIncidentConfirmation = false
                },
                onChangeLocation: {
                    isShowingIncidentConfirmation = false
                    shouldShowIncidentLocationAfterAuthorization = true
                },
                onCancel: {
                    pendingIncidentCoordinate = nil
                    isShowingIncidentConfirmation = false
                }
            )
            .presentationDetents([
                .height(320),
                .medium
            ])
            .presentationDragIndicator(.visible)
        }
    }
    
    @ViewBuilder
    // Shows selected-hydrant route metrics while keeping the route on the map.
    private var routeDetailsSheet: some View {
        if let route, let routedHydrant {
            routeDetailsPanel(
                hydrant: routedHydrant,
                route: route
            )
            .presentationDetents([
                .height(240),
                .medium
            ])
            .presentationDragIndicator(.visible)
        }
    }
    
    @ViewBuilder
    // Shows active incident metadata and the controlled end-incident action.
    private var incidentDetailsSheet: some View {
        if let incidentCoordinate = viewModel.incidentCoordinate {
            incidentDetailsPanel(coordinate: incidentCoordinate)
                .presentationDetents([
                    .height(260),
                    .medium
                ])
                .presentationDragIndicator(.visible)
        }
    }
    
    // Presents ranked hydrant recommendations for the active incident.
    private var nearbyHydrantsSheet: some View {
        NavigationStack {
            nearbyHydrantsPanel
                .presentationDetents([
                    .height(300),
                    .medium,
                    .large
                ])
                .presentationDragIndicator(.visible)
        }
    }
    
    // Displays the map, route polyline, incident markers, recommendations, and user location.
    private var mapView: some View {
        MapReader { proxy in
            Map(position: $viewModel.cameraPosition, scope: mapScope) {
                if let route {
                    MapPolyline(route.polyline)
                        .stroke(.blue, lineWidth: 6)
                }
                
                if viewModel.incidentCoordinate != nil {
                    ForEach(viewModel.displayedRecommendations) { recommendation in
                        recommendationAnnotation(for: recommendation)
                    }
                }
                
                if let incidentCoordinate = viewModel.incidentCoordinate {
                    Annotation(
                        "Lokasi Kebakaran",
                        coordinate: incidentCoordinate
                    ) {
                        Button {
                            isShowingIncidentDetails = true
                        } label: {
                            Image(systemName: "flame.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .padding(10)
                                .background(Circle().fill(.red))
                                .shadow(radius: 3)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Lokasi kebakaran")
                        .accessibilityHint("Ketuk untuk mengakhiri incident")
                    }
                }
                
                if let pendingIncidentCoordinate {
                    Annotation(
                        "Preview Lokasi Kebakaran",
                        coordinate: pendingIncidentCoordinate
                    ) {
                        Image(systemName: "flame.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(Circle().fill(.orange))
                            .shadow(radius: 3)
                    }
                }
                
                UserAnnotation()
            }
            .mapStyle(
                .standard(
                    elevation: .realistic,
                    pointsOfInterest: .excludingAll
                )
            )
            .onTapGesture { position in
                guard isPlacingIncident else {
                    return
                }
                
                guard let coordinate = proxy.convert(
                    position,
                    from: .local
                ) else {
                    return
                }
                isPlacingIncident = false
                previewIncident(at: coordinate)
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }
    
    // Hosts compact map overlays above the map content.
    private var topControls: some View {
        VStack(spacing: 10) {
            if isPlacingIncident {
                Label("Tap lokasi kebakaran pada peta", systemImage: "flame.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        .red,
                        in: Capsule()
                    )
            }
            
            statusBar
            filterBar
            
            HStack {
                Spacer()
                HStack(spacing: 10) {
                    MapCompass(scope: mapScope)
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                        .accessibilityLabel("Arah peta")
                    
                    MapUserLocationButton(scope: mapScope)
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                        .accessibilityLabel("Pusatkan lokasi saya")
                }
            }
            
            if viewModel.incidentCoordinate != nil && route == nil {
                Button {
                    showHydrantsForCurrentIncident()
                } label: {
                    Label("Nearby Hydrants", systemImage: "drop.fill")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    // Starts the authorized incident workflow from a red-tinted glass button.
    private var bottomIncidentButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    isShowingIncidentAuthorization = true
                } label: {
                    Label("Incident", systemImage: "flame.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.glass(.regular.tint(.red)))
                .buttonBorderShape(.capsule)
                .accessibilityLabel("Tentukan lokasi kebakaran")
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
    }
    
    @MapContentBuilder
    // Builds a tappable recommended hydrant annotation that starts in-app routing.
    private func recommendationAnnotation(
        for recommendation: HydrantRecommendation
    ) -> some MapContent {
        let hydrant = recommendation.hydrant
        Annotation(
            "Recommended \(hydrant.title)",
            coordinate: hydrant.coordinate
        ) {
            Button {
                selectHydrantForRoute(hydrant)
            } label: {
                HydrantMarker(
                    isUsable: hydrant.isUsable,
                    isSelected: routedHydrant?.id == hydrant.id
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(hydrant.accessibilityLabel)
        }
    }
    
    // Stores an unconfirmed incident coordinate and opens the confirmation step.
    private func previewIncident(at coordinate: CLLocationCoordinate2D) {
        pendingIncidentCoordinate = coordinate
        viewModel.cameraPosition = .region(
            MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.035, longitudeDelta: 0.035)
            )
        )
        
        if isShowingIncidentLocation {
            shouldShowIncidentConfirmationAfterLocation = true
            isShowingIncidentLocation = false
        } else {
            shouldShowIncidentConfirmationAfterLocation = false
            isShowingIncidentConfirmation = true
        }
    }
    
    // Recenters on location updates or resumes a route that was waiting for location.
    private func handleLocationChange(_ location: CLLocation?) {
        guard let location else { return }
        if let pendingRouteHydrant {
            Task {
                await calculateRoute(to: pendingRouteHydrant)
            }
        } else if route == nil {
            viewModel.updateCamera(to: location)
        }
    }
    
    // Advances to the next workflow step after the authorization sheet dismisses.
    private func handleAuthorizationSheetChange(isShowing: Bool) {
        guard !isShowing else {
            return
        }
        
        if shouldShowEndIncidentConfirmationAfterAuthorization {
            shouldShowEndIncidentConfirmationAfterAuthorization = false
            isAuthorizingEndIncident = false
            isShowingEndIncidentConfirmation = true
            return
        }
        
        guard shouldShowIncidentLocationAfterAuthorization else {
            isAuthorizingEndIncident = false
            return
        }
        
        shouldShowIncidentLocationAfterAuthorization = false
        isAuthorizingEndIncident = false
        isShowingIncidentLocation = true
    }
    
    // Opens confirmation only after incident input has fully dismissed.
    private func handleIncidentLocationSheetChange(isShowing: Bool) {
        guard !isShowing && shouldShowIncidentConfirmationAfterLocation else {
            return
        }
        shouldShowIncidentConfirmationAfterLocation = false
        isShowingIncidentConfirmation = true
    }
    
    // Applies or discards pending incident state after the confirmation sheet closes.
    private func handleIncidentConfirmationSheetChange(isShowing: Bool) {
        guard !isShowing else {
            return
        }
        
        if let coordinate = incidentCoordinateToConfirm {
            incidentCoordinateToConfirm = nil
            Task {
                await Task.yield()
                await setIncident(at: coordinate)
            }
        } else if shouldShowIncidentLocationAfterAuthorization {
            shouldShowIncidentLocationAfterAuthorization = false
            pendingIncidentCoordinate = nil
            isShowingIncidentLocation = true
        } else {
            pendingIncidentCoordinate = nil
        }
    }
    
    // Starts end-incident authorization after the details sheet dismisses.
    private func handleIncidentDetailsSheetChange(isShowing: Bool) {
        guard !isShowing && shouldShowEndIncidentAuthorizationAfterDetails else {
            return
        }
        
        shouldShowEndIncidentAuthorizationAfterDetails = false
        isAuthorizingEndIncident = true
        isShowingIncidentAuthorization = true
    }
    
    @MainActor
    // Confirms the incident, clears stale route state, then calculates recommendations.
    private func setIncident(at coordinate: CLLocationCoordinate2D) async {
        endRoute()
        pendingIncidentCoordinate = nil
        viewModel.incidentCoordinate = coordinate
        viewModel.hydrantRecommendations = []
        viewModel.cameraPosition = .region(
            MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.035, longitudeDelta: 0.035)
            )
        )
        isShowingNearbyHydrants = true
        await viewModel.updateHydrantRecommendations(
            incidentCoordinate: coordinate,
            firefighterLocation: locationProvider.currentLocation,
            routeService: routeService
        )
    }
    
    // Reopens recommendations for the active incident, calculating them if needed.
    private func showHydrantsForCurrentIncident() {
        guard let incidentCoordinate = viewModel.incidentCoordinate else {
            isShowingIncidentAuthorization = true
            return
        }
        
        isShowingNearbyHydrants = true
        guard viewModel.hydrantRecommendations.isEmpty && !viewModel.isLoadingRecommendations else {
            return
        }
        
        Task {
            await viewModel.updateHydrantRecommendations(
                incidentCoordinate: incidentCoordinate,
                firefighterLocation: locationProvider.currentLocation,
                routeService: routeService
            )
        }
    }
    
    // Selects one recommended hydrant and begins firefighter-to-hydrant routing.
    private func selectHydrantForRoute(_ hydrant: Hydrant) {
        isShowingNearbyHydrants = false
        isShowingRouteDetails = false
        route = nil
        routedHydrant = nil
        routeErrorMessage = nil
        pendingRouteHydrant = hydrant
        Task {
            await calculateRoute(to: hydrant)
        }
    }
    
    @MainActor
    // Uses MKDirections through RouteService and displays the resulting polyline.
    private func calculateRoute(to hydrant: Hydrant) async {
        guard let userLocation = locationProvider.currentLocation else {
            print("❌ No current firefighter location")
            routeErrorMessage = "Your current firefighter location is unavailable. Allow location access or set a simulator location, then try again."
            locationProvider.requestLocation()
            return
        }
        
        print("🚒 Firefighter:", userLocation.coordinate)
        print("💧 Hydrant:", hydrant.coordinate)
        
        do {
            let calculatedRoute = try await routeService.calculateRoute(
                from: userLocation.coordinate,
                to: hydrant.coordinate
            )
            
            route = calculatedRoute
            routedHydrant = hydrant
            pendingRouteHydrant = nil
            routeErrorMessage = nil
            print("✅ ROUTE FOUND")
            print("Distance:", formatDrivingDistance(calculatedRoute.distance))
            print("ETA:", formatETA(calculatedRoute.expectedTravelTime))
            
            withAnimation {
                viewModel.cameraPosition = .rect(
                    paddedMapRect(for: calculatedRoute)
                )
            }
            isShowingRouteDetails = true
        } catch {
            print("❌ ROUTE FAILED:", error)
            route = nil
            routedHydrant = nil
            pendingRouteHydrant = nil
            isShowingRouteDetails = false
            routeErrorMessage = "A driving route to this hydrant could not be found."
        }
    }
    
    // Clears only the selected route, leaving the active incident in place.
    private func endRoute() {
        route = nil
        routedHydrant = nil
        pendingRouteHydrant = nil
        isShowingRouteDetails = false
    }
    
    // Clears incident-specific state after passcode and destructive confirmation.
    private func endIncident() {
        endRoute()
        isPlacingIncident = false
        isShowingIncidentDetails = false
        isShowingNearbyHydrants = false
        isShowingIncidentConfirmation = false
        pendingIncidentCoordinate = nil
        incidentCoordinateToConfirm = nil
        shouldShowIncidentConfirmationAfterLocation = false
        shouldShowEndIncidentAuthorizationAfterDetails = false
        shouldShowEndIncidentConfirmationAfterAuthorization = false
        isAuthorizingEndIncident = false
        isShowingEndIncidentConfirmation = false
        viewModel.incidentCoordinate = nil
        viewModel.hydrantRecommendations = []
        viewModel.recommendationErrorMessage = nil
        viewModel.isLoadingRecommendations = false
    }
    
    // Expands the route bounds so map content is not hidden by sheets or controls.
    private func paddedMapRect(for route: MKRoute) -> MKMapRect {
        let rect = route.polyline.boundingMapRect
        let padding = max(max(rect.size.width, rect.size.height) * 0.25, 1_000)
        return rect.insetBy(dx: -padding, dy: -padding)
    }
    
    // Formats route distance for UI display.
    private func formatDrivingDistance(_ distance: CLLocationDistance) -> String {
        if distance < 1000 {
            return "\(Int(distance.rounded())) m"
        }
        return String(format: "%.1f km", distance / 1000)
    }
    
    // Formats incident-to-hydrant distance with the same units as route distance.
    private func formatIncidentDistance(_ distance: CLLocationDistance) -> String {
        formatDrivingDistance(distance)
    }
    
    // Formats expected travel time without exposing raw seconds.
    private func formatETA(_ travelTime: TimeInterval) -> String {
        let minutes = Int((travelTime / 60).rounded(.up))
        if minutes < 60 {
            return "\(minutes) min"
        }
        
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        if remainingMinutes == 0 {
            return "\(hours) hr"
        }
        return "\(hours) hr \(remainingMinutes) min"
    }
    
    // Lays out the compact route details sheet.
    private func routeDetailsPanel(
        hydrant: Hydrant,
        route: MKRoute
    ) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text(hydrant.title)
                    .font(.headline)
                Label("Available", systemImage: "circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.green)
            }
            
            HStack(alignment: .top, spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Distance from Incident")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(viewModel.formattedDistanceFromIncident(to: hydrant))
                        .font(.subheadline.weight(.semibold))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Route from Your Location")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(formatDrivingDistance(route.distance)) • \(formatETA(route.expectedTravelTime))")
                        .font(.subheadline.weight(.semibold))
                }
            }
            
            Button(role: .destructive) {
                endRoute()
            } label: {
                Text("End Route")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // Lays out the active incident details sheet.
    private func incidentDetailsPanel(coordinate: CLLocationCoordinate2D) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Label("Lokasi Kebakaran", systemImage: "flame.fill")
                    .font(.headline)
                    .foregroundStyle(.red)
                Text("Incident is active. End it only when this fire response is complete.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Incident Coordinate")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Latitude: \(coordinate.latitude, format: .number.precision(.fractionLength(5)))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Text("Longitude: \(coordinate.longitude, format: .number.precision(.fractionLength(5)))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recommendations")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(viewModel.displayedRecommendations.count)")
                        .font(.subheadline.weight(.semibold))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Route")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(route == nil ? "Inactive" : "Active")
                        .font(.subheadline.weight(.semibold))
                }
            }
            
            Button(role: .destructive) {
                shouldShowEndIncidentAuthorizationAfterDetails = true
                isShowingIncidentDetails = false
            } label: {
                Text("End Incident")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // Shows total, usable, and unusable hydrant counts.
    private var statusBar: some View {
        HStack {
            Spacer()
            Spacer()
            Spacer()
            MetricView(value: viewModel.hydrants.count.formatted(), label: "Total")
            Spacer()
            Spacer()
            MetricView(value: viewModel.usableCount.formatted(), label: "Siap")
            Spacer()
            Spacer()
            MetricView(value: viewModel.unusableCount.formatted(), label: "Rusak")
            Spacer()
            Spacer()
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
    
    // Lets the user switch between all, usable, and unusable hydrants.
    private var filterBar: some View {
        Picker("Kondisi", selection: $viewModel.statusFilter) {
            ForEach(HydrantStatusFilter.allCases) { filter in
                Text(filter.title).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .padding(8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
    // Lays out loading, empty, and ranked hydrant recommendation states.
    private var nearbyHydrantsPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nearby Hydrants")
                        .font(.headline)
                    Text("\(viewModel.displayedRecommendations.count) recommended hydrants")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                if viewModel.isLoadingRecommendations {
                    ProgressView("Finding best hydrants…")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 32)
                } else if viewModel.displayedRecommendations.isEmpty {
                    ContentUnavailableView(
                        "No Hydrants Found",
                        systemImage: "drop.triangle",
                        description: Text("Place an incident near usable hydrants.")
                    )
                    .padding(.vertical, 24)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(viewModel.displayedRecommendations.enumerated()), id: \.element.id) { index, recommendation in
                            Button {
                                selectHydrantForRoute(recommendation.hydrant)
                            } label: {
                                HStack(alignment: .center, spacing: 12) {
                                    Image(systemName: "drop.fill")
                                        .font(.title3)
                                        .foregroundStyle(.blue)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(spacing: 8) {
                                            Text(recommendation.hydrant.title)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(.primary)
                                            if index == 0 {
                                                Text("Recommended")
                                                    .font(.caption2.weight(.semibold))
                                                    .foregroundStyle(.blue)
                                            }
                                        }
                                        
                                        Text("Available")
                                            .font(.caption)
                                            .foregroundStyle(.green)
                                        
                                        HStack(spacing: 16) {
                                            Label(
                                                "\(formatIncidentDistance(recommendation.incidentDistance)) from incident",
                                                systemImage: "flame.fill"
                                            )
                                            .foregroundStyle(.secondary)
                                            
                                            Label(
                                                recommendationRouteText(recommendation),
                                                systemImage: "timer"
                                            )
                                            .foregroundStyle(recommendation.expectedTravelTime == nil ? .tertiary : .secondary)
                                        }
                                        .font(.caption)
                                        .lineLimit(1)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.plain)
                            .contentShape(Rectangle())
                            
                            if recommendation.id != viewModel.displayedRecommendations.last?.id {
                                Divider()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // Formats optional candidate route metrics for recommendation rows.
    private func recommendationRouteText(_ recommendation: HydrantRecommendation) -> String {
        guard let drivingDistance = recommendation.drivingDistance,
              let expectedTravelTime = recommendation.expectedTravelTime else {
            return "Route unavailable"
        }
        return "\(formatDrivingDistance(drivingDistance)) • \(formatETA(expectedTravelTime))"
    }
}

#Preview {
    ContentView()
}
