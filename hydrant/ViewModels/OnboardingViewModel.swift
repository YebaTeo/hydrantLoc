//
//  OnboardingViewModel.swift
//  hydrant
//
//  Created by Daffa Burane Nugraha on 26/08/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class OnboardingViewModel: ObservableObject {

    @Published var selectedRole: UserRole?
    @Published var selectedTaskForce: TaskForce = .jakartaPusat

    let roles: [UserRole]
    let taskForces: [TaskForce]

    init() {
        self.roles = OnboardingData.roles
        self.taskForces = OnboardingData.taskForces
    }

    var canContinue: Bool {
        selectedRole != nil
    }

    func continueOnboarding() {
        guard let selectedRole else {
            return
        }

        print("Selected Role: \(selectedRole.rawValue)")
        print("Selected Task Force: \(selectedTaskForce.rawValue)")
    }
}
