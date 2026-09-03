//
//  IncidentListPanel.swift
//  hydrant
//

import SwiftUI

// Default controller content: the list of incident reports plus the add button.
struct IncidentListPanel: View {
    var incidents: [Incident]
    var canAddIncident: Bool
    var isExpanded: Bool
    var onAddIncident: () -> Void
    var onSelectIncident: (Incident) -> Void

    var body: some View {
        VStack(spacing: 0) {
            header

            if isExpanded {
                Divider()
                if incidents.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Button {
                    onAddIncident()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.85))

                        Text("Cari lokasi kebakaran")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.9))
                            .lineLimit(1)

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 18)
                    .frame(height: 58)
                    .background(Color.black.opacity(0.72), in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(!canAddIncident)
                .accessibilityLabel("Cari lokasi kebakaran untuk laporan baru")

                Button {
                    onAddIncident()
                } label: {
                    Image(systemName: "plus")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)
                        .frame(width: 58, height: 58)
                        .background(.regularMaterial, in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(!canAddIncident)
                .accessibilityLabel("Tambah laporan insiden")
            }

            if isExpanded {
                Text("\(incidents.count) laporan aktif")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 4)
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
            Text(canAddIncident ? "Ketuk kolom pencarian untuk menambahkan laporan baru." : "Belum ada laporan aktif untuk dipantau.")
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
