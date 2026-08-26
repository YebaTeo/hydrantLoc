//
//  FireMarker.swift
//  hydrant
//
//  Created by Yeba Teo on 18/08/26.
//

import SwiftUI

struct FireMarker: View {
    var body: some View {
        Image(systemName: "flame.fill")
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(Circle().fill(.orange))
            .overlay(Circle().stroke(.white, lineWidth: 2))
            .shadow(radius: 2, y: 1)
    }
}
