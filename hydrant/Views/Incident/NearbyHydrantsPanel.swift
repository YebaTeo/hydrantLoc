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
    var claimVM: HydrantClaimViewModel
    var reportVM: ConditionReportViewModel
    var incident: Incident

    // Hidran yang sedang dipilih atau memiliki rute aktif.
    var selectedHydrant: Hydrant?

    var isExpanded: Bool
    var canRemoveIncident: Bool
    var onSelectHydrant: (Hydrant) -> Void
    var onClose: () -> Void
    var onRemoveIncident: () -> Void
    var onReportCondition: (Hydrant) -> Void

    @State private var currentIndex = 0
    @State private var isClaimInFlight = false

    private var recommendations: [HydrantRecommendation] {
        mapViewModel.displayedRecommendations
    }

    private var fireStationRecommendations: [FireStationRecommendation] {
        mapViewModel.fireStationRecommendations
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
                } else if selectedHydrant?.id == rec.hydrant.id {
                    compactHydrantDetails(for: rec)
                }
            }

            if !fireStationRecommendations.isEmpty {
                fireStationSection
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
//            Button {
//                navigateCarousel(delta: -1)
//            } label: {
//                Image(systemName: "chevron.left")
//                    .font(.subheadline.weight(.bold))
//                    .foregroundStyle(.primary)
//                    .opacity(currentIndex > 0 ? 1.0 : 0.35)
//                    .frame(width: 32, height: 32)
//                    .background(.thinMaterial, in: Circle())
//            }
//            .disabled(currentIndex <= 0)
//            .buttonStyle(.plain)
//            .accessibilityLabel("Rekomendasi sebelumnya")
//
//            Spacer()

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

//            Button {
//                navigateCarousel(delta: 1)
//            } label: {
//                Image(systemName: "chevron.right")
//                    .font(.subheadline.weight(.bold))
//                    .foregroundStyle(.primary)
//                    .opacity(
//                        currentIndex < recommendations.count - 1
//                            ? 1.0
//                            : 0.35
//                    )
//                    .frame(width: 32, height: 32)
//                    .background(.thinMaterial, in: Circle())
//            }
//            .disabled(currentIndex >= recommendations.count - 1)
//            .buttonStyle(.plain)
//            .accessibilityLabel("Rekomendasi berikutnya")
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

            claimBadge(for: rec.hydrant)
            conditionBadge(for: rec.hydrant)

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

    private func compactHydrantDetails(
        for rec: HydrantRecommendation
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            detailRow(title: "Wilayah", value: rec.hydrant.wilayah.capitalized)
            detailRow(title: "Kecamatan", value: rec.hydrant.kecamatan.capitalized)
            detailRow(title: "Kelurahan", value: rec.hydrant.kelurahan.capitalized)
            detailRow(title: "Alamat", value: rec.hydrant.alamat.capitalized)
        }
        .padding(.top, 4)
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
                claimButton(for: rec.hydrant)

                Button {
                    onReportCondition(rec.hydrant)
                } label: {
                    Label("Laporkan Kondisi", systemImage: "exclamationmark.bubble.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                }
                .buttonStyle(.bordered)
                .tint(.orange)
                .buttonBorderShape(.roundedRectangle(radius: 10))

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

    // Nearest fire stations (Pos Damkar) to the incident, shown alongside the
    // hydrant recommendations so an officer can also dispatch a nearby post.
    private var fireStationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()
                .padding(.vertical, 2)

            Label("Pos Damkar Terdekat", systemImage: "building.2.fill")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.secondary)

            ForEach(fireStationRecommendations) { recommendation in
                fireStationRow(for: recommendation)
            }
        }
        .padding(.top, 4)
    }

    private func fireStationRow(
        for recommendation: FireStationRecommendation
    ) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "flame.circle.fill")
                .font(.title2)
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text(recommendation.station.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text("\(DistanceFormatting.distance(recommendation.incidentDistance)) dari insiden")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Button {
                MapsNavigationService.openDirections(to: recommendation.station)
            } label: {
                Image(systemName: "location.fill")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(.orange, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Navigasi ke \(recommendation.station.title)")
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            .thinMaterial,
            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
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

    // A hydrant held by another unit is never hidden — it is labelled, so the
    // officer can decide (some hydrants can be shared). Shows nothing when free.
    @ViewBuilder
    private func claimBadge(for hydrant: Hydrant) -> some View {
        if let claim = claimVM.claim(for: hydrant), claim.unitKode != claimVM.myUnit {
            Label(
                "Dipakai \(claim.unitKode) sejak \(claim.startedAt.formatted(date: .omitted, time: .shortened))",
                systemImage: "person.fill.checkmark"
            )
            .font(.caption.weight(.semibold))
            .foregroundStyle(.orange)
        } else if claimVM.isMine(hydrant) {
            Label("Dipakai unit Anda", systemImage: "checkmark.seal.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.blue)
        }
    }

    // An active field report on this hydrant, shown to every unit at once. A
    // problem shows amber; a "berfungsi" recovery report shows green.
    @ViewBuilder
    private func conditionBadge(for hydrant: Hydrant) -> some View {
        if let report = reportVM.latestReport(for: hydrant) {
            Label(
                "\(report.condition.title) · \(report.reportedByUnit) · \(report.time.formatted(date: .omitted, time: .shortened))",
                systemImage: report.condition.systemImage
            )
            .font(.caption.weight(.semibold))
            .foregroundStyle(report.condition.isProblem ? .orange : .green)
        }
    }

    // Claim / release the currently shown hydrant. Only rendered when the shared
    // layer is live; offline the app has no claims to coordinate.
    @ViewBuilder
    private func claimButton(for hydrant: Hydrant) -> some View {
        if claimVM.cloudAvailable {
            if claimVM.isMine(hydrant) {
                Button(role: .destructive) {
                    runClaimAction { await claimVM.release(hydrant) }
                } label: {
                    claimButtonLabel("Lepas Hidran", systemImage: "hand.raised.slash.fill")
                }
                .buttonStyle(.bordered)
                .tint(.blue)
                .buttonBorderShape(.roundedRectangle(radius: 10))
                .disabled(isClaimInFlight)
            } else {
                Button {
                    runClaimAction { await claimVM.claim(hydrant, incidentID: incident.id) }
                } label: {
                    claimButtonLabel("Pakai Hidran Ini", systemImage: "hand.raised.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .buttonBorderShape(.roundedRectangle(radius: 10))
                .disabled(isClaimInFlight)
            }
        }
    }

    private func claimButtonLabel(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.subheadline.weight(.bold))
            .frame(maxWidth: .infinity)
            .frame(height: 38)
    }

    private func runClaimAction(_ action: @escaping () async -> Void) {
        isClaimInFlight = true
        Task {
            await action()
            isClaimInFlight = false
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
