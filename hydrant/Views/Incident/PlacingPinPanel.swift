//
//  PlacingPinPanel.swift
//  hydrant
//

import CoreLocation
import MapKit
import SwiftUI

// Controller content while the fixed center pin is aimed at the incident.
// Address search only recenters the map; the final confirm always uses the pin.
struct PlacingPinPanel: View {
    var mapCenter: CLLocationCoordinate2D?
    var onSelectSearchResult: (CLLocationCoordinate2D) -> Void
    var onConfirm: () -> Void
    var onCancel: () -> Void

    @State private var searchService = IncidentSearchService()
    @State private var errorMessage: String?
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            searchField
            searchContent
            coordinateBadge
            actions
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .alert(
            "Unable to Find Location",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "Try another address or drag the map to aim the pin.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.headline)
                    .foregroundStyle(.red)
                Text("Tentukan Lokasi Kebakaran")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }

            Text("Geser peta untuk mengarahkan pin ke lokasi kebakaran, lalu konfirmasi.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            TextField("Cari atau masukkan alamat...", text: $searchService.query)
                .font(.subheadline)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .focused($isSearchFocused)

            if !searchService.query.isEmpty {
                Button {
                    searchService.query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }

            if searchService.isSearching {
                ProgressView().controlSize(.small)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    @ViewBuilder
    private var searchContent: some View {
        if searchService.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            EmptyView()
        } else if searchService.completions.isEmpty && !searchService.isSearching {
            Text("Tidak ada saran lokasi.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.vertical, 4)
        } else {
            VStack(spacing: 0) {
                ForEach(searchService.completions.prefix(4), id: \.self) { completion in
                    Button {
                        resolve(completion)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(completion.title)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            if !completion.subtitle.isEmpty {
                                Text(completion.subtitle)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if completion != searchService.completions.prefix(4).last {
                        Divider()
                    }
                }
            }
            .padding(.horizontal, 8)
            .background(.thinMaterial.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private var coordinateBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "scope")
                .font(.caption)
                .foregroundStyle(.red)

            Text("Pusat Peta:")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            if let mapCenter {
                Text("\(mapCenter.latitude, format: .number.precision(.fractionLength(5))), \(mapCenter.longitude, format: .number.precision(.fractionLength(5)))")
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.primary)
            } else {
                Text("Menentukan titik…")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.thinMaterial, in: Capsule())
    }

    private var actions: some View {
        HStack(spacing: 12) {
            Button(role: .cancel) {
                onCancel()
            } label: {
                Text("Batal")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.roundedRectangle(radius: 10))

            Button {
                onConfirm()
            } label: {
                Text("Konfirmasi Lokasi")
                    .font(.subheadline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .buttonBorderShape(.roundedRectangle(radius: 10))
            .disabled(mapCenter == nil)
        }
        .padding(.top, 2)
    }

    private func resolve(_ completion: MKLocalSearchCompletion) {
        isSearchFocused = false
        Task {
            do {
                let coordinate = try await searchService.resolve(completion)
                searchService.query = ""
                onSelectSearchResult(coordinate)
            } catch {
                errorMessage = "Coba alamat lain atau geser peta untuk mengarahkan pin."
            }
        }
    }
}
