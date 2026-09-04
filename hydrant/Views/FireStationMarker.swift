//
//  FireStationMarker.swift
//  hydrant
//

import SwiftUI

// Map marker displaying the compressed fire station (Pos Damkar) pin asset.
struct FireStationMarker: View {
    var isSelected = false

    var body: some View {
        Image("FireStationMarkerPin")
            .resizable()
            .scaledToFit()
            .frame(width: markerSize, height: markerSize)
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Circle()
                        .fill(.blue)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                        .offset(x: 2, y: -2)
                }
            }
            .shadow(
                color: isSelected ? .orange.opacity(0.6) : .black.opacity(0.25),
                radius: isSelected ? 6 : 3,
                x: 0,
                y: 2
            )
            .scaleEffect(isSelected ? 1.25 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }

    private var markerSize: CGFloat {
        isSelected ? 38 : 28
    }
}
