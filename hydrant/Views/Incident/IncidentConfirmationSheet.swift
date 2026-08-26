//
//  IncidentConfirmationSheet.swift
//  hydrant
//
//  Created by Yeba Teo on 26/08/26.
//

import CoreLocation
import SwiftUI

struct IncidentConfirmationSheet: View {
    let coordinate: CLLocationCoordinate2D
    let onConfirm: () -> Void
    let onChangeLocation: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Incident Confirmation")
                    .font(.headline)
                Text("Confirm this fire incident location before hydrant recommendations are calculated.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 8) {
                Label("Pending Incident", systemImage: "flame.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.red)
                Text("Latitude: \(coordinate.latitude, format: .number.precision(.fractionLength(5)))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Text("Longitude: \(coordinate.longitude, format: .number.precision(.fractionLength(5)))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                Button {
                    onConfirm()
                } label: {
                    Text("Confirm Incident")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    onChangeLocation()
                } label: {
                    Label("Change Location", systemImage: "mappin.and.ellipse")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button(role: .cancel) {
                    onCancel()
                } label: {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal)
        .padding(.top, 24)
        .padding(.bottom)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    IncidentConfirmationSheet(
        coordinate: CLLocationCoordinate2D(latitude: -6.2088, longitude: 106.8456),
        onConfirm: {},
        onChangeLocation: {},
        onCancel: {}
    )
}
