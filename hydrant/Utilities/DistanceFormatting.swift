//
//  DistanceFormatting.swift
//  hydrant
//

import CoreLocation
import Foundation

// Centralized distance/ETA formatting shared by view models and views.
// Replaces the copies that previously lived in ContentView and HydrantMapViewModel.
enum DistanceFormatting {
    // Formats a distance in meters, switching to kilometers past 1 km.
    static func distance(_ meters: CLLocationDistance) -> String {
        if meters < 1000 {
            return "\(Int(meters.rounded())) m"
        }
        return String(format: "%.1f km", meters / 1000)
    }

    // Formats an expected travel time in minutes/hours without exposing raw seconds.
    static func travelTime(_ seconds: TimeInterval) -> String {
        let minutes = Int((seconds / 60).rounded(.up))
        if minutes < 60 {
            return "\(minutes) min"
        }

        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        if remainingMinutes == 0 {
            return "\(hours) hr"
        }
        return "\(hours) hr \(remainingMinutes) min"
    }
}
