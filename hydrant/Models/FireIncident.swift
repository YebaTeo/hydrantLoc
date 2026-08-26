//
//  FireIncident.swift
//  hydrant
//
//  Created by Yeba Teo on 18/08/26.
//

import CoreLocation
import Foundation

struct FireIncident: Decodable, Identifiable, Hashable {
    let latitude: Double
    let longitude: Double
    let title: String
    let kategori: String
    let alamat: String

    var id: String {
        "\(latitude),\(longitude),\(title)"
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
