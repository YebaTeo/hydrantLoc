//
//  HydrantMarker.swift
//  hydrant
//
//  Created by Yeba Teo on 18/08/26.
//

import SwiftUI

// Map marker tinted green when usable and red when unusable. A small corner badge
// signals an active claim: blue when this unit holds it, orange when another unit
// does — so a claimed hydrant is visible on the map without opening its detail.
struct HydrantMarker: View {
    let isUsable: Bool
    var isSelected = false
    var claimedByMine = false
    var claimedByOther = false
    var hasWarning = false

    var body: some View {
        ZStack {
            Circle()
                .fill(markerColor)
                .frame(width: markerSize, height: markerSize)
            Circle()
                .stroke(.white, lineWidth: isSelected ? 4 : 3)
                .frame(width: markerSize, height: markerSize)
            Image(systemName: "drop.fill")
                .font(.system(size: isSelected ? 12 : 9, weight: .bold))
                .foregroundStyle(.white)
        }
        .overlay(alignment: .topTrailing) { claimBadge }
        .overlay(alignment: .topLeading) { warningBadge }
        .shadow(radius: isSelected ? 5 : 2, y: 1)
        .scaleEffect(isSelected ? 1.2 : 1)
    }

    @ViewBuilder
    private var warningBadge: some View {
        if hasWarning {
            Image(systemName: "exclamationmark")
                .font(.system(size: 7, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 12, height: 12)
                .background(Circle().fill(Color.yellow))
                .overlay(Circle().stroke(.white, lineWidth: 1.5))
                .offset(x: -3, y: -3)
        }
    }

    @ViewBuilder
    private var claimBadge: some View {
        if claimedByMine || claimedByOther {
            Image(systemName: claimedByMine ? "checkmark" : "hand.raised.fill")
                .font(.system(size: 7, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 12, height: 12)
                .background(Circle().fill(claimedByMine ? Color.blue : Color.orange))
                .overlay(Circle().stroke(.white, lineWidth: 1.5))
                .offset(x: 3, y: -3)
        }
    }

    private var markerColor: Color {
        if isSelected {
            return .blue
        }
        return isUsable ? .green : .red
    }

    private var markerSize: CGFloat {
        isSelected ? 26 : 20
    }
}
