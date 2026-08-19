//
//  LocationProvider.swift
//  hydrant
//
//  Created by Yeba Teo on 18/08/26.
//

import CoreLocation
import Foundation
import Observation

// Wraps Core Location so SwiftUI views can observe location and permission changes.
@Observable
final class LocationProvider: NSObject, CLLocationManagerDelegate {
    // Apple location manager used to request permission and one-time location updates.
    private let manager = CLLocationManager()

    // Latest known user location, used for nearest hydrant and distance display.
    var currentLocation: CLLocation?

    // Current permission state for location access.
    var authorizationStatus: CLAuthorizationStatus

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    // Requests permission on first launch, or refreshes location if already allowed.
    func requestAuthorization() {
        guard canRequestLocation else { return }

        switch authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .denied, .restricted:
            break
        @unknown default:
            break
        }
    }

    // Requests the user's current location when permission allows it.
    func requestLocation() {
        guard canRequestLocation else { return }

        switch authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .denied, .restricted:
            break
        @unknown default:
            break
        }
    }

    // Prevents a crash if the app target has no location usage description yet.
    private var canRequestLocation: Bool {
        Bundle.main.object(forInfoDictionaryKey: "NSLocationWhenInUseUsageDescription") != nil
    }

    // Updates stored permission state whenever the user changes location access.
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }

    // Saves the newest location returned by Core Location.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }

    // Clears the stored location when Core Location cannot provide one.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        currentLocation = nil
    }
}
