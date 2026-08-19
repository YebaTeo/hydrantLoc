//
//  HydrantStatusFilter.swift
//  hydrant
//
//  Created by Yeba Teo on 18/08/26.
//

import Foundation

// Filter options shown in the segmented control above the map.
enum HydrantStatusFilter: String, CaseIterable, Identifiable {
    case all
    case usable
    case unusable

    // Uses the enum case itself as the SwiftUI identity.
    var id: Self { self }

    // User-facing label for each filter option.
    var title: String {
        switch self {
        case .all:
            "Semua"
        case .usable:
            "Siap"
        case .unusable:
            "Rusak"
        }
    }

    // Returns true when a hydrant should appear for the selected filter.
    func includes(_ hydrant: Hydrant) -> Bool {
        switch self {
        case .all:
            true
        case .usable:
            hydrant.isUsable
        case .unusable:
            !hydrant.isUsable
        }
    }
}
