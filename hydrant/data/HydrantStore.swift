//
//  HydrantStore.swift
//  hydrant
//
//  Created by Yeba Teo on 18/08/26.
//

import Foundation

// Loads and decodes the hydrant JSON bundled with the app.
enum HydrantStore {
    static func load() -> [Hydrant] {
        guard let url = Bundle.main.url(forResource: "data-lokasi-hidran-komponen-data", withExtension: "json") else {
            assertionFailure("Hydrant JSON was not found in the app bundle.")
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([Hydrant].self, from: data)
            // Assign a stable 1-based id by dataset position. This mirrors the
            // production serial that would be assigned once at import; every claim
            // and grid lookup keys off it.
            return decoded.enumerated().map { index, hydrant in
                var hydrant = hydrant
                hydrant.hidranID = index + 1
                return hydrant
            }
        } catch {
            assertionFailure("Hydrant JSON could not be decoded: \(error)")
            return []
        }
    }
}
