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
            } else {
                IncidentListPanel(
                    incidents: flowVM.incidents,
                    onAddIncident: flowVM.addIncident,
                    onSelectIncident: { incident in
                        flowVM.openIncident(
                            incident,
                            firefighterLocation: locationProvider.currentLocation
                        )
                    }
                )
            }

        case .authorizing(let purpose):
            IncidentAuthorizationView(
                title: purpose == .end ? "Hapus Laporan" : "Command Center Authorization",
                message: purpose == .end ? "Masukkan kode 4-digit untuk menghapus laporan ini" : "Masukkan kode incident 4-digit",
                onAuthorized: flowVM.authorizationDidSucceed,
                onCancel: flowVM.authorizationDidCancel
            )

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
                    claimVM: claimVM,
                    reportVM: reportVM,
                    incident: incident,
                    isExpanded: isExpanded,
                    onSelectHydrant: { flowVM.selectHydrant($0, firefighterLocation: locationProvider.currentLocation) },
                    onClose: flowVM.closeIncidentDetail,
                    onRemoveIncident: flowVM.requestRemoveIncident,
                    onReportCondition: onReportCondition
                )
            }
        }
    }
}
