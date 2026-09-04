//
//  IncidentRepository.swift
//  hydrant
//
//  Reads and writes the shared incident list in the CloudKit public database.
//  This is the first slice that makes the demo multi-unit: an incident created on
//  one device appears on every other unit's device.
//

import CloudKit
import Foundation

@MainActor
final class IncidentRepository {
    private let database: CKDatabase

    init(database: CKDatabase? = nil) {
        self.database = database ?? CloudKitContainer.shared.publicDatabase
    }

    // Fetch every active incident, newest first. `wilayahID` optionally scopes the
    // result the way a unit's own region would; nil returns all active incidents.
    func fetchActive(wilayahID: Int? = nil) async throws -> [SharedIncident] {
        let predicate: NSPredicate
        if let wilayahID {
            predicate = NSPredicate(
                format: "%K == %@ AND %K == %d",
                CloudKitSchema.Incident.status, IncidentStatus.aktif.rawValue,
                CloudKitSchema.Incident.wilayahID, wilayahID
            )
        } else {
            predicate = NSPredicate(
                format: "%K == %@",
                CloudKitSchema.Incident.status, IncidentStatus.aktif.rawValue
            )
        }

        let query = CKQuery(recordType: CloudKitSchema.Incident.type, predicate: predicate)
        query.sortDescriptors = [
            NSSortDescriptor(key: CloudKitSchema.Incident.createdAt, ascending: false)
        ]

        let (matches, _) = try await database.records(matching: query)
        return matches.compactMap { _, result in
            guard case let .success(record) = result else { return nil }
            return SharedIncident(record: record)
        }
    }

    // Create or update an incident. Because the record id is derived from the
    // incident UUID, saving the same offline-created incident twice is idempotent.
    @discardableResult
    func save(_ incident: SharedIncident) async throws -> SharedIncident {
        let record = incident.makeRecord()
        let saved = try await database.save(record)
        return SharedIncident(record: saved) ?? incident
    }

    // Mark an incident finished. Server-side this frees any claims released by the
    // caller; the claim ledger is handled separately by HydrantClaimRepository.
    func markFinished(_ incident: SharedIncident) async throws {
        var updated = incident
        updated.status = .selesai
        _ = try await save(updated)
    }

    // Live updates: push a silent notification whenever any active incident changes
    // so every device can refresh its shared list. Registered once per install.
    func subscribeToActiveIncidents() async throws {
        let subscriptionID = "sub-insiden-aktif"
        let predicate = NSPredicate(
            format: "%K == %@",
            CloudKitSchema.Incident.status, IncidentStatus.aktif.rawValue
        )
        let subscription = CKQuerySubscription(
            recordType: CloudKitSchema.Incident.type,
            predicate: predicate,
            subscriptionID: subscriptionID,
            options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
        )
        let info = CKSubscription.NotificationInfo()
        info.shouldSendContentAvailable = true   // silent push; app refreshes in background
        subscription.notificationInfo = info

        do {
            _ = try await database.save(subscription)
        } catch let error as CKError where error.code == .serverRejectedRequest {
            // Subscription already exists — expected on every launch after the first.
        }
    }
}
