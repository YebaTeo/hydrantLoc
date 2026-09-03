//
//  FireStationDetailPanel.swift
//  hydrant
//

import SwiftUI

// Bottom sheet content displayed when tapping any fire station (Pos Damkar) annotation on the map.
struct FireStationDetailPanel: View {
    var station: FireStation
    var onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            Divider()
            details
            actions
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(station.title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(station.isOperational ? "Pos Aktif" : "Perlu Pemeliharaan")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.green)
                }
            }

            Spacer()

            Button {
                onClose()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Tutup")
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 8) {
            detailRow(title: "Wilayah", value: station.wilayah.capitalized)
            detailRow(title: "Kecamatan", value: station.kecamatan.capitalized)
            detailRow(title: "Kelurahan", value: station.kelurahan.capitalized)
            detailRow(title: "Alamat", value: station.alamat.capitalized)
            if !station.vehicles.isEmpty {
                detailRow(title: "Unit Armada", value: station.vehicles.joined(separator: ", ").capitalized)
            }
            if let plat = station.platNomor, !plat.isEmpty {
                detailRow(title: "Plat Nomor", value: plat)
            }
            if let kategori = station.kategoriPos, !kategori.isEmpty {
                detailRow(title: "Kategori", value: kategori.capitalized)
            }
        }
    }

    private func detailRow(title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var actions: some View {
        Button {
            MapsNavigationService.openDirections(to: station)
        } label: {
            Label("Navigasi via Apple Maps", systemImage: "map.fill")
                .font(.subheadline.weight(.bold))
                .frame(maxWidth: .infinity)
                .frame(height: 40)
        }
        .buttonStyle(.borderedProminent)
        .tint(.orange)
        .buttonBorderShape(.roundedRectangle(radius: 12))
        .padding(.top, 4)
    }
}
