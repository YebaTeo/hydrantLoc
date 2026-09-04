//
//  IncidentMapView.swift
//  hydrant
//

import MapKit
import SwiftUI

// The map surface: route polyline, incident markers, ranked hydrant markers,
// user location, and the fixed center pin used while aiming a new incident.
struct IncidentMapView: View {
    @Bindable var mapViewModel: HydrantMapViewModel
    var flowVM: IncidentFlowViewModel
    var claimVM: HydrantClaimViewModel
    var reportVM: ConditionReportViewModel
    let mapScope: Namespace.ID
    var onSelectIncident: (Incident) -> Void
    var onSelectHydrant: (Hydrant) -> Void
    var onSelectFireStation: (FireStation) -> Void

    var body: some View {
        ZStack {
            map
            if flowVM.isPlacingPin {
                centerPin
            }
        }
    }

    private var map: some View {
        Map(position: $mapViewModel.cameraPosition, scope: mapScope) {
            ForEach(mapViewModel.recommendedHydrantRoutes) { recommendedRoute in
                MapPolyline(recommendedRoute.route.polyline)
                    .stroke(.gray.opacity(0.35), lineWidth: 3)
            }

            if flowVM.isRouting, let route = flowVM.route {
                MapPolyline(route.polyline)
                    .stroke(.blue, lineWidth: 6)
            }

            if mapViewModel.incidentCoordinate != nil {
                ForEach(mapViewModel.displayedRecommendations) { recommendation in
                    recommendationAnnotation(for: recommendation)
                }

                ForEach(mapViewModel.fireStationRecommendations) { recommendation in
                    Annotation(recommendation.station.title, coordinate: recommendation.station.coordinate) {
                        FireStationMarker(isSelected: false)
                            .accessibilityLabel(recommendation.station.accessibilityLabel)
                    }
                }
            } else {
                ForEach(mapViewModel.filteredHydrants) { hydrant in
                    Annotation(hydrant.title, coordinate: hydrant.coordinate) {
                        Button {
                            onSelectHydrant(hydrant)
                        } label: {
                            HydrantMarker(
                                isUsable: hydrant.isUsable,
                                isSelected: mapViewModel.selectedHydrant?.id == hydrant.id,
                                claimedByMine: claimVM.isMine(hydrant),
                                claimedByOther: claimVM.isClaimedByOther(hydrant),
                                hasWarning: reportVM.hasWarning(for: hydrant)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(hydrant.accessibilityLabel)
                    }
                }

                ForEach(mapViewModel.fireStations) { station in
                    Annotation(station.title, coordinate: station.coordinate) {
                        Button {
                            onSelectFireStation(station)
                        } label: {
                            FireStationMarker(
                                isSelected: mapViewModel.selectedFireStation?.id == station.id
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(station.accessibilityLabel)
                    }
                }
            }

            incidentMarkers

            UserAnnotation()
        }
        .mapStyle(mapViewModel.mapStyleMode.mapStyle)
        .onMapCameraChange(frequency: .continuous) { context in
            flowVM.mapCenter = context.region.center
        }
        .ignoresSafeArea(edges: .bottom)
    }

    @MapContentBuilder
    private var incidentMarkers: some MapContent {
        if flowVM.showsAllIncidentMarkers {
            // Browsing the list: every report is a tappable fire incident marker.
            ForEach(flowVM.incidents) { incident in
                Annotation(incident.name, coordinate: incident.coordinate) {
                    Button {
                        onSelectIncident(incident)
                    } label: {
                        FireMarker()
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(incident.name)
                }
            }
        } else if let incident = flowVM.selectedIncident {
            // Detail / routing: only the open incident is shown.
            Annotation(incident.name, coordinate: incident.coordinate) {
                FireMarker(isSelected: true)
            }
        }
    }

    @MapContentBuilder
    // A tappable recommended hydrant that starts in-app routing.
    private func recommendationAnnotation(
        for recommendation: HydrantRecommendation
    ) -> some MapContent {
        let hydrant = recommendation.hydrant
        Annotation(
            "Recommended \(hydrant.title)",
            coordinate: hydrant.coordinate
        ) {
            Button {
                onSelectHydrant(hydrant)
            } label: {
                HydrantMarker(
                    isUsable: hydrant.isUsable,
                    isSelected: flowVM.routedHydrant?.id == hydrant.id,
                    claimedByMine: claimVM.isMine(hydrant),
                    claimedByOther: claimVM.isClaimedByOther(hydrant),
                    hasWarning: reportVM.hasWarning(for: hydrant)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(hydrant.accessibilityLabel)
        }
    }

    // Fixed marker at screen center; the user pans the map underneath to aim it.
    private var centerPin: some View {
        VStack(spacing: 2) {
            Image(systemName: "mappin")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.red)
                .shadow(radius: 3)
            Ellipse()
                .fill(.black.opacity(0.25))
                .frame(width: 10, height: 4)
        }
        // Lift so the pin's tip lands on the geometric center of the map.
        .offset(y: -20)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
