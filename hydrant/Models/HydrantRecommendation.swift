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
