//
//  MapModeSelectionSheet.swift
//  hydrant
//

import SwiftUI

// Bottom sheet presentation for choosing between Standar and Satelit map modes,
// featuring card-style selectors inspired by Apple Maps.
struct MapModeSelectionSheet: View {
    @Binding var selectedMode: MapStyleMode
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            header
            modeCards
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .presentationDetents([.height(230)])
        .presentationCornerRadius(24)
        .presentationBackground(.regularMaterial)
    }

    private var header: some View {
        HStack {
            Text("Mode Peta")
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 30, height: 30)
                    .background(.thinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Tutup")
        }
    }

    private var modeCards: some View {
        HStack(spacing: 16) {
            modeCard(
                mode: .standard,
                title: "Standar",
                iconName: "map.fill",
                gradient: [Color.blue.opacity(0.65), Color.cyan.opacity(0.85)]
            )

            modeCard(
                mode: .satellite,
                title: "Satelit",
                iconName: "globe.americas.fill",
                gradient: [Color.indigo.opacity(0.75), Color.teal.opacity(0.85)]
            )
        }
    }

    private func modeCard(
        mode: MapStyleMode,
        title: String,
        iconName: String,
        gradient: [Color]
    ) -> some View {
        let isSelected = selectedMode == mode

        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                selectedMode = mode
            }
            dismiss()
        } label: {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 80)

                    Image(systemName: iconName)
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.2), radius: 3, y: 1)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                )
                .shadow(color: isSelected ? Color.blue.opacity(0.3) : Color.clear, radius: 6)

                HStack(spacing: 6) {
                    Text(title)
                        .font(.subheadline.weight(isSelected ? .bold : .medium))
                        .foregroundStyle(isSelected ? .blue : .primary)

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.blue)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MapModeSelectionSheet(selectedMode: .constant(.standard))
}
