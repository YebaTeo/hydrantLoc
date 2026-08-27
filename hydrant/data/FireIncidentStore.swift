//
//  FireIncidentStore.swift
//  hydrant
//
//  Created by Yeba Teo on 18/08/26.
//

import Foundation

enum FireIncidentStore {
    static func load() -> [FireIncident] {
        guard let url = Bundle.main.url(forResource: "dummy-data-kebakaran", withExtension: "json") else {
            assertionFailure("Fire incident JSON was not found in the app bundle.")
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([FireIncident].self, from: data)
        } catch {
            assertionFailure("Fire incident JSON could not be decoded: \(error)")
            return []
        }
    }
}
