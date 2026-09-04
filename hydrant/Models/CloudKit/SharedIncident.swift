//
//  SharedIncident.swift
//  hydrant
//
//  CloudKit-backed view of an incident. Wraps the existing local `Incident`
//  struct (kept untouched) with the fields the shared layer needs: a lifecycle
//  status and the server change tag used for optimistic concurrency.
//
//  Keeping this separate from `Incident` means the map/flow view models can stay
//  on the plain local model until we wire the repository in; the CloudKit layer
//  converts at its boundary.
//

import CloudKit
import CoreLocation
import Foundation

enum IncidentStatus: String, CaseIterable {
    case aktif
    case selesai
    case dibatalkan
}

struct SharedIncident: Identifiable, Equatable {
    var incident: Incident
    var status: IncidentStatus
    var createdByUnit: String?
    var cellID: Int?

    // Opaque server change tag; nil for a record not yet saved. Used so an update
    // only lands if the device holds the latest version (last-writer conflicts fail
    // loudly instead of silently clobbering).
    var changeTag: String?

    var id: UUID { incident.id }

    init(
        incident: Incident,
        status: IncidentStatus = .aktif,
        createdByUnit: String? = nil,
        cellID: Int? = nil,
        changeTag: String? = nil
    ) {
        self.incident = incident
        self.status = status
        self.createdByUnit = createdByUnit
        self.cellID = cellID
        self.changeTag = changeTag
    }

    static func == (lhs: SharedIncident, rhs: SharedIncident) -> Bool {
        lhs.incident == rhs.incident && lhs.status == rhs.status
    }
}

// MARK: - CKRecord mapping

extension SharedIncident {
    // The record id is derived from the incident's UUID so replaying an offline
    // "create incident" is idempotent: the same action always targets the same
    // record name and cannot produce a duplicate TKP.
    static func recordID(for incidentID: UUID) -> CKRecord.ID {
        CKRecord.ID(recordName: "insiden-\(incidentID.uuidString)")
    }

    // Build a CKRecord to save. Reuses the server record when updating so the
    // change tag is preserved for conflict detection.
    func makeRecord(existing: CKRecord? = nil) -> CKRecord {
        let record = existing ?? CKRecord(
            recordType: CloudKitSchema.Incident.type,
            recordID: Self.recordID(for: incident.id)
        )
        record[CloudKitSchema.Incident.name] = incident.name as CKRecordValue
        record[CloudKitSchema.Incident.latitude] = incident.coordinate.latitude as CKRecordValue
        record[CloudKitSchema.Incident.longitude] = incident.coordinate.longitude as CKRecordValue
        record[CloudKitSchema.Incident.createdAt] = incident.createdAt as CKRecordValue
        record[CloudKitSchema.Incident.status] = status.rawValue as CKRecordValue
        if let createdByUnit {
            record[CloudKitSchema.Incident.createdBy] = createdByUnit as CKRecordValue
        }
        if let cellID {
            record[CloudKitSchema.Incident.cellID] = cellID as CKRecordValue
        }
        return record
    }

    // Rebuild the domain value from a fetched record. Returns nil when the record
    // is missing required fields (treated as skip-and-log, not a crash).
    init?(record: CKRecord) {
        guard
            record.recordType == CloudKitSchema.Incident.type,
            let name = record[CloudKitSchema.Incident.name] as? String,
            let lat = record[CloudKitSchema.Incident.latitude] as? Double,
            let lon = record[CloudKitSchema.Incident.longitude] as? Double,
            let createdAt = record[CloudKitSchema.Incident.createdAt] as? Date,
            let uuid = UUID(uuidString: record.recordID.recordName
                .replacingOccurrences(of: "insiden-", with: ""))
        else {
            return nil
        }

        let statusRaw = record[CloudKitSchema.Incident.status] as? String
        self.init(
            incident: Incident(
                id: uuid,
                name: name,
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                createdAt: createdAt
            ),
            status: statusRaw.flatMap(IncidentStatus.init) ?? .aktif,
            createdByUnit: record[CloudKitSchema.Incident.createdBy] as? String,
            cellID: record[CloudKitSchema.Incident.cellID] as? Int,
            changeTag: record.recordChangeTag
        )
    }
}
