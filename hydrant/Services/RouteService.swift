//
//  RouteService.swift
//  hydrant
//
//  Created by Yeba Teo on 26/08/26.
//

import Foundation
import CoreLocation
import MapKit

struct RouteService {
    func calculateRouteMetrics(
        from source: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D
    ) async throws -> RouteMetrics {
        let route = try await calculateRoute(
            from: source,
            to: destination
        )
        return RouteMetrics(
            distance: route.distance,
            expectedTravelTime: route.expectedTravelTime
        )
    }

    func calculateRoute(
        from source: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D
    ) async throws -> MKRoute {

        let request = MKDirections.Request()

        request.source = MKMapItem(
            location: CLLocation(
                latitude: source.latitude,
                longitude: source.longitude
            ),
            address: nil
        )

        request.destination = MKMapItem(
            location: CLLocation(
                latitude: destination.latitude,
                longitude: destination.longitude
            ),
            address: nil
        )

        request.transportType = .automobile

        let directions = MKDirections(request: request)
        let response = try await directions.calculate()

        guard let route = response.routes.first else {
            throw RouteError.routeNotFound
        }

        return route
    }
}

struct RouteMetrics {
    let distance: CLLocationDistance
    let expectedTravelTime: TimeInterval
}

enum RouteError: Error {
    case routeNotFound
}
