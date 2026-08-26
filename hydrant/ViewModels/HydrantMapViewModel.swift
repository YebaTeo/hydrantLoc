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
    var hydrants: [Hydrant]
    var cameraPosition: MapCameraPosition
    var selectedHydrant: Hydrant?
    var searchText = ""
    var statusFilter: HydrantStatusFilter = .usable

    init(hydrants: [Hydrant] = HydrantStore.load()) {
        self.hydrants = hydrants
        cameraPosition = .region(HydrantMapDefaults.jakartaRegion)
    }

    // Applies the selected filter and search text to the full hydrant list.
    var filteredHydrants: [Hydrant] {
        hydrants.filter { hydrant in
            statusFilter.includes(hydrant)
            && (
                searchText.isEmpty
                || hydrant.searchableText.localizedCaseInsensitiveContains(searchText)
            )
        }
    }

    var availableHydrants: [Hydrant] {
        hydrants.filter(\.isUsable)
    }

    var usableCount: Int {
        hydrants.filter(\.isUsable).count
    }

    var unusableCount: Int {
        hydrants.count - usableCount
    }

    // Selects a hydrant and zooms the map around it.
    func select(_ hydrant: Hydrant) {
        selectedHydrant = hydrant
        cameraPosition = .region(
            MKCoordinateRegion(
                center: hydrant.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
            )
        )
    }

    // Finds and selects the closest usable hydrant from the user's current location.
    func selectNearestUsableHydrant(from currentLocation: CLLocation?) -> Bool {
        guard let currentLocation else {
            return false
        }

        let nearest = hydrants
            .filter(\.isUsable)
            .min { lhs, rhs in
                lhs.location.distance(from: currentLocation) < rhs.location.distance(from: currentLocation)
            }

        if let nearest {
            statusFilter = .usable
            select(nearest)
            return true
        }

        return false
    }

    // Moves the map camera to the user's location; a smaller span zooms in more.
    func updateCamera(to location: CLLocation, span: Double = 0.035) {
        cameraPosition = .region(
            MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span)
            )
        )
    }
}

// Default map region centered on Jakarta.
enum HydrantMapDefaults {
    static let jakartaRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -6.2088, longitude: 106.8456),
        span: MKCoordinateSpan(latitudeDelta: 0.33, longitudeDelta: 0.33)
    )
}
