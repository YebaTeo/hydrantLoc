//
//  HydrantRecommendation.swift
//  hydrant
//
//  Created by Yeba Teo on 26/08/26.
//

import CoreLocation
import Foundation

struct HydrantRecommendation: Identifiable {
    let hydrant: Hydrant
    let incidentDistance: CLLocationDistance
    let drivingDistance: CLLocationDistance?
    let expectedTravelTime: TimeInterval?

    var id: Hydrant.ID {
        hydrant.id
    }
}

// A fire station (Pos Damkar) ranked by straight-line distance from the incident.
struct FireStationRecommendation: Identifiable {
    let station: FireStation
    let incidentDistance: CLLocationDistance

    var id: FireStation.ID {
        station.id
    }
}
