//
//  HydrantMapViewModel.swift
//  hydrant
//
//  Created by Yeba Teo on 18/08/26.
//

import CoreLocation
import MapKit
import Observation
import SwiftUI

// Stores map screen state and handles filtering, selection, and camera updates.
@Observable
final class HydrantMapViewModel {
    // Full hydrant dataset loaded from the app bundle.
    var hydrants: [Hydrant]
    
    // Current visible map region/camera position.
    var cameraPosition: MapCameraPosition
    
    // Location of the fire/emergency incident.
    var incidentCoordinate: CLLocationCoordinate2D?

    // Ranked hydrant recommendations for the current incident.
    var hydrantRecommendations: [HydrantRecommendation] = []
    var recommendedHydrantRoutes: [RecommendedHydrantRoute] = []
    var isLoadingRecommendations = false
    var recommendationErrorMessage: String?
    
    // Selected status filter for the map markers.
    var statusFilter: HydrantStatusFilter = .usable

    // Selected hydrant for direct map inspection.
    var selectedHydrant: Hydrant?

    // Full fire station dataset loaded from the app bundle.
    var fireStations: [FireStation]

    // Selected fire station for direct map inspection.
    var selectedFireStation: FireStation?

    // Nearest fire stations (Pos Damkar) to the current incident.
    var fireStationRecommendations: [FireStationRecommendation] = []

    // Standard vs. satellite map appearance.
    var mapStyleMode: MapStyleMode = .standard

    private let recommendationCandidateLimit = 8
    private let displayedRecommendationLimit = 5
    private let fireStationRecommendationLimit = 3
    
    init(
        hydrants: [Hydrant] = HydrantStore.load(),
        fireStations: [FireStation] = FireStationStore.load()
    ) {
        self.hydrants = hydrants
        self.fireStations = fireStations
        cameraPosition = .region(HydrantMapDefaults.jakartaRegion)
    }
    var displayedRecommendations: [HydrantRecommendation] {
        Array(hydrantRecommendations.prefix(displayedRecommendationLimit))
    }

    // Development HomeView uses this lightweight list for available hydrant markers.
    var availableHydrants: [Hydrant] {
        hydrants.filter(\.isUsable)
    }

    // Applies the selected filter to the full hydrant list.
    var filteredHydrants: [Hydrant] {
        hydrants.filter { hydrant in
            statusFilter.includes(hydrant)
        }
    }
    
    // Number of hydrants marked usable.
    var usableCount: Int {
        hydrants.filter(\.isUsable).count
    }
    
    // Number of hydrants marked unusable.
    var unusableCount: Int {
        hydrants.count - usableCount
    }
    
    func distanceFromIncident(to hydrant: Hydrant) -> CLLocationDistance? {
        guard let incidentCoordinate else {
            return nil
        }
        
        let incidentLocation = CLLocation(
            latitude: incidentCoordinate.latitude,
            longitude: incidentCoordinate.longitude
        )
        
        return hydrant.location.distance(from: incidentLocation)
    }
    func formattedDistanceFromIncident(to hydrant: Hydrant) -> String {
        guard let distance = distanceFromIncident(to: hydrant) else {
            return "-"
        }
        return DistanceFormatting.distance(distance)
    }

    // Ranks the operational fire stations by straight-line distance from the
    // incident and keeps the nearest few as recommendations.
    func updateFireStationRecommendations(
        incidentCoordinate: CLLocationCoordinate2D
    ) {
        let incidentLocation = CLLocation(
            latitude: incidentCoordinate.latitude,
            longitude: incidentCoordinate.longitude
        )

        fireStationRecommendations = fireStations
            .filter(\.isOperational)
            .map { station in
                FireStationRecommendation(
                    station: station,
                    incidentDistance: station.location.distance(from: incidentLocation)
                )
            }
            .sorted { $0.incidentDistance < $1.incidentDistance }
            .prefix(fireStationRecommendationLimit)
            .map { $0 }
    }

    @MainActor
    func updateHydrantRecommendations(
        incidentCoordinate: CLLocationCoordinate2D,
        firefighterLocation: CLLocation?,
        routeService: RouteService
    ) async {
        isLoadingRecommendations = true
        recommendationErrorMessage = nil
        hydrantRecommendations = []
        recommendedHydrantRoutes = []

        print("🔥 INCIDENT: \(incidentCoordinate.latitude), \(incidentCoordinate.longitude)")
        if let firefighterLocation {
            let coordinate = firefighterLocation.coordinate
            print("🚒 FIREFIGHTER: \(coordinate.latitude), \(coordinate.longitude)")
        } else {
            print("🚒 FIREFIGHTER: unavailable")
        }

        let incidentLocation = CLLocation(
            latitude: incidentCoordinate.latitude,
            longitude: incidentCoordinate.longitude
        )

        let candidates = hydrants
            .filter(\.isUsable)
            .map { hydrant in
                HydrantRecommendation(
                    hydrant: hydrant,
                    incidentDistance: hydrant.location.distance(from: incidentLocation),
                    drivingDistance: nil,
                    expectedTravelTime: nil
                )
            }
            .sorted { lhs, rhs in
                lhs.incidentDistance < rhs.incidentDistance
            }
            .prefix(recommendationCandidateLimit)

        print("Evaluating \(candidates.count) usable hydrant candidates...")

        var evaluatedRecommendations: [HydrantRecommendation] = []
        if let firefighterLocation {
            let candidatesArray = Array(candidates)
            evaluatedRecommendations = await withTaskGroup(of: (HydrantRecommendation, Int).self) { group in
                for (index, candidate) in candidatesArray.enumerated() {
                    let hydrantCoordinate = candidate.hydrant.coordinate
                    let hydrantTitle = candidate.hydrant.title
                    group.addTask {
                        var drivingDistance: CLLocationDistance?
                        var expectedTravelTime: TimeInterval?
                        do {
                            let metrics = try await routeService.calculateRouteMetrics(
                                from: firefighterLocation.coordinate,
                                to: hydrantCoordinate
                            )
                            drivingDistance = metrics.distance
                            expectedTravelTime = metrics.expectedTravelTime
                        } catch {
                            print("⚠️ No route for \(hydrantTitle): \(error)")
                        }
                        let recommendation = HydrantRecommendation(
                            hydrant: candidate.hydrant,
                            incidentDistance: candidate.incidentDistance,
                            drivingDistance: drivingDistance,
                            expectedTravelTime: expectedTravelTime
                        )
                        return (recommendation, index)
                    }
                }
                var results: [(HydrantRecommendation, Int)] = []
                for await result in group {
                    results.append(result)
                }
                return results.sorted(by: { $0.1 < $1.1 }).map(\.0)
            }
        } else {
            evaluatedRecommendations = candidates.map { candidate in
                HydrantRecommendation(
                    hydrant: candidate.hydrant,
                    incidentDistance: candidate.incidentDistance,
                    drivingDistance: nil,
                    expectedTravelTime: nil
                )
            }
        }

        // Prefer candidates with valid route data, then shortest ETA, incident distance, and driving distance.
        hydrantRecommendations = evaluatedRecommendations.sorted { lhs, rhs in
            switch (lhs.expectedTravelTime, rhs.expectedTravelTime) {
            case let (lhsETA?, rhsETA?):
                if lhsETA != rhsETA {
                    return lhsETA < rhsETA
                }
                if lhs.incidentDistance != rhs.incidentDistance {
                    return lhs.incidentDistance < rhs.incidentDistance
                }
                return (lhs.drivingDistance ?? .greatestFiniteMagnitude)
                    < (rhs.drivingDistance ?? .greatestFiniteMagnitude)
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            case (nil, nil):
                return lhs.incidentDistance < rhs.incidentDistance
            }
        }

        print("✅ Hydrant recommendation ranking complete")
        for (index, recommendation) in displayedRecommendations.enumerated() {
            print("\(index + 1). \(recommendation.hydrant.title)")
        }

        isLoadingRecommendations = false
    }

    @MainActor
    func updateRecommendedHydrantRoutes(
        incidentCoordinate: CLLocationCoordinate2D,
        routeService: RouteService
    ) async {
        let recommendations = displayedRecommendations
        guard !recommendations.isEmpty else {
            recommendedHydrantRoutes = []
            return
        }

        let routes = await withTaskGroup(of: RecommendedHydrantRoute?.self) { group in
            for recommendation in recommendations {
                let hydrantID = recommendation.id
                let hydrantCoordinate = recommendation.hydrant.coordinate
                let hydrantTitle = recommendation.hydrant.title
                group.addTask {
                    do {
                        let route = try await routeService.calculateRoute(
                            from: incidentCoordinate,
                            to: hydrantCoordinate
                        )
                        return RecommendedHydrantRoute(
                            hydrantID: hydrantID,
                            route: route
                        )
                    } catch {
                        print("⚠️ No incident route for \(hydrantTitle): \(error)")
                        return nil
                    }
                }
            }

            var calculatedRoutes: [RecommendedHydrantRoute] = []
            for await route in group {
                if let route {
                    calculatedRoutes.append(route)
                }
            }
            return calculatedRoutes
        }

        guard coordinatesMatch(self.incidentCoordinate, incidentCoordinate) else { return }

        let recommendationOrder = Dictionary(
            uniqueKeysWithValues: recommendations.enumerated().map { index, recommendation in
                (recommendation.id, index)
            }
        )
        recommendedHydrantRoutes = routes.sorted { lhs, rhs in
            (recommendationOrder[lhs.hydrantID] ?? Int.max) < (recommendationOrder[rhs.hydrantID] ?? Int.max)
        }
    }

    private func coordinatesMatch(
        _ lhs: CLLocationCoordinate2D?,
        _ rhs: CLLocationCoordinate2D
    ) -> Bool {
        guard let lhs else { return false }
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }

    // Moves the map camera to a location with a specified zoom span.
    func updateCamera(to location: CLLocation, span: CLLocationDegrees = 0.035) {
        cameraPosition = .region(
            MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span)
            )
        )
    }

    // Pans the map camera to a location while preserving the user's current zoom scale.
    func panCamera(to location: CLLocation) {
        if let currentRegion = cameraPosition.region {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: location.coordinate,
                    span: currentRegion.span
                )
            )
        } else {
            updateCamera(to: location)
        }
    }
}

struct RecommendedHydrantRoute: Identifiable {
    let hydrantID: Hydrant.ID
    let route: MKRoute

    var id: Hydrant.ID {
        hydrantID
    }
}

// Default map region centered on Jakarta.
enum HydrantMapDefaults {
    static let jakartaRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -6.2088, longitude: 106.8456),
        span: MKCoordinateSpan(latitudeDelta: 0.33, longitudeDelta: 0.33)
    )
}
