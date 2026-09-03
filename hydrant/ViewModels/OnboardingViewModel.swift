////
////  OnboardingViewModel.swift
////  hydrant
////
////  Created by Daffa Burane Nugraha on 26/08/26.
////
//
//import Foundation
//import SwiftUI
//import Combine
//
//@MainActor
//final class OnboardingViewModel: ObservableObject {
//
//    @Published var selectedRole: UserRole?
//    @Published var selectedTaskForce: TaskForce?
//
//    let roles: [UserRole]
//    let taskForces: [TaskForce]
//
//    init() {
//        self.roles = OnboardingData.roles
//        self.taskForces = OnboardingData.taskForces
//        if let savedRole = UserDefaults.standard.string(forKey: "userRole") {
//            self.selectedRole = UserRole(rawValue: savedRole)
//        }
//        if let savedTaskForce = UserDefaults.standard.string(forKey: "userTaskForce") {
//            self.selectedTaskForce = TaskForce(rawValue: savedTaskForce)
//        }
//    }
//
//    var canContinue: Bool {
//        selectedRole != nil && selectedTaskForce != nil
//    }
//
//    func continueOnboarding() {
//        guard let selectedRole, let selectedTaskForce else {
//            return
//        }
//
//        UserDefaults.standard.set(selectedRole.rawValue, forKey: "userRole")
//        UserDefaults.standard.set(selectedTaskForce.rawValue, forKey: "userTaskForce")
//        print("Saved Selected Role: \(selectedRole.rawValue)")
//        print("Saved Selected Task Force: \(selectedTaskForce.rawValue)")
//    }
//}
