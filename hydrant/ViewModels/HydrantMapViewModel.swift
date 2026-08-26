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
    var isLoadingRecommendations = false
    var recommendationErrorMessage: String?
    
    // Selected status filter for the map markers.
    var statusFilter: HydrantStatusFilter = .usable

    private let recommendationCandidateLimit = 8
    private let displayedRecommendationLimit = 5
    
    init(hydrants: [Hydrant] = HydrantStore.load()) {
        self.hydrants = hydrants
        cameraPosition = .region(HydrantMapDefaults.jakartaRegion)
    }
    var displayedRecommendations: [HydrantRecommendation] {
        Array(hydrantRecommendations.prefix(displayedRecommendationLimit))
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
        if distance < 1000 {
            return "\(Int(distance)) m"
        }
        return String(
            format: "%.1f km",
            distance / 1000
        )
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
        for candidate in candidates {
            var drivingDistance: CLLocationDistance?
            var expectedTravelTime: TimeInterval?

            if let firefighterLocation {
                do {
                    let metrics = try await routeService.calculateRouteMetrics(
                        from: firefighterLocation.coordinate,
                        to: candidate.hydrant.coordinate
                    )
                    drivingDistance = metrics.distance
                    expectedTravelTime = metrics.expectedTravelTime
                } catch {
                    print("⚠️ No route for \(candidate.hydrant.title): \(error)")
                }
            }

            let recommendation = HydrantRecommendation(
                hydrant: candidate.hydrant,
                incidentDistance: candidate.incidentDistance,
                drivingDistance: drivingDistance,
                expectedTravelTime: expectedTravelTime
            )
            evaluatedRecommendations.append(recommendation)

            print("💧 \(recommendation.hydrant.title)")
            print("Incident distance: \(formatDistance(recommendation.incidentDistance))")
            if let drivingDistance = recommendation.drivingDistance,
               let expectedTravelTime = recommendation.expectedTravelTime {
                print("Driving distance: \(formatDistance(drivingDistance))")
                print("ETA: \(formatETA(expectedTravelTime))")
            } else {
                print("Driving route: unavailable")
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

    // Moves the map camera to the user's current location.
    func updateCamera(to location: CLLocation) {
        cameraPosition = .region(
            MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.035, longitudeDelta: 0.035)
            )
        )
    }

    private func formatDistance(_ distance: CLLocationDistance) -> String {
        if distance < 1000 {
            return "\(Int(distance.rounded())) m"
        }
        return String(format: "%.1f km", distance / 1000)
    }

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
}

// Default map region centered on Jakarta.
enum HydrantMapDefaults {
    static let jakartaRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -6.2088, longitude: 106.8456),
        span: MKCoordinateSpan(latitudeDelta: 0.33, longitudeDelta: 0.33)
    )
}
