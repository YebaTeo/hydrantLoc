//
//  HydrantClaim.swift
//  hydrant
//
//  A unit's active hold on a hydrant during an incident. The domain value plus
//  its CKRecord mapping. The uniqueness of the claim is not a field on the record
//  — it is the record's deterministic name ("klaim-aktif-<hidranID>"), which can
//  exist at most once per hydrant. See HydrantClaimRepository for how that gives
//  us the atomic "one active claim per hydrant" that CloudKit has no index for.
//

import CloudKit
import Foundation

struct HydrantClaim: Identifiable, Equatable {
    let hidranID: Int
    let incidentID: UUID
    let unitKode: String
    let startedAt: Date
    let expiresAt: Date

    var id: Int { hidranID }

    // Read-time TTL: a claim past its expiry is treated as free even though the
    // record may still exist, so no server-side sweep job is needed for the demo.
    func isActive(now: Date = .now) -> Bool { now < expiresAt }

    init(
        hidranID: Int,
        incidentID: UUID,
        unitKode: String,
        startedAt: Date = .now,
        expiresAt: Date? = nil
    ) {
        self.hidranID = hidranID
        self.incidentID = incidentID
        self.unitKode = unitKode
        self.startedAt = startedAt
        self.expiresAt = expiresAt ?? startedAt.addingTimeInterval(CloudKitSchema.Claim.defaultTTL)
    }
}

// MARK: - CKRecord mapping

extension HydrantClaim {
    var recordID: CKRecord.ID {
        CKRecord.ID(recordName: CloudKitSchema.Claim.recordName(hidranID: hidranID))
    }

    func makeRecord() -> CKRecord {
        let record = CKRecord(recordType: CloudKitSchema.Claim.type, recordID: recordID)
        record[CloudKitSchema.Claim.hidranID] = hidranID as CKRecordValue
        record[CloudKitSchema.Claim.insidenID] = incidentID.uuidString as CKRecordValue
        record[CloudKitSchema.Claim.unitKode] = unitKode as CKRecordValue
        record[CloudKitSchema.Claim.startedAt] = startedAt as CKRecordValue
        record[CloudKitSchema.Claim.expiresAt] = expiresAt as CKRecordValue
        return record
    }

    init?(record: CKRecord) {
        guard
            record.recordType == CloudKitSchema.Claim.type,
            let hidranID = record[CloudKitSchema.Claim.hidranID] as? Int,
            let insidenRaw = record[CloudKitSchema.Claim.insidenID] as? String,
            let incidentID = UUID(uuidString: insidenRaw),
            let unitKode = record[CloudKitSchema.Claim.unitKode] as? String,
            let startedAt = record[CloudKitSchema.Claim.startedAt] as? Date,
            let expiresAt = record[CloudKitSchema.Claim.expiresAt] as? Date
        else {
            return nil
        }
        self.init(
            hidranID: hidranID,
            incidentID: incidentID,
            unitKode: unitKode,
            startedAt: startedAt,
            expiresAt: expiresAt
        )
    }
}

// Outcome of a claim attempt, surfaced to the UI as a clear message rather than a
// raw CloudKit error — an emergency app must always say what to do next.
enum ClaimError: Error, Equatable {
    // Lost the race: another unit already holds this hydrant.
    case alreadyClaimed(byUnit: String?, since: Date?)
    // No iCloud account / offline; the action is queued locally by the caller.
    case unavailable
    case other(String)
}
