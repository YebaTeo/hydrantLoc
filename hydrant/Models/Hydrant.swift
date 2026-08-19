//
//  Hydrant.swift
//  hydrant
//
//  Created by Yeba Teo on 18/08/26.
//

import CoreLocation
import Foundation

// Represents one hydrant record from the bundled JSON dataset.
struct Hydrant: Decodable, Identifiable, Hashable {
    // Administrative area and address data from the source JSON.
    let wilayah: String
    let kecamatan: String
    let kelurahan: String
    let namaHidran: String
    let alamat: String

    // Geographic coordinate from the source JSON.
    let longitude: Double
    let latitude: Double

    // Text status, for example usable or unusable.
    let kondisi: String

    // Stable identifier for SwiftUI lists and map annotations.
    var id: String {
        "\(latitude),\(longitude),\(alamat)"
    }

    // Coordinate format required by MapKit annotations.
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    // Location format used for distance calculations and navigation.
    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }

    // Converts the Indonesian condition text into a simple usable flag.
    var isUsable: Bool {
        kondisi.localizedCaseInsensitiveContains("BISA DIGUNAKAN")
        && !kondisi.localizedCaseInsensitiveContains("TIDAK")
    }

    // Display title used on annotations and detail screens.
    var title: String {
        namaHidran.capitalized
    }

    // Combined text used by the search field.
    var searchableText: String {
        [wilayah, kecamatan, kelurahan, namaHidran, alamat, kondisi].joined(separator: " ")
    }

    // Spoken label for VoiceOver users.
    var accessibilityLabel: String {
        "\(title), \(kondisi.capitalized), \(alamat.capitalized)"
    }

    // Maps snake_case JSON keys into Swift camelCase properties.
    enum CodingKeys: String, CodingKey {
        case wilayah
        case kecamatan
        case kelurahan
        case namaHidran = "nama_hidran"
        case alamat
        case longitude
        case latitude
        case kondisi
    }
}
