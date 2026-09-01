//
//  OnboardingOption.swift
//  hydrant
//
//  Created by Daffa Burane Nugraha on 26/08/26.
//


import Foundation

enum UserRole: String, CaseIterable, Identifiable {
    case petugas = "Satgas"
    case admin = "Comand Center"

    var id: String {
        rawValue
    }

    var canManageIncidents: Bool {
        self == .admin
    }

    static var saved: UserRole? {
        guard let rawValue = UserDefaults.standard.string(forKey: "userRole") else {
            return nil
        }
        return UserRole(rawValue: rawValue)
    }
}

enum TaskForce: String, CaseIterable, Identifiable {
    case jakartaPusat = "Jakarta Pusat"
    case jakartaBarat = "Jakarta Barat"
    case jakartaTimur = "Jakarta Timur"
    case jakartaUtara = "Jakarta Utara"
    case jakartaSelatan = "Jakarta Selatan"

    var id: String {
        rawValue
    }
}
