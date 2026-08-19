//
//  MapsNavigationService.swift
//  hydrant
//
//  Created by Yeba Teo on 18/08/26.
//

import MapKit

// Opens selected hydrants in the Apple Maps app.
enum MapsNavigationService {
    // Starts driving navigation to the chosen hydrant and enables traffic display.
    static func openDirections(to hydrant: Hydrant) {
        let item = MKMapItem(location: hydrant.location, address: nil)
        item.name = hydrant.title
        item.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving,
            MKLaunchOptionsShowsTrafficKey: true
        ])
    }
}
