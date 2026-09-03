//
//  FireStationStore.swift
//  hydrant
//

import Foundation

// Loads and decodes the fire station (Pos Damkar) JSON bundled with the app.
enum FireStationStore {
    static func load() -> [FireStation] {
        guard let url = Bundle.main.url(forResource: "data-lokasi-pos-damkar", withExtension: "json") else {
            assertionFailure("Fire station JSON was not found in the app bundle.")
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([FireStation].self, from: data)
        } catch {
            assertionFailure("Fire station JSON could not be decoded: \(error)")
            return []
        }
    }
}
