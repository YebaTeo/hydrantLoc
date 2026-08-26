//
//  HydrantMarker.swift
//  hydrant
//
//  Created by Yeba Teo on 18/08/26.
//

import SwiftUI

// Small map marker that changes color based on hydrant condition.
struct HydrantMarker: View {
    // Green means usable; red means unusable.
    let isUsable: Bool
    var isSelected = false

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
        .shadow(radius: isSelected ? 5 : 2, y: 1)
        .scaleEffect(isSelected ? 1.2 : 1)
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
