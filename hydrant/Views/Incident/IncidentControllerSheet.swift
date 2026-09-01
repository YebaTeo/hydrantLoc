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

        case .authorizing(let purpose):
            IncidentAuthorizationView(
                title: purpose == .end
                    ? "Hapus Laporan"
                    : "Command Center Authorization",
                message: purpose == .end
                    ? "Masukkan kode 4-digit untuk menghapus laporan ini"
                    : "Masukkan kode incident 4-digit",
                onAuthorized: flowVM.authorizationDidSucceed,
                onCancel: flowVM.authorizationDidCancel
            )

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
                    incident: incident,
                    selectedHydrant: flowVM.routedHydrant,
                    isExpanded: isExpanded,
                    onSelectHydrant: { hydrant in
                        flowVM.selectHydrant(
                            hydrant,
                            firefighterLocation:
                                locationProvider.currentLocation
                        )
                    },
                    onClose: flowVM.closeIncidentDetail,
                    onRemoveIncident: flowVM.requestRemoveIncident
                )
            }
        }
    }
}
