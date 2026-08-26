//
//  MetricView.swift
//  hydrant
//
//  Created by Yeba Teo on 18/08/26.
//

import SwiftUI

// Compact count-and-label display used in the map status bar.
struct MetricView: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.headline.monospacedDigit())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 54, alignment: .leading)
    }
}
