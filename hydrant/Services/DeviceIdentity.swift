//
//  DeviceIdentity.swift
//  hydrant
//
//  The device's identity, as chosen during onboarding and stored in UserDefaults.
//  This is the "device-identity, no login" model: the app never asks who you are
//  at use time — the unit and region were set once and every shared record is
//  attributed from here. In production this would come from MDM provisioning.
//

import Foundation

enum DeviceIdentity {
    private static let roleKey = "userRole"
    private static let wilayahKey = "userTaskForce"
    private static let unitCodeKey = "unitKode"

    static var role: String {
        UserDefaults.standard.string(forKey: roleKey) ?? UserRole.petugas.rawValue
    }

    static var wilayah: String {
        UserDefaults.standard.string(forKey: wilayahKey) ?? TaskForce.jakartaPusat.rawValue
    }

    // A short, stable unit code (e.g. "JS-07"), generated once per install so two
    // demo devices are distinguishable in claim labels ("dipakai unit JS-07").
    // A real deployment would carry the actual unit code from MDM instead.
    static var unitKode: String {
        if let existing = UserDefaults.standard.string(forKey: unitCodeKey) {
            return existing
        }
        let code = "\(wilayahAbbreviation)-\(String(format: "%02d", Int.random(in: 1...99)))"
        UserDefaults.standard.set(code, forKey: unitCodeKey)
        return code
    }

    private static var wilayahAbbreviation: String {
        switch wilayah {
        case TaskForce.jakartaPusat.rawValue: return "JP"
        case TaskForce.jakartaBarat.rawValue: return "JB"
        case TaskForce.jakartaTimur.rawValue: return "JT"
        case TaskForce.jakartaUtara.rawValue: return "JU"
        case TaskForce.jakartaSelatan.rawValue: return "JS"
        default: return "JKT"
        }
    }
}
