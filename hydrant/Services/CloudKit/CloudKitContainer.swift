//
//  CloudKitContainer.swift
//  hydrant
//
//  Thin wrapper over the shared CKContainer and its public database, plus an
//  account-availability probe. Repositories depend on this rather than reaching
//  for CKContainer.default(), so the container id is defined in exactly one place.
//

import CloudKit
import Foundation

// Whether CloudKit is usable right now. The app is offline-first, so an
// unavailable account is a normal, non-fatal state — the UI degrades, it does
// not error out.
enum CloudKitAvailability: Equatable {
    case available
    case noAccount        // user not signed into iCloud on this device
    case restricted       // parental controls / MDM restriction
    case temporarilyUnavailable
    case unknown(String)

    var isAvailable: Bool { self == .available }
}

@MainActor
final class CloudKitContainer {
    static let shared = CloudKitContainer()

    let container: CKContainer
    var publicDatabase: CKDatabase { container.publicCloudDatabase }

    private init() {
        container = CKContainer(identifier: CloudKitSchema.containerIdentifier)
    }

    // Probe the iCloud account state. Call on launch to decide whether the
    // shared-data layer is live or the app should run purely on bundled data.
    func availability() async -> CloudKitAvailability {
        do {
            switch try await container.accountStatus() {
            case .available:
                return .available
            case .noAccount:
                return .noAccount
            case .restricted:
                return .restricted
            case .couldNotDetermine, .temporarilyUnavailable:
                return .temporarilyUnavailable
            @unknown default:
                return .unknown("unhandled account status")
            }
        } catch {
            return .unknown(error.localizedDescription)
        }
    }
}
