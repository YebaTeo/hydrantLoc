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
                // Home list view: show statistics and status filter bar
                if isPlacingPin {
                    placingHint
                }
                statusBar
                filterBar
                HStack {
                    Spacer()
                    floatingControlStack
                }
            } else {
                // Active workflow view: clean top toolbar with back button & floating controls
                HStack(alignment: .top) {
                    backButton
                    Spacer()
                    if isPlacingPin {
                        placingHint
                    }
                    Spacer()
                    floatingControlStack
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var backButton: some View {
        Button {
            handleBackAction()
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.primary)
                .frame(width: 44, height: 44)
                .background(.regularMaterial, in: Circle())
                .shadow(color: .black.opacity(0.12), radius: 4, y: 1)
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
        case .authorizing:
            flowVM.authorizationDidCancel()
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

    // Total, usable, and unusable hydrant counts.
    private var statusBar: some View {
        HStack {
            MetricView(value: mapViewModel.hydrants.count.formatted(), label: "Total")
            Spacer()
            MetricView(value: mapViewModel.usableCount.formatted(), label: "Siap")
            Spacer()
            MetricView(value: mapViewModel.unusableCount.formatted(), label: "Rusak")
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    // Switches between all, usable, and unusable hydrants.
    private var filterBar: some View {
        Picker("Kondisi", selection: $mapViewModel.statusFilter) {
            ForEach(HydrantStatusFilter.allCases) { filter in
                Text(filter.title).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .padding(8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

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
