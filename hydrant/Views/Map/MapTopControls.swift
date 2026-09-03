//
//  MapTopControls.swift
//  hydrant
//

import MapKit
import SwiftUI

// Overlays pinned to the top of the map: hydrant statistics & condition filter (on home list),
// or clean top toolbar back button during active workflows.
struct MapTopControls: View {
    @Bindable var mapViewModel: HydrantMapViewModel
    var flowVM: IncidentFlowViewModel
    let mapScope: Namespace.ID
    var isPlacingPin: Bool
    var onOpenMapModes: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            if flowVM.showsAllIncidentMarkers {
                topBar(showsBackButton: false)

                HStack {
                    Spacer()
                    floatingControlStack
                }
            } else {
                topBar(showsBackButton: true)

                if isPlacingPin {
                    placingHint
                }

                if flowVM.isRouting,
                   let route = flowVM.route,
                   let hydrant = flowVM.routedHydrant {
                    routeSummary(route: route, hydrant: hydrant)
                }

                HStack {
                    Spacer()
                    floatingControlStack
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private func topBar(showsBackButton: Bool) -> some View {
        ZStack {
            Text("Hidran Jakarta")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)

            HStack {
                if showsBackButton {
                    backButton
                }

                Spacer()
            }
        }
        .frame(height: 44)
    }

    private var backButton: some View {
        Button {
            handleBackAction()
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.primary)
                .frame(width: 40, height: 40)
                .background(.regularMaterial, in: Circle())
                .shadow(color: .black.opacity(0.12), radius: 5, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Kembali")
    }

    private func handleBackAction() {
        switch flowVM.state {
        case .placingPin:
            flowVM.cancelPlacingPin()
        case .incidentDetail:
            flowVM.closeIncidentDetail()
        case .routing:
            flowVM.endRoute()
        case .list:
            break
        }
    }

    private var placingHint: some View {
        Label("Geser peta untuk mengarahkan pin", systemImage: "mappin.and.ellipse")
            .font(.subheadline.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.red, in: Capsule())
    }

    private func routeSummary(route: MKRoute, hydrant: Hydrant) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(DistanceFormatting.travelTime(route.expectedTravelTime))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.green)

                Text(DistanceFormatting.distance(route.distance))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                routePoint(icon: "location.fill", color: .blue, title: "Lokasi Anda")
                routePoint(icon: "drop.fill", color: .cyan, title: hydrant.title)
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.16), radius: 8, y: 3)
    }

    private func routePoint(icon: String, color: Color, title: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(color)
                .frame(width: 18)

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)

            Spacer(minLength: 0)
        }
    }

    // Total, usable, and unusable hydrant counts.
//    private var statusBar: some View {
//        HStack {
//            MetricView(value: mapViewModel.hydrants.count.formatted(), label: "Total")
//            Spacer()
//            MetricView(value: mapViewModel.usableCount.formatted(), label: "Siap")
//            Spacer()
//            MetricView(value: mapViewModel.unusableCount.formatted(), label: "Rusak")
//        }
//        .padding(12)
//        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
//    }

    // Switches between all, usable, and unusable hydrants.
//    private var filterBar: some View {
//        Picker("Kondisi", selection: $mapViewModel.statusFilter) {
//            ForEach(HydrantStatusFilter.allCases) { filter in
//                Text(filter.title).tag(filter)
//            }
//        }
//        .pickerStyle(.segmented)
//        .padding(8)
//        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
//    }

    private var floatingControlStack: some View {
        VStack(spacing: 0) {
            Button {
                onOpenMapModes()
            } label: {
                Image(systemName: "map.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Mode Peta")

            Divider()
                .frame(width: 28)

            MapUserLocationButton(scope: mapScope)
                .frame(width: 44, height: 44)
                .accessibilityLabel("Pusatkan lokasi saya")
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 6, y: 2)
    }
}
