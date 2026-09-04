//
//  ConditionReportRepository.swift
//  hydrant
//
//  Append-only writes and reads of field condition reports in the CloudKit public
//  database. Reports show to every unit the moment they sync; a `sesaat` report is
//  filtered out once past its 24h expiry (read-time TTL, no server sweep).
//

import CloudKit
import Foundation

@MainActor
final class ConditionReportRepository {
    private let database: CKDatabase

    init(database: CKDatabase? = nil) {
        self.database = database ?? CloudKitContainer.shared.publicDatabase
    }

    // File a report. Append-only and idempotent (record id derives from the report
    // UUID), so a background retry or offline replay never duplicates it.
    @discardableResult
    func submit(_ report: HydrantConditionReport) async throws -> HydrantConditionReport {
        let saved = try await database.save(report.makeRecord())
        return HydrantConditionReport(record: saved) ?? report
    }

    // Every currently-active report, newest first. Expired `sesaat` reports are
    // dropped here so callers only ever see live conditions.
    func fetchActive() async throws -> [HydrantConditionReport] {
        let query = CKQuery(
            recordType: CloudKitSchema.ConditionReport.type,
            predicate: NSPredicate(value: true)
        )
        query.sortDescriptors = [
            NSSortDescriptor(key: CloudKitSchema.ConditionReport.time, ascending: false)
        ]
        let (matches, _) = try await database.records(matching: query)
        let now = Date.now
        return matches.compactMap { _, result -> HydrantConditionReport? in
            guard case let .success(record) = result,
                  let report = HydrantConditionReport(record: record),
                  report.isActive(now: now)
            else { return nil }
            return report
        }
    }

    func subscribeToReports() async throws {
        let subscriptionID = "sub-laporan-kondisi"
        let subscription = CKQuerySubscription(
            recordType: CloudKitSchema.ConditionReport.type,
            predicate: NSPredicate(value: true),
            subscriptionID: subscriptionID,
            options: [.firesOnRecordCreation]
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
}
