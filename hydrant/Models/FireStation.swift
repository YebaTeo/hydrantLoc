//
//  FireStation.swift
//  hydrant
//

import CoreLocation
import Foundation

// One fire station (Pos Damkar) record from the bundled JSON dataset.
struct FireStation: Decodable, Identifiable, Hashable {
    let namaPos: String
    let wilayah: String
    let kecamatan: String
    let kelurahan: String
    let alamat: String
    let longitude: Double
    let latitude: Double
    let kategoriPos: String?
    let hakMilikPos: String?
    let jenisKendaraan: String?
    let klasifikasi: String?
    let fungsi: String?
    let platNomor: String?
    let kondisi: String?

    var id: String {
        "\(latitude),\(longitude),\(namaPos)"
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }

    var title: String {
        namaPos.capitalized
    }

    var vehicles: [String] {
        guard let jenisKendaraan, !jenisKendaraan.isEmpty else { return [] }
        return jenisKendaraan.components(separatedBy: "|")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    var isOperational: Bool {
        guard let kondisi else { return true }
        return kondisi.localizedCaseInsensitiveContains("BAIK")
    }

    var searchableText: String {
        [namaPos, wilayah, kecamatan, kelurahan, alamat, jenisKendaraan ?? "", kondisi ?? ""].joined(separator: " ")
    }

    var accessibilityLabel: String {
        "\(title), \(alamat.capitalized)"
    }

    enum CodingKeys: String, CodingKey {
        case namaPos = "nama_pos"
        case wilayah
        case kecamatan
        case kelurahan
        case alamat
        case longitude
        case latitude
        case kategoriPos = "kategori_pos"
        case hakMilikPos = "hak_milik_pos"
        case jenisKendaraan = "jenis_kendaraan"
        case klasifikasi
        case fungsi
        case platNomor = "plat_nomor"
        case kondisi
    }
}
