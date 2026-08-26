//
//  RootView.swift
//  hydrant
//

import SwiftUI

struct RootView: View {

    @AppStorage("hasCompletedOnboarding")
    private var hasCompletedOnboarding = false

    var body: some View {
        Group {

            if hasCompletedOnboarding {

                ContentView()

            } else {

                OnboardingView(
                    hasCompletedOnboarding: $hasCompletedOnboarding
                )
            }
        }
    }
}

#Preview {
    RootView()
}
