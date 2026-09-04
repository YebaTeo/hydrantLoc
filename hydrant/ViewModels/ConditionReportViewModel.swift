//
//  ConditionReportViewModel.swift
//  hydrant
//
//  Drives the "Laporkan Kondisi" flow and exposes the latest active condition per
//  hydrant so the map and detail panels can warn every unit in real time.
//

import Foundation
import Observation

@Observable
@MainActor
final class ConditionReportViewModel {
    // The most recent active report per hydrant, keyed by hidranID. One entry is
    // enough to drive the warning UI; the full history lives in CloudKit.
    private(set) var latestByHydrant: [Int: HydrantConditionReport] = [:]
    private(set) var cloudAvailable = false
    var submitError: String?

    let myUnit = DeviceIdentity.unitKode
    private let repository: ConditionReportRepository

    init(repository: ConditionReportRepository? = nil) {
        self.repository = repository ?? ConditionReportRepository()
    }

    // MARK: - Lifecycle

    func start() async {
        cloudAvailable = await CloudKitContainer.shared.availability().isAvailable
        guard cloudAvailable else { return }
        try? await repository.subscribeToReports()
        await refresh()
    }

    func refresh() async {
        guard cloudAvailable, let reports = try? await repository.fetchActive() else { return }
        // Reports arrive newest-first; keep the first seen per hydrant.
        var latest: [Int: HydrantConditionReport] = [:]
        for report in reports where latest[report.hidranID] == nil {
            latest[report.hidranID] = report
        }
        latestByHydrant = latest
    }

    // MARK: - Actions

    // File a report. Updates the local map immediately (optimistic) and, when
    // offline, still records it locally so the officer's screen reflects the call —
    // the CloudKit save is best-effort and idempotent on retry.
    func submit(
        hydrant: Hydrant,
        level: ConditionLevel,
        condition: HydrantCondition,
        note: String?,
        incidentID: UUID?
    ) async {
        let report = HydrantConditionReport(
            hidranID: hydrant.hidranID,
            incidentID: incidentID,
            reportedByUnit: myUnit,
            level: level,
            condition: condition,
            note: note
        )
        latestByHydrant[hydrant.hidranID] = report   // optimistic, shows at once

        guard cloudAvailable else { return }
        do {
            try await repository.submit(report)
        } catch {
            submitError = "Laporan tersimpan lokal tapi gagal terkirim. Akan dicoba lagi saat online."
        }
    }

    // MARK: - Queries for the UI

    func latestReport(for hydrant: Hydrant) -> HydrantConditionReport? {
        guard let report = latestByHydrant[hydrant.hidranID], report.isActive() else { return nil }
        return report
    }

    // A hydrant carrying an active problem report (anything but "berfungsi").
    func hasWarning(for hydrant: Hydrant) -> Bool {
        latestReport(for: hydrant)?.condition.isProblem ?? false
    }
}
