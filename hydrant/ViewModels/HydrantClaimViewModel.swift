//
//  HydrantClaimViewModel.swift
//  hydrant
//
//  Drives the "Pakai hidran ini" flow: which hydrants are currently held, by whom,
//  and the claim/release actions. Sits on top of the atomic HydrantClaimRepository,
//  so a lost race surfaces as a clear message rather than a silent overwrite.
//

import Foundation
import Observation

@Observable
@MainActor
final class HydrantClaimViewModel {
    // Active claims keyed by hidranID. The read-time TTL is applied by the
    // repository, so anything here is a live hold.
    private(set) var activeClaims: [Int: HydrantClaim] = [:]
    private(set) var cloudAvailable = false

    // Set when a claim attempt loses the race; ContentView shows it as an alert.
    var conflictMessage: String?

    // This device's unit, from onboarding. Attribution without a login.
    let myUnit = DeviceIdentity.unitKode

    private let repository: HydrantClaimRepository

    init(repository: HydrantClaimRepository? = nil) {
        self.repository = repository ?? HydrantClaimRepository()
    }

    // MARK: - Lifecycle

    func start() async {
        cloudAvailable = false
        activeClaims = [:]
    }

    func refresh() async {
        cloudAvailable = false
        activeClaims = [:]
    }

    // MARK: - Actions

    // Claim a hydrant for an incident. On success the local map reflects it
    // immediately; on conflict we surface who won and resync to show their hold.
    func claim(_ hydrant: Hydrant, incidentID: UUID) async {
        guard cloudAvailable else {
            conflictMessage = "Klaim tidak terkirim: iCloud/koneksi tidak tersedia."
            return
        }
        do {
            let claim = try await repository.claim(
                hidranID: hydrant.hidranID,
                incidentID: incidentID,
                unitKode: myUnit
            )
            activeClaims[hydrant.hidranID] = claim
        } catch let error as ClaimError {
            present(error, hydrant: hydrant)
            await refresh()   // reveal the winner's claim on the map
        } catch {
            conflictMessage = error.localizedDescription
        }
    }

    // Release a hydrant this unit holds (normal end-of-use).
    func release(_ hydrant: Hydrant) async {
        guard cloudAvailable else { return }
        try? await repository.release(hidranID: hydrant.hidranID)
        activeClaims[hydrant.hidranID] = nil
    }

    // Free every hydrant this unit holds for a finished incident (end report).
    func releaseAll(forIncident incidentID: UUID) async {
        guard cloudAvailable else { return }
        let mine = activeClaims.values.filter {
            $0.incidentID == incidentID && $0.unitKode == myUnit
        }
        for claim in mine {
            try? await repository.release(hidranID: claim.hidranID)
            activeClaims[claim.hidranID] = nil
        }
    }

    // MARK: - Queries for the UI

    func claim(for hydrant: Hydrant) -> HydrantClaim? {
        guard let claim = activeClaims[hydrant.hidranID], claim.isActive() else { return nil }
        return claim
    }

    func isMine(_ hydrant: Hydrant) -> Bool {
        claim(for: hydrant)?.unitKode == myUnit
    }

    func isClaimedByOther(_ hydrant: Hydrant) -> Bool {
        guard let claim = claim(for: hydrant) else { return false }
        return claim.unitKode != myUnit
    }

    // MARK: - Helpers

    private func present(_ error: ClaimError, hydrant: Hydrant) {
        switch error {
        case let .alreadyClaimed(unit, since):
            let who = unit ?? "unit lain"
            let when = since.map { " sejak \($0.formatted(date: .omitted, time: .shortened))" } ?? ""
            conflictMessage = "Hidran \(hydrant.title) sedang dipakai \(who)\(when)."
        case .unavailable:
            conflictMessage = "Klaim tidak terkirim: iCloud/koneksi tidak tersedia. Coba lagi saat online."
        case let .other(message):
            conflictMessage = message
        }
    }
}
