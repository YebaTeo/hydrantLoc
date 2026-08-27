//
//  FireListSheet.swift
//  hydrant
//
//  Created by Yeba Teo on 18/08/26.
//

import SwiftUI

struct FireListSheet: View {
    let incidents: [FireIncident]
    @Binding var mapMode: MapMode
    @Binding var showMapModeSheet: Bool
    let onSelect: (FireIncident) -> Void

    var body: some View {
        List {
            Section {
                ForEach(incidents) { incident in
                    Button {
                        onSelect(incident)
                    } label: {
                        FireIncidentRow(incident: incident)
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Kejadian Kebakaran")
                    .font(.headline)
                    .textCase(nil)
                    .foregroundStyle(.primary)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .sheet(isPresented: $showMapModeSheet) {
            MapModeSheet(selection: $mapMode)
                .presentationDetents([.height(300)])
                .presentationDragIndicator(.visible)
        }
    }
}

private struct FireIncidentRow: View {
    let incident: FireIncident

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "flame.fill")
                .font(.title3)
                .foregroundStyle(.orange)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(incident.title)
                    .font(.headline)
                Text(incident.alamat)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}
