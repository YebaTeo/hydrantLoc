//
//  IncidentControllerSheet.swift
//  hydrant
//

import SwiftUI

// The single persistent bottom sheet that steers the whole app. It renders the
// panel for the current workflow step and wires panel intents to the flow view
// model. This replaces the five separate, ephemeral sheets the old flow used.
struct IncidentControllerSheet: View {
    var mapViewModel: HydrantMapViewModel
    var flowVM: IncidentFlowViewModel
    var locationProvider: LocationProvider
    var isExpanded: Bool

    var body: some View {
        switch flowVM.state {
        case .list:
            if let hydrant = mapViewModel.selectedHydrant {
                HydrantDetailPanel(
                    hydrant: hydrant,
                    onClose: {
                        mapViewModel.selectedHydrant = nil
                    }
                )
            } else {
                IncidentListPanel(
                    incidents: flowVM.incidents,
                    canAddIncident: flowVM.canManageIncidents,
                    onAddIncident: flowVM.addIncident,
                    onSelectIncident: { incident in
                        flowVM.openIncident(
                            incident,
                            firefighterLocation: locationProvider.currentLocation
                        )
                    }
                )
            }

        case .placingPin:
            PlacingPinPanel(
                mapCenter: flowVM.mapCenter,
                onSelectSearchResult: flowVM.recenterOnSearchResult,
                onConfirm: { flowVM.confirmPinnedLocation(firefighterLocation: locationProvider.currentLocation) },
                onCancel: flowVM.cancelPlacingPin
            )

        case .incidentDetail, .routing:
            if let incident = flowVM.selectedIncident {
                NearbyHydrantsPanel(
                    mapViewModel: mapViewModel,
                    incident: incident,
                    isExpanded: isExpanded,
                    canRemoveIncident: flowVM.canManageIncidents,
                    onSelectHydrant: { flowVM.selectHydrant($0, firefighterLocation: locationProvider.currentLocation) },
                    onClose: flowVM.closeIncidentDetail,
                    onRemoveIncident: flowVM.requestRemoveIncident
                )
            }
        }
    }
}
