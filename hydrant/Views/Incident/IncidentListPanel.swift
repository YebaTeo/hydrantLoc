//
//  IncidentListPanel.swift
//  hydrant
//

import SwiftUI

// Default controller content: the list of incident reports plus the add button.
struct IncidentListPanel: View {
    var incidents: [Incident]
    var canAddIncident: Bool
    var onAddIncident: () -> Void
    var onSelectIncident: (Incident) -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if incidents.isEmpty {
                emptyState
            } else {
                list
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Laporan Insiden")
                    .font(.headline)
                Text("\(incidents.count) laporan aktif")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if canAddIncident {
                Button {
                    onAddIncident()
                } label: {
                    Label("Tambah", systemImage: "plus")
                        .labelStyle(.iconOnly)
                        .font(.title2.weight(.semibold))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.circle)
                .tint(.red)
                .accessibilityLabel("Tambah laporan insiden")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "flame")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.red)
                Text("Belum Ada Laporan Kebakaran")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            Text(canAddIncident ? "Ketuk tombol + untuk menambahkan laporan baru." : "Belum ada laporan aktif untuk dipantau.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(incidents) { incident in
                    Button {
                        onSelectIncident(incident)
                    } label: {
                        row(for: incident)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())

                    if incident.id != incidents.last?.id {
                        Divider().padding(.leading, 52)
                    }
                }
            }
        }
    }

    private func row(for incident: Incident) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "flame.fill")
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(Circle().fill(.red))

            VStack(alignment: .leading, spacing: 4) {
                Text(incident.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                // Single Text (two HStacked Labels mislayout inside this sheet row).
                Text("\(incident.createdAtText)  •  \(incident.coordinateText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
