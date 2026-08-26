//
//  Hydrant.swift
//  hydrant
//
//  Created by Yeba Teo on 18/08/26.
//

import CoreLocation
import Foundation

// One hydrant record from the bundled JSON dataset.
struct Hydrant: Decodable, Identifiable, Hashable {
    let wilayah: String
    let kecamatan: String
    let kelurahan: String
    let namaHidran: String
    let alamat: String
    let longitude: Double
    let latitude: Double
    let kondisi: String

    var id: String {
        "\(latitude),\(longitude),\(alamat)"
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }

    // Derives a usable flag from the Indonesian condition text.
    var isUsable: Bool {
        kondisi.localizedCaseInsensitiveContains("BISA DIGUNAKAN")
        && !kondisi.localizedCaseInsensitiveContains("TIDAK")
    }

    var title: String {
        namaHidran.capitalized
    }

    var searchableText: String {
        [wilayah, kecamatan, kelurahan, namaHidran, alamat, kondisi].joined(separator: " ")
    }

    var accessibilityLabel: String {
        "\(title), \(kondisi.capitalized), \(alamat.capitalized)"
    }

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
