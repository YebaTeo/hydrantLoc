//
//  CloudKitContainer.swift
//  hydrant
//

import CloudKit
import Foundation

// Whether CloudKit is usable right now. CloudKit is disabled for the current demo,
// so callers should run local-only and avoid touching the container.
enum CloudKitAvailability: Equatable {
    case available
    case noAccount
    case restricted
    case temporarilyUnavailable
    case unknown(String)

    var isAvailable: Bool { self == .available }
}

final class CloudKitContainer: @unchecked Sendable {
    static let shared = CloudKitContainer()

    var publicDatabase: CKDatabase {
        CKContainer(identifier: CloudKitSchema.containerIdentifier).publicCloudDatabase
    }

    private init() {}

    func availability(timeout: Duration = .seconds(2)) async -> CloudKitAvailability {
        .temporarilyUnavailable
    }
}
