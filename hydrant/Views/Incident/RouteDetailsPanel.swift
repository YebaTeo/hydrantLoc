//
//  RouteDetailsPanel.swift
//  hydrant
//

import MapKit
import SwiftUI

// Controller content while a route is drawn: route metrics and the two exits
// (end the route, or end the whole incident). This is the persistent control the
// old flow lacked — it stays reachable no matter how the sheet is dragged.
struct RouteDetailsPanel: View {
    var mapViewModel: HydrantMapViewModel
    var hydrant: Hydrant
    var route: MKRoute
    var onEndRoute: () -> Void
    var onRemoveIncident: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text(hydrant.title)
                    .font(.headline)
                Label("Siap digunakan", systemImage: "circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.green)
            }

            HStack(alignment: .top, spacing: 24) {
                metric(
                    title: "Jarak dari Incident",
                    value: mapViewModel.formattedDistanceFromIncident(to: hydrant)
                )
                metric(
                    title: "Rute dari Lokasi Anda",
                    value: "\(DistanceFormatting.distance(route.distance)) • \(DistanceFormatting.travelTime(route.expectedTravelTime))"
                )
            }

            VStack(spacing: 12) {
                Button {
                    onEndRoute()
                } label: {
                    Label("Akhiri Rute", systemImage: "arrow.uturn.backward")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button(role: .destructive) {
                    onRemoveIncident()
                } label: {
                    Label("Hapus Laporan", systemImage: "flame.slash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func metric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
        }
    }
}
