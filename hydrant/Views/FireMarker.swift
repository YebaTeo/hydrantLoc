//
//  FireMarker.swift
//  hydrant
//
//  Created by Yeba Teo on 18/08/26.
//

import SwiftUI

struct FireMarker: View {
    var isSelected: Bool = false

    var body: some View {
        Image("FireIncidentMarkerPin")
            .resizable()
            .scaledToFit()
            .frame(width: markerSize, height: markerSize)
            .shadow(color: .black.opacity(0.3), radius: isSelected ? 5 : 3, x: 0, y: 2)
            .scaleEffect(isSelected ? 1.2 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }

    private var markerSize: CGFloat {
        isSelected ? 32 : 24
    }
}

