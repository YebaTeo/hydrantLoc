//
//  NearbyHydrantsPanel.swift
//  hydrant
//

import SwiftUI

// Controller content for an opened incident: ranked hydrant recommendations
// presented in a compact carousel card with left/right navigation,
// expandable on swipe up for full details.
struct NearbyHydrantsPanel: View {

    var mapViewModel: HydrantMapViewModel
    var incident: Incident

    // Hidran yang sedang dipilih atau memiliki rute aktif.
    var selectedHydrant: Hydrant?

    var isExpanded: Bool
    var canRemoveIncident: Bool
    var onSelectHydrant: (Hydrant) -> Void
    var onClose: () -> Void
    var onRemoveIncident: () -> Void

    @State private var currentIndex = 0

    private var recommendations: [HydrantRecommendation] {
        mapViewModel.displayedRecommendations
    }

    private var currentRecommendation: HydrantRecommendation? {
        guard !recommendations.isEmpty,
              recommendations.indices.contains(currentIndex)
        else {
            return nil
        }

        return recommendations[currentIndex]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if mapViewModel.isLoadingRecommendations {
                loadingView
            } else if recommendations.isEmpty {
                emptyView
            } else if let rec = currentRecommendation {
                carouselHeader
                compactCard(for: rec)

                if isExpanded {
                    expandedDetails(for: rec)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            synchronizeWithSelectedHydrant()
        }
        .onChange(of: selectedHydrant?.id) { _, _ in
            synchronizeWithSelectedHydrant()
        }
        .onChange(of: recommendations.map(\.id)) { _, _ in
            synchronizeWithSelectedHydrant()
        }
    }

    private var loadingView: some View {
        HStack(spacing: 12) {
            ProgressView()

            Text("Mencari hidran terdekat...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var emptyView: some View {
        VStack(spacing: 6) {
            Image(systemName: "drop.triangle")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("Hidran Tidak Ditemukan")
                .font(.subheadline.weight(.semibold))

            Text("Tidak ada hidran siap pakai di dekat lokasi ini.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
    }

    private var carouselHeader: some View {
        HStack {
            Button {
                navigateCarousel(delta: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
                    .opacity(currentIndex > 0 ? 1.0 : 0.35)
                    .frame(width: 32, height: 32)
                    .background(.thinMaterial, in: Circle())
            }
            .disabled(currentIndex <= 0)
            .buttonStyle(.plain)
            .accessibilityLabel("Rekomendasi sebelumnya")

            Spacer()

            HStack(spacing: 8) {
                Text("\(currentIndex + 1)/\(recommendations.count)")
                    .font(.subheadline.weight(.bold).monospacedDigit())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.blue, in: Capsule())

                Text(incident.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
            }

            Spacer()

            Button {
                navigateCarousel(delta: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
                    .opacity(
                        currentIndex < recommendations.count - 1
                            ? 1.0
                            : 0.35
                    )
                    .frame(width: 32, height: 32)
                    .background(.thinMaterial, in: Circle())
            }
            .disabled(currentIndex >= recommendations.count - 1)
            .buttonStyle(.plain)
            .accessibilityLabel("Rekomendasi berikutnya")
        }
    }

    private func compactCard(
        for rec: HydrantRecommendation
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(rec.hydrant.title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    HStack(spacing: 6) {
                        Label(
                            "Siap digunakan",
                            systemImage: "checkmark.circle.fill"
                        )
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)

                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.tertiary)

                        Text(
                            "\(DistanceFormatting.distance(rec.incidentDistance)) dari insiden"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "drop.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
            }

            if let drivingDistance = rec.drivingDistance,
               let expectedTravelTime = rec.expectedTravelTime {
                HStack(spacing: 12) {
                    Label(
                        DistanceFormatting.distance(drivingDistance),
                        systemImage: "car.fill"
                    )
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                    Label(
                        DistanceFormatting.travelTime(expectedTravelTime),
                        systemImage: "clock.fill"
                    )
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    .thinMaterial,
                    in: RoundedRectangle(
                        cornerRadius: 8,
                        style: .continuous
                    )
                )
            }
        }
    }

    private func expandedDetails(
        for rec: HydrantRecommendation
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Divider()
                .padding(.vertical, 4)

            Text("Detail Hidran")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                detailRow(
                    title: "Wilayah",
                    value: rec.hydrant.wilayah.capitalized
                )

                detailRow(
                    title: "Kecamatan",
                    value: rec.hydrant.kecamatan.capitalized
                )

                detailRow(
                    title: "Kelurahan",
                    value: rec.hydrant.kelurahan.capitalized
                )

                detailRow(
                    title: "Alamat",
                    value: rec.hydrant.alamat.capitalized
                )
            }

            VStack(spacing: 10) {
                Button {
                    MapsNavigationService.openDirections(
                        to: rec.hydrant
                    )
                } label: {
                    Label(
                        "Navigasi via Apple Maps",
                        systemImage: "map.fill"
                    )
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.roundedRectangle(radius: 10))

                if canRemoveIncident {
                    Button(role: .destructive) {
                        onRemoveIncident()
                    } label: {
                        Label("Hapus Laporan Kebakaran", systemImage: "flame.slash")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .buttonBorderShape(.roundedRectangle(radius: 10))
                }
            }
            .padding(.top, 4)
        }
    }

    private func detailRow(
        title: String,
        value: String
    ) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .leading)

            Text(value)
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)
        }
    }

    private func navigateCarousel(delta: Int) {
        let newIndex = currentIndex + delta

        guard recommendations.indices.contains(newIndex) else {
            return
        }

        withAnimation(.easeInOut(duration: 0.25)) {
            currentIndex = newIndex
        }

        let selectedRecommendation = recommendations[newIndex]

        mapViewModel.panCamera(
            to: selectedRecommendation.hydrant.location
        )

        onSelectHydrant(selectedRecommendation.hydrant)
    }

    // Menyamakan posisi carousel dengan hidran yang dipilih dari peta.
    private func synchronizeWithSelectedHydrant() {
        guard let selectedHydrant,
              let selectedIndex = recommendations.firstIndex(
                where: {
                    $0.hydrant.id == selectedHydrant.id
                }
              ),
              currentIndex != selectedIndex
        else {
            return
        }

        withAnimation(.easeInOut(duration: 0.25)) {
            currentIndex = selectedIndex
        }
    }
}
