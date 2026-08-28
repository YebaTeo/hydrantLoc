//
//  Incident.swift
//  hydrant
//

import CoreLocation
import Foundation

// One fire incident report. The app can hold several at once; they are listed in
// the controller sheet and each can be opened for hydrant recommendations.
struct Incident: Identifiable, Equatable {
    let id: UUID
    var name: String
    var coordinate: CLLocationCoordinate2D
    let createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        coordinate: CLLocationCoordinate2D,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.coordinate = coordinate
        self.createdAt = createdAt
    }

    // CLLocationCoordinate2D is not Equatable, so identity is by id.
    static func == (lhs: Incident, rhs: Incident) -> Bool {
        lhs.id == rhs.id
    }

    var coordinateText: String {
        String(
            format: "%.5f, %.5f",
            coordinate.latitude,
            coordinate.longitude
        )
    }

    var createdAtText: String {
        createdAt.formatted(date: .omitted, time: .shortened)
    }
}
