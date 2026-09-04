//
//  IncidentControllerSheet.swift
//  hydrant
//

import SwiftUI

// The single persistent bottom sheet that steers the whole app.
// It renders the panel for the current workflow step and wires
// panel intents to the flow view model.
struct IncidentControllerSheet: View {

    var mapViewModel: HydrantMapViewModel
    var flowVM: IncidentFlowViewModel
    var claimVM: HydrantClaimViewModel
    var reportVM: ConditionReportViewModel
    var locationProvider: LocationProvider
    var isExpanded: Bool
    var onReportCondition: (Hydrant) -> Void

    var body: some View {
        switch flowVM.state {
        case .list:
            if let hydrant = mapViewModel.selectedHydrant {
                HydrantDetailPanel(
                    hydrant: hydrant,
                    reportVM: reportVM,
                    onClose: {
                        mapViewModel.selectedHydrant = nil
                    },
                    onReportCondition: onReportCondition
                )
            } else if let station = mapViewModel.selectedFireStation {
                FireStationDetailPanel(
                    station: station,
                    onClose: {
                        mapViewModel.selectedFireStation = nil
                    }
                )
            } else {
                IncidentListPanel(
                    incidents: flowVM.incidents,
                    canAddIncident: flowVM.canManageIncidents,
                    isExpanded: isExpanded,
                    onAddIncident: flowVM.addIncident,
                    onSelectIncident: { incident in
                        flowVM.openIncident(
                            incident,
                            firefighterLocation:
                                locationProvider.currentLocation
                        )
                    }
                )
            }

        case .placingPin:
            PlacingPinPanel(
                mapCenter: flowVM.mapCenter,
                onSelectSearchResult: flowVM.recenterOnSearchResult,
                onConfirm: {
                    flowVM.confirmPinnedLocation(
                        firefighterLocation:
                            locationProvider.currentLocation
                    )
                },
                onCancel: flowVM.cancelPlacingPin
            )

        case .incidentDetail, .routing:
            if let incident = flowVM.selectedIncident {
                NearbyHydrantsPanel(
                    mapViewModel: mapViewModel,
                    claimVM: claimVM,
                    reportVM: reportVM,
                    incident: incident,
                    selectedHydrant: flowVM.routedHydrant,
                    isExpanded: isExpanded,
                    canRemoveIncident: flowVM.canManageIncidents,
                    onSelectHydrant: { flowVM.selectHydrant($0, firefighterLocation: locationProvider.currentLocation) },
                    onClose: flowVM.closeIncidentDetail,
                    onRemoveIncident: flowVM.requestRemoveIncident,
                    onReportCondition: onReportCondition
                )
            }
        }
    }
}
