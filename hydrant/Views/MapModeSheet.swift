//
//  MapModeSheet.swift
//  hydrant
//
//  Created by Yeba Teo on 18/08/26.
//

import SwiftUI

struct MapModeSheet: View {
    @Binding var selection: MapMode
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 28) {
            header

            HStack(spacing: 16) {
                ForEach(MapMode.allCases) { mode in
                    Button {
                        selection = mode
                    } label: {
                        MapModeCard(mode: mode, isSelected: selection == mode)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)

            Spacer(minLength: 0)
        }
        .padding(24)
    }

    private var header: some View {
        ZStack {
            Text("Mode Peta")
                .font(.title2.bold())

            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(.gray.opacity(0.25)))
                }
                .accessibilityLabel("Tutup")
            }
        }
    }
}

private struct MapModeCard: View {
    let mode: MapMode
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: mode.thumbnailColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 150, height: 112)
                .overlay {
                    Image(systemName: mode.systemImage)
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(isSelected ? Color.accentColor : .clear, lineWidth: 3)
                }

            Text(mode.title)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .primary : .secondary)
        }
    }
}

#Preview {
    MapModeSheet(selection: .constant(.explore))
        .presentationDetents([.height(300)])
}
