//
//  HydrantClaimRepository.swift
//  hydrant
//
//  The atomic hydrant-claim primitive. CloudKit has no unique index and no
//  server-side transaction, so uniqueness is enforced structurally: a claim is a
//  record whose name is "klaim-aktif-<hidranID>". Record names are unique per
//  zone, so at most one active claim can exist per hydrant. Two units racing for
//  the same hydrant both try to create the same record name — exactly one wins,
//  the other gets a conflict we map to `.alreadyClaimed`.
//

import CloudKit
import Foundation

@MainActor
final class HydrantClaimRepository {
    private let injectedDatabase: CKDatabase?
    private var database: CKDatabase {
        injectedDatabase ?? CloudKitContainer.shared.publicDatabase
    }

    init(database: CKDatabase? = nil) {
        injectedDatabase = database
    }

    // Attempt to claim a hydrant. Succeeds only if no active claim record exists.
    //
    // The `.ifServerRecordUnchanged` policy on a freshly built record (which has no
    // change tag) means "save only if the server has no record here". If another
    // unit created it first, CloudKit returns `.serverRecordChanged` carrying the
    // winner's record — that is our atomic 409.
    func claim(
        hidranID: Int,
        incidentID: UUID,
        unitKode: String
    ) async throws -> HydrantClaim {
        // A stale (expired) claim record can linger because TTL is read-time only.
        // If the existing record is past expiry, take it over; otherwise it's a
        // live claim and we must not steal it.
        if let existing = try await fetchClaim(hidranID: hidranID) {
            if existing.isActive() {
                throw ClaimError.alreadyClaimed(byUnit: existing.unitKode, since: existing.startedAt)
            }
            try await forceRelease(hidranID: hidranID)   // reclaim an expired slot
        }

        let claim = HydrantClaim(hidranID: hidranID, incidentID: incidentID, unitKode: unitKode)
        let record = claim.makeRecord()

        do {
            let result = try await database.modifyRecords(
                saving: [record],
                deleting: [],
                savePolicy: .ifServerRecordUnchanged,
                atomically: true
            )
            for (_, saveResult) in result.saveResults {
                if case let .failure(error) = saveResult {
                    throw mapClaimConflict(error)
                }
            }
            return claim
        } catch let error as CKError {
            throw mapClaimConflict(error)
        }
    }

    // Release a claim held by this unit (normal end-of-use). Deleting the record
    // frees the hydrant. Deleting an already-absent record is treated as success.
    func release(hidranID: Int) async throws {
        try await forceRelease(hidranID: hidranID)
    }

    // Extend a live claim (auto-renew while the unit is still on the incident).
    func extend(hidranID: Int, by interval: TimeInterval = 90 * 60) async throws {
        let recordID = CKRecord.ID(recordName: CloudKitSchema.Claim.recordName(hidranID: hidranID))
        let record = try await database.record(for: recordID)
        record[CloudKitSchema.Claim.expiresAt] = Date.now.addingTimeInterval(interval) as CKRecordValue
        _ = try await database.save(record)
    }

    // All currently-held (non-expired) claims, for the map overlay. Callers apply
    // the read-time TTL filter so an expired-but-not-yet-deleted record reads free.
    func activeClaims() async throws -> [HydrantClaim] {
        let query = CKQuery(
            recordType: CloudKitSchema.Claim.type,
            predicate: NSPredicate(value: true)
        )
        let (matches, _) = try await database.records(matching: query)
        let now = Date.now
        return matches.compactMap { _, result -> HydrantClaim? in
            guard case let .success(record) = result,
                  let claim = HydrantClaim(record: record),
                  claim.isActive(now: now)
            else { return nil }
            return claim
        }
    }

    func subscribeToClaims() async throws {
        let subscriptionID = "sub-klaim-aktif"
        let subscription = CKQuerySubscription(
            recordType: CloudKitSchema.Claim.type,
            predicate: NSPredicate(value: true),
            subscriptionID: subscriptionID,
            options: [.firesOnRecordCreation, .firesOnRecordDeletion, .firesOnRecordUpdate]
        )
        let info = CKSubscription.NotificationInfo()
        info.shouldSendContentAvailable = true
        subscription.notificationInfo = info
        do {
            _ = try await database.save(subscription)
        } catch let error as CKError where error.code == .serverRejectedRequest {
            // Already registered.
        }
    }

    // MARK: - Helpers

    private func fetchClaim(hidranID: Int) async throws -> HydrantClaim? {
        let recordID = CKRecord.ID(recordName: CloudKitSchema.Claim.recordName(hidranID: hidranID))
        do {
            let record = try await database.record(for: recordID)
            return HydrantClaim(record: record)
        } catch let error as CKError where error.code == .unknownItem {
            return nil   // no claim exists — hydrant is free
        }
    }

    private func forceRelease(hidranID: Int) async throws {
        let recordID = CKRecord.ID(recordName: CloudKitSchema.Claim.recordName(hidranID: hidranID))
        do {
            _ = try await database.deleteRecord(withID: recordID)
        } catch let error as CKError where error.code == .unknownItem {
            // Nothing to release.
        }
    }

    // Translate CloudKit conflict/availability errors into the app's ClaimError.
    private func mapClaimConflict(_ error: Error) -> ClaimError {
        guard let ckError = error as? CKError else {
            return .other(error.localizedDescription)
        }
        switch ckError.code {
        case .serverRecordChanged:
            // Someone won the race; the server record identifies the winner.
            let winner = ckError.serverRecord
            let unit = winner?[CloudKitSchema.Claim.unitKode] as? String
            let since = winner?[CloudKitSchema.Claim.startedAt] as? Date
            return .alreadyClaimed(byUnit: unit, since: since)
        case .notAuthenticated, .networkUnavailable, .networkFailure, .serviceUnavailable:
            return .unavailable
        default:
            // A batch failure wraps the real per-record error in partialErrorsByItemID.
            if let partial = ckError.partialErrorsByItemID?.values
                .compactMap({ $0 as? CKError })
                .first(where: { $0.code == .serverRecordChanged }) {
                let unit = partial.serverRecord?[CloudKitSchema.Claim.unitKode] as? String
                let since = partial.serverRecord?[CloudKitSchema.Claim.startedAt] as? Date
                return .alreadyClaimed(byUnit: unit, since: since)
            }
            return .other(ckError.localizedDescription)
        }
    }
}
