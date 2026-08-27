//
//  MapMode.swift
//  hydrant
//
//  Created by Yeba Teo on 18/08/26.
//

import MapKit
import SwiftUI

enum MapMode: String, CaseIterable, Identifiable {
    case explore
    case satellite

    var id: Self { self }

    var title: String {
        switch self {
        case .explore:
            "Jelajah"
        case .satellite:
            "Satelit"
        }
    }

    var systemImage: String {
        switch self {
        case .explore:
            "map"
        case .satellite:
            "globe.americas.fill"
        }
    }

    var mapStyle: MapStyle {
        switch self {
        case .explore:
            .standard(elevation: .realistic, pointsOfInterest: .excludingAll, showsTraffic: true)
        case .satellite:
            .hybrid(elevation: .realistic)
        }
    }

    var thumbnailColors: [Color] {
        switch self {
        case .explore:
            [.green, .teal]
        case .satellite:
            [.brown, .gray]
        }
    }
}
