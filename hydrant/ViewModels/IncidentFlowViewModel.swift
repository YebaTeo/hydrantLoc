//
//  IncidentFlowViewModel.swift
//  hydrant
//

import CoreLocation
import MapKit
import Observation
import SwiftUI

@Observable
final class IncidentFlowViewModel {

    // MARK: - Workflow state

    private(set) var state: IncidentFlowState = .list

    private(set) var incidents: [Incident] = []
    private(set) var selectedIncident: Incident?

    private(set) var route: MKRoute?
    private(set) var routedHydrant: Hydrant?

    var routeErrorMessage: String?
    var isShowingRemoveIncidentConfirmation = false
    var mapCenter: CLLocationCoordinate2D?

    private var pendingRouteHydrant: Hydrant?

    private let mapViewModel: HydrantMapViewModel
    private let routeService: RouteService
    private let currentUserRole: UserRole?

    init(
        mapViewModel: HydrantMapViewModel,
        routeService: RouteService = RouteService(),
        currentUserRole: UserRole? = .saved
    ) {
        self.mapViewModel = mapViewModel
        self.routeService = routeService
        self.currentUserRole = currentUserRole
    }

    // MARK: - Derived state

    var isPlacingPin: Bool {
        state == .placingPin
    }

    var isRouting: Bool {
        route != nil
    }

    var canManageIncidents: Bool {
        currentUserRole?.canManageIncidents == true
    }

    var showsAllIncidentMarkers: Bool {
        state == .list
    }

    // MARK: - Add incident

    func addIncident() {
        guard canManageIncidents else {
            return
        }

        state = .placingPin

        mapCenter =
            mapViewModel.cameraPosition.region?.center
            ?? HydrantMapDefaults.jakartaRegion.center
    }

    func requestRemoveIncident() {
        guard canManageIncidents,
              selectedIncident != nil
        else {
            return
        }

        isShowingRemoveIncidentConfirmation = true
    }

    func recenterOnSearchResult(
        _ coordinate: CLLocationCoordinate2D
    ) {
        guard canManageIncidents,
              state == .placingPin
        else {
            return
        }

        mapCenter = coordinate
        recenter(on: coordinate)
    }

    func confirmPinnedLocation(
        firefighterLocation: CLLocation?
    ) {
        guard canManageIncidents,
              let coordinate = mapCenter
        else {
            return
        }

        let incident = Incident(
            name: "Laporan #\(incidents.count + 1)",
            coordinate: coordinate
        )

        incidents.insert(incident, at: 0)

        openIncident(
            incident,
            firefighterLocation: firefighterLocation
        )
    }

    func cancelPlacingPin() {
        guard canManageIncidents else {
            return
        }

        mapCenter = nil
        state = .list
    }

    // MARK: - Incident detail

    func openIncident(
        _ incident: Incident,
        firefighterLocation: CLLocation?
    ) {
        clearRouteState()

        selectedIncident = incident
        mapViewModel.incidentCoordinate = incident.coordinate
        mapViewModel.hydrantRecommendations = []
        mapViewModel.recommendedHydrantRoutes = []

        recenter(on: incident.coordinate)

        state = .incidentDetail

        Task { @MainActor in
            await mapViewModel.updateHydrantRecommendations(
                incidentCoordinate: incident.coordinate,
                firefighterLocation: firefighterLocation,
                routeService: routeService
            )

            async let recommendedRoutes: Void =
                mapViewModel.updateRecommendedHydrantRoutes(
                    incidentCoordinate: incident.coordinate,
                    routeService: routeService
                )

            if let topRecommendation =
                mapViewModel.displayedRecommendations.first {
                await calculateRoute(
                    to: topRecommendation.hydrant,
                    firefighterLocation: firefighterLocation
                )
            }

            await recommendedRoutes
        }
    }

    func closeIncidentDetail() {
        clearRouteState()

        selectedIncident = nil
        mapViewModel.incidentCoordinate = nil
        mapViewModel.hydrantRecommendations = []
        mapViewModel.recommendedHydrantRoutes = []
        mapViewModel.recommendationErrorMessage = nil
        mapViewModel.isLoadingRecommendations = false

        state = .list
    }

    private func removeSelectedIncident() {
        guard canManageIncidents else {
            return
        }

        if let selectedIncident {
            incidents.removeAll {
                $0.id == selectedIncident.id
            }
        }

        closeIncidentDetail()
    }

    func confirmRemoveIncident() {
        guard canManageIncidents else {
            return
        }

        isShowingRemoveIncidentConfirmation = false
        removeSelectedIncident()
    }

    func cancelRemoveIncident() {
        isShowingRemoveIncidentConfirmation = false

        state = selectedIncident == nil
            ? .list
            : .incidentDetail
    }

    // MARK: - Routing

    func selectHydrant(
        _ hydrant: Hydrant,
        firefighterLocation: CLLocation?
    ) {
        // Langsung perbarui hidran aktif agar carousel ikut berubah.
        routedHydrant = hydrant
        pendingRouteHydrant = hydrant

        // Hilangkan rute lama selama rute baru dihitung.
        route = nil
        routeErrorMessage = nil

        Task { @MainActor in
            await calculateRoute(
                to: hydrant,
                firefighterLocation: firefighterLocation
            )
        }
    }

    func endRoute() {
        clearRouteState()
    }

    @MainActor
    private func calculateRoute(
        to hydrant: Hydrant,
        firefighterLocation: CLLocation?
    ) async {
        guard let userLocation = firefighterLocation else {
            return
        }

        do {
            let calculatedRoute =
                try await routeService.calculateRoute(
                    from: userLocation.coordinate,
                    to: hydrant.coordinate
                )

            route = calculatedRoute
            routedHydrant = hydrant
            pendingRouteHydrant = nil
            routeErrorMessage = nil
        } catch {
            route = nil
            routedHydrant = nil
            pendingRouteHydrant = nil

            routeErrorMessage =
                "Rute menuju hidran yang dipilih tidak dapat ditemukan."
        }
    }

    // MARK: - Location updates

    func locationUpdated(_ location: CLLocation) {
        if let pendingRouteHydrant {
            Task { @MainActor in
                await calculateRoute(
                    to: pendingRouteHydrant,
                    firefighterLocation: location
                )
            }
        } else if state == .list {
            mapViewModel.updateCamera(to: location)
        }
    }

    // MARK: - Helpers

    private func clearRouteState() {
        route = nil
        routedHydrant = nil
        pendingRouteHydrant = nil
        routeErrorMessage = nil
    }

    private func recenter(
        on coordinate: CLLocationCoordinate2D
    ) {
        mapViewModel.cameraPosition = .region(
            MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(
                    latitudeDelta: 0.035,
                    longitudeDelta: 0.035
                )
            )
        )
    }
}
