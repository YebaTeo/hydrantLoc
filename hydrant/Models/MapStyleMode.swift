//
//  MapStyleMode.swift
//  hydrant
//

import MapKit
import SwiftUI

// Map appearance modes offered by the map-mode control, mirroring Apple Maps'
// Standard and Satellite options.
enum MapStyleMode: String, CaseIterable, Identifiable {
    case standard
    case satellite

    var id: Self { self }

    var title: String {
        switch self {
        case .standard: "Standar"
        case .satellite: "Satelit"
        }
    }

    var systemImage: String {
        switch self {
        case .standard: "map"
        case .satellite: "globe.americas.fill"
        }
    }

    // MapStyle is a single opaque value type, so both cases share one property.
    var mapStyle: MapStyle {
        switch self {
        case .standard:
            .standard(elevation: .realistic, pointsOfInterest: .excludingAll)
        case .satellite:
            .hybrid(elevation: .realistic, pointsOfInterest: .excludingAll)
        }
    }
}
