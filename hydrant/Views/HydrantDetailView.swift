//
//  HydrantDetailView.swift
//  hydrant
//
//  Created by Yeba Teo on 18/08/26.
//

import CoreLocation
import SwiftUI

// Sheet view that shows detailed information for one selected hydrant.
struct HydrantDetailView: View {
    let hydrant: Hydrant
    let userLocation: CLLocation?
    let openDirections: () -> Void

    private var distanceText: String? {
        guard let userLocation else { return nil }
        let distance = hydrant.location.distance(from: userLocation)
        return Measurement(value: distance, unit: UnitLength.meters)
            .formatted(.measurement(width: .abbreviated, usage: .road))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("Kondisi") {
                        Text(hydrant.kondisi.capitalized)
                            .foregroundStyle(hydrant.isUsable ? .green : .red)
                    }
                    if let distanceText {
                        LabeledContent("Jarak", value: distanceText)
                    }
                    LabeledContent("Wilayah", value: hydrant.wilayah.capitalized)
                    LabeledContent("Kecamatan", value: hydrant.kecamatan.capitalized)
                    LabeledContent("Kelurahan", value: hydrant.kelurahan.capitalized)
                }

                Section("Alamat") {
                    Text(hydrant.alamat.capitalized)
                }

                Section {
                    Button(action: openDirections) {
                        Label("Navigasi Apple Maps", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle(hydrant.title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

//#Preview(
//    HydrantDetailView()
//)

