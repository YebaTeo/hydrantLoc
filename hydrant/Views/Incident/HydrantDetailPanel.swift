//
//  HydrantDetailPanel.swift
//  hydrant
//

import SwiftUI

// Bottom sheet content displayed when tapping any hydrant annotation on the map.
struct HydrantDetailPanel: View {
    var hydrant: Hydrant
    var reportVM: ConditionReportViewModel
    var onClose: () -> Void
    var onReportCondition: (Hydrant) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            conditionBanner
            Divider()
            details
            actions
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(hydrant.title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                HStack(spacing: 6) {
                    Image(systemName: hydrant.isUsable ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(hydrant.isUsable ? .green : .red)
                    Text(hydrant.isUsable ? "Siap Digunakan" : "Kondisi Rusak")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(hydrant.isUsable ? .green : .red)
                }
            }

            Spacer()

            Button {
                onClose()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Tutup")
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 8) {
            detailRow(title: "Wilayah", value: hydrant.wilayah.capitalized)
            detailRow(title: "Kecamatan", value: hydrant.kecamatan.capitalized)
            detailRow(title: "Kelurahan", value: hydrant.kelurahan.capitalized)
            detailRow(title: "Alamat", value: hydrant.alamat.capitalized)
        }
    }

    private func detailRow(title: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)
        }
    }

    @ViewBuilder
    private var conditionBanner: some View {
        if let report = reportVM.latestReport(for: hydrant) {
            Label(
                "\(report.condition.title) — dilaporkan \(report.reportedByUnit), \(report.time.formatted(date: .omitted, time: .shortened))",
                systemImage: report.condition.systemImage
            )
            .font(.caption.weight(.semibold))
            .foregroundStyle(report.condition.isProblem ? .orange : .green)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(
                (report.condition.isProblem ? Color.orange : Color.green).opacity(0.12),
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
        }
    }

    private var actions: some View {
        VStack(spacing: 10) {
            Button {
                onReportCondition(hydrant)
            } label: {
                Label("Laporkan Kondisi", systemImage: "exclamationmark.bubble.fill")
                    .font(.subheadline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
            }
            .buttonStyle(.bordered)
            .tint(.orange)
            .buttonBorderShape(.roundedRectangle(radius: 12))

            Button {
                MapsNavigationService.openDirections(to: hydrant)
            } label: {
                Label("Navigasi via Apple Maps", systemImage: "map.fill")
                    .font(.subheadline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .buttonBorderShape(.roundedRectangle(radius: 12))
        }
        .padding(.top, 4)
    }
}
