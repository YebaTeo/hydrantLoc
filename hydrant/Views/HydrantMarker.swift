//
//  HydrantMarker.swift
//  hydrant
//
//  Created by Yeba Teo on 18/08/26.
//

import SwiftUI

// Map marker displaying the compressed hydrant pin asset.
struct HydrantMarker: View {
    let isUsable: Bool
    var isSelected = false
    var claimedByMine = false
    var claimedByOther = false
    var hasWarning = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image("HydrantMarkerPin")
                .resizable()
                .scaledToFit()
                .frame(width: markerSize, height: markerSize)
                .opacity(isUsable ? 1.0 : 0.45)
                .saturation(isUsable ? 1.0 : 0.3)

            statusBadge
                .offset(x: 5, y: -5)
        }
        .shadow(
            color: isSelected ? .blue.opacity(0.6) : .black.opacity(0.25),
            radius: isSelected ? 6 : 3,
            x: 0,
            y: 2
        )
        .scaleEffect(isSelected ? 1.2 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }

    @ViewBuilder
    private var statusBadge: some View {
        if hasWarning {
            badge(systemImage: "exclamationmark.triangle.fill", color: .orange)
        } else if claimedByMine {
            badge(systemImage: "checkmark.seal.fill", color: .blue)
        } else if claimedByOther {
            badge(systemImage: "person.fill.checkmark", color: .orange)
        } else if isSelected {
            badge(systemImage: "checkmark.circle.fill", color: .blue)
        }
    }

    private func badge(systemImage: String, color: Color) -> some View {
        Image(systemName: systemImage)
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 16, height: 16)
            .background(Circle().fill(color))
            .overlay(Circle().stroke(.white, lineWidth: 2))
    }

    private var markerSize: CGFloat {
        isSelected ? 40 : 32
    }
}
