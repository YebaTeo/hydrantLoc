//
//  HydrantMarker.swift
//  hydrant
//
//  Created by Yeba Teo on 18/08/26.
//

import SwiftUI

// Map marker tinted green when usable and red when unusable.
struct HydrantMarker: View {
    let isUsable: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(isUsable ? Color.green : Color.red)
                .frame(width: 20, height: 20)
            Circle()
                .stroke(.white, lineWidth: 3)
                .frame(width: 20, height: 20)
            Image(systemName: "drop.fill")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white)
        }
        .shadow(radius: 2, y: 1)
    }
}
