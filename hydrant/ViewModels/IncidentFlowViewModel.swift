//
//  IncidentFlowViewModel.swift
//  hydrant
//

import CoreLocation
import MapKit
import Observation
import SwiftUI

// Owns the incident workflow state machine, the list of incident reports, routing,
// authorization, and incident lifecycle. Holds no SwiftUI views and receives the
// firefighter location as an argument, so it stays independent and testable.
@Observable
final class IncidentFlowViewModel {
    // Current workflow step. Only this view model mutates it.
    private(set) var state: IncidentFlowState = .list

    // All incident reports, newest first, and the one currently opened.
    private(set) var incidents: [Incident] = []
    private(set) var selectedIncident: Incident?

    // Live driving route to the selected hydrant, and that hydrant.
    private(set) var route: MKRoute?
    private(set) var routedHydrant: Hydrant?
    var routeErrorMessage: String?
    var isShowingRemoveIncidentConfirmation = false

    // Center of the map while placing an incident pin; confirm reads it.
    var mapCenter: CLLocationCoordinate2D?

    // Holds a hydrant whose route is waiting for the firefighter location to arrive.
    private var pendingRouteHydrant: Hydrant?

    // Whether the shared (CloudKit) layer is live. Offline-first: when false the app
    // runs entirely on local state and every write is best-effort in the background.
    private(set) var cloudAvailable = false

    private let mapViewModel: HydrantMapViewModel
    private let routeService: RouteService
    private let incidentRepository: IncidentRepository

    init(
        mapViewModel: HydrantMapViewModel,
        routeService: RouteService = RouteService(),
        incidentRepository: IncidentRepository? = nil
    ) {
        self.mapViewModel = mapViewModel
        self.routeService = routeService
        self.incidentRepository = incidentRepository ?? IncidentRepository()
    }

    // MARK: - Shared incident sync (CloudKit)

    // Called once when the screen appears: probe the account, register for live
    // updates, and pull the current shared incident list. Never throws — an
    // unavailable cloud simply leaves the app on local state.
    func startCloudSync() async {
        cloudAvailable = await CloudKitContainer.shared.availability().isAvailable
        guard cloudAvailable else { return }
        try? await incidentRepository.subscribeToActiveIncidents()
        await refreshFromCloud()
    }

    // Merge the server's active incidents into the local list, keyed by id. Upsert
    // only: locally created incidents not yet uploaded are preserved, so a failed
    // or pending sync never makes an incident disappear from the officer's screen.
    func refreshFromCloud() async {
        guard cloudAvailable, let shared = try? await incidentRepository.fetchActive() else {
            return
        }
        var byID = Dictionary(incidents.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        for item in shared {
            byID[item.incident.id] = item.incident
        }
        incidents = byID.values.sorted { $0.createdAt > $1.createdAt }
    }

    // MARK: - Derived state

    var isPlacingPin: Bool { state == .placingPin }
    var isRouting: Bool { route != nil }
    var isAuthorizing: Bool {
        if case .authorizing = state { return true }
        return false
    }
    // Show every incident marker only while browsing the list.
    var showsAllIncidentMarkers: Bool { state == .list }

    // MARK: - Add-incident flow

    // List → passcode gate for a new incident.
    func addIncident() {
        state = .authorizing(purpose: .start)
    }

    // Detail → passcode gate to remove the selected incident.
    func requestRemoveIncident() {
        state = .authorizing(purpose: .end)
    }

    // Called by the passcode view after a valid code is entered.
    func authorizationDidSucceed() {
        switch state {
        case .authorizing(.start):
            state = .placingPin
            mapCenter = mapViewModel.cameraPosition.region?.center ?? HydrantMapDefaults.jakartaRegion.center
        case .authorizing(.end):
            state = selectedIncident == nil ? .list : .incidentDetail
            isShowingRemoveIncidentConfirmation = selectedIncident != nil
        default:
            break
        }
    }

    // Called when the user backs out of the passcode gate.
    func authorizationDidCancel() {
        switch state {
        case .authorizing(.start):
            state = .list
        case .authorizing(.end):
            state = selectedIncident == nil ? .list : .incidentDetail
        default:
            break
        }
    }

    // Recenters the map (and therefore the fixed pin) on a searched address.
    func recenterOnSearchResult(_ coordinate: CLLocationCoordinate2D) {
        mapCenter = coordinate
        recenter(on: coordinate)
    }

    // Creates the incident at the current pin, opens it, and computes recommendations.
    func confirmPinnedLocation(firefighterLocation: CLLocation?) {
        guard let coordinate = mapCenter else { return }
        let incident = Incident(
            name: "Laporan #\(incidents.count + 1)",
            coordinate: coordinate
        )
        incidents.insert(incident, at: 0)
        openIncident(incident, firefighterLocation: firefighterLocation)

        // Publish to the shared layer in the background. The record id is derived
        // from the incident UUID, so a retry (or an offline replay) is idempotent
        // and never creates a duplicate TKP. A failure here does not block the flow.
        publishNewIncident(incident)
    }

    // Best-effort background create; offline-first, never blocks the officer.
    private func publishNewIncident(_ incident: Incident) {
        guard cloudAvailable else { return }
        let shared = SharedIncident(
            incident: incident,
            status: .aktif,
            createdByUnit: DeviceIdentity.unitKode
        )
        Task { try? await incidentRepository.save(shared) }
    }

    // Abandons pin placement without creating an incident.
    func cancelPlacingPin() {
        state = .list
    }

    // MARK: - Incident detail

    // Opens an incident from the list and loads its hydrant recommendations.
    func openIncident(_ incident: Incident, firefighterLocation: CLLocation?) {
        clearRouteState()
        selectedIncident = incident
        mapViewModel.incidentCoordinate = incident.coordinate
        mapViewModel.hydrantRecommendations = []
        recenter(on: incident.coordinate)
        state = .incidentDetail

        Task { @MainActor in
            await mapViewModel.updateHydrantRecommendations(
                incidentCoordinate: incident.coordinate,
                firefighterLocation: firefighterLocation,
                routeService: routeService
            )

            if let topRec = mapViewModel.displayedRecommendations.first {
                await calculateRoute(to: topRec.hydrant, firefighterLocation: firefighterLocation)
            }
        }
    }

    // Returns to the list without deleting the incident (a lightweight exit).
    func closeIncidentDetail() {
        clearRouteState()
        selectedIncident = nil
        mapViewModel.incidentCoordinate = nil
        mapViewModel.hydrantRecommendations = []
        mapViewModel.recommendationErrorMessage = nil
        mapViewModel.isLoadingRecommendations = false
        state = .list
    }

    private func removeSelectedIncident() {
        if let selectedIncident {
            // Ending a report finishes the shared incident (status → selesai) so it
            // drops off every other unit's active list too. Background, best-effort.
            if cloudAvailable {
                let shared = SharedIncident(
                    incident: selectedIncident,
                    status: .selesai,
                    createdByUnit: DeviceIdentity.unitKode
                )
                Task { try? await incidentRepository.markFinished(shared) }
            }
            incidents.removeAll { $0.id == selectedIncident.id }
        }
        closeIncidentDetail()
    }

    func confirmRemoveIncident() {
        isShowingRemoveIncidentConfirmation = false
        removeSelectedIncident()
    }

    func cancelRemoveIncident() {
        isShowingRemoveIncidentConfirmation = false
        state = selectedIncident == nil ? .list : .incidentDetail
    }

    // MARK: - Routing

    // Selects a recommended hydrant and begins firefighter-to-hydrant routing.
    func selectHydrant(_ hydrant: Hydrant, firefighterLocation: CLLocation?) {
        pendingRouteHydrant = hydrant
        Task { @MainActor in
            await calculateRoute(to: hydrant, firefighterLocation: firefighterLocation)
        }
    }

    // Clears only the active route, keeping the incident open.
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
            let calculatedRoute = try await routeService.calculateRoute(
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
        }
    }

    // MARK: - Location updates

    // Resumes a pending route when the firefighter location arrives, or recenters
    // on the user while idly browsing the list.
    func locationUpdated(_ location: CLLocation) {
        if let pendingRouteHydrant {
            Task { @MainActor in
                await calculateRoute(to: pendingRouteHydrant, firefighterLocation: location)
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

    private func recenter(on coordinate: CLLocationCoordinate2D) {
        mapViewModel.cameraPosition = .region(
            MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.035, longitudeDelta: 0.035)
            )
        )
    }

    // Expands the route bounds so the polyline is not hidden behind the sheet.
    private func paddedMapRect(for route: MKRoute) -> MKMapRect {
        let rect = route.polyline.boundingMapRect
        let padding = max(max(rect.size.width, rect.size.height) * 0.25, 1_000)
        return rect.insetBy(dx: -padding, dy: -padding)
    }
}
