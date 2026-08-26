//
//  IncidentSearchService.swift
//  hydrant
//
//  Created by Yeba Teo on 26/08/26.
//

import CoreLocation
import Foundation
import MapKit
import Observation

@Observable
final class IncidentSearchService: NSObject, MKLocalSearchCompleterDelegate {
    var query = "" {
        didSet {
            updateQueryFragment()
        }
    }
    var completions: [MKLocalSearchCompletion] = []
    var isSearching = false

    private let completer = MKLocalSearchCompleter()
    private let searchRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -6.2088, longitude: 106.8456),
        span: MKCoordinateSpan(latitudeDelta: 0.6, longitudeDelta: 0.6)
    )

    override init() {
        super.init()
        completer.delegate = self
        completer.region = searchRegion
        completer.resultTypes = [.address, .pointOfInterest]
    }

    func resolve(_ completion: MKLocalSearchCompletion) async throws -> CLLocationCoordinate2D {
        isSearching = true
        defer { isSearching = false }

        let request = MKLocalSearch.Request(completion: completion)
        request.region = searchRegion
        request.resultTypes = [.address, .pointOfInterest]

        let search = MKLocalSearch(request: request)
        let response = try await search.start()

        guard let coordinate = response.mapItems.first?.location.coordinate else {
            throw IncidentSearchError.locationNotFound
        }

        return coordinate
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        completions = completer.results
        isSearching = false
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: any Error) {
        print("❌ INCIDENT SEARCH FAILED:", error)
        completions = []
        isSearching = false
    }

    private func updateQueryFragment() {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            completions = []
            isSearching = false
            completer.queryFragment = ""
            return
        }

        isSearching = true
        completer.queryFragment = trimmedQuery
    }
}

enum IncidentSearchError: Error {
    case locationNotFound
}
