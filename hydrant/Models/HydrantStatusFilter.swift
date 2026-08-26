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

    var id: Self { self }

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
