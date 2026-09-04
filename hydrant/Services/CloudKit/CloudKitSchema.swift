//
//  CloudKitSchema.swift
//  hydrant
//
//  Single source of truth for CloudKit record-type names and field keys.
//  Every string used against CloudKit lives here so the app and the CloudKit
//  Dashboard schema never drift apart. When you add a field in the Dashboard,
//  add it here too (and mark it queryable/sortable there if the app filters on it).
//

import Foundation

enum CloudKitSchema {
    // The iCloud container backing the whole app. Must match the identifier in
    // hydrant.entitlements and the container created in the CloudKit Dashboard.
    static let containerIdentifier = "iCloud.com.damkar.hydrant"

    // Shared operational state (incidents, claims, condition reports) lives in the
    // PUBLIC database so every unit's device sees the same picture. The static grid
    // and registry stay bundled/precomputed and are not modelled here.

    enum Incident {
        static let type = "Insiden"
        static let kode = "kode"                 // queryable
        static let name = "nama"
        static let latitude = "lat"
        static let longitude = "lon"
        static let cellID = "cellID"             // bridge into the bundled grid
        static let wilayahID = "wilayahID"       // queryable
        static let createdBy = "dibuatOlehKode"  // unit code, not a user (device-identity)
        static let createdAt = "dibuatAt"        // queryable + sortable
        static let status = "status"             // queryable: aktif | selesai | dibatalkan
        static let modeOperasi = "modeOperasi"   // isi_ulang | suplai_selang
    }

    enum Claim {
        static let type = "HidranKlaim"
        // recordName is deterministic: "klaim-aktif-<hidranID>". Its per-zone
        // uniqueness IS the "one active claim per hydrant" constraint that CloudKit
        // has no unique-index feature for. See HydrantClaimRepository.
        static func recordName(hidranID: Int) -> String { "klaim-aktif-\(hidranID)" }

        static let hidranID = "hidranID"         // queryable
        static let insidenID = "insidenID"       // queryable
        static let unitKode = "unitKode"
        static let startedAt = "mulaiAt"
        static let expiresAt = "expiresAt"       // read-time TTL, no server sweep

        // Default claim lifetime before it is treated as expired at read time.
        static let defaultTTL: TimeInterval = 90 * 60
    }

    enum ConditionReport {
        static let type = "LaporanKondisi"
        static let hidranID = "hidranID"         // queryable
        static let insidenID = "insidenID"       // queryable
        static let reportedBy = "unitKode"
        static let time = "waktu"                // sortable
        static let level = "tingkat"             // queryable: sesaat | permanen
        static let condition = "kondisi"
        static let note = "catatan"
        static let photo = "foto"                // CKAsset
        static let expiresAt = "kedaluwarsaAt"   // 'sesaat' = waktu + 24h; read-time filter
    }
}
