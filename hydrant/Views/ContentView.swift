//
//  ContentView.swift
//  hydrant
//
//  Created by Yeba Teo on 18/08/26.
//

import MapKit
import SwiftUI

// Main screen. A thin composition layer: it owns the view models, hosts the map
// and its top overlays, and presents the single persistent controller sheet.
// All workflow logic lives in IncidentFlowViewModel.
struct ContentView: View {
    @State private var mapViewModel: HydrantMapViewModel
    @State private var flowVM: IncidentFlowViewModel
    @State private var claimVM = HydrantClaimViewModel()
    @State private var reportVM = ConditionReportViewModel()
    @State private var locationProvider = LocationProvider()

    // The hydrant whose condition-report form is open, if any.
    @State private var reportingHydrant: Hydrant?

    // Connects the custom MapKit controls to this map instance.
    @Namespace private var mapScope

    // Whether the controller sheet is expanded.
    @State private var isSheetExpanded = false

    @State private var isShowingMapModes = false

    init() {
        let map = HydrantMapViewModel()
        _mapViewModel = State(initialValue: map)
        _flowVM = State(initialValue: IncidentFlowViewModel(mapViewModel: map))
    }

    private var isRouteErrorPresented: Binding<Bool> {
        Binding(
            get: { flowVM.routeErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    flowVM.routeErrorMessage = nil
                }
            }
        )
    }

    var body: some View {
        @Bindable var mapViewModel = mapViewModel
        @Bindable var flowVM = flowVM
        NavigationStack {
            ZStack(alignment: .top) {
                IncidentMapView(
                    mapViewModel: mapViewModel,
                    flowVM: flowVM,
                    claimVM: claimVM,
                    reportVM: reportVM,
                    mapScope: mapScope,
                    onSelectIncident: { incident in
                        mapViewModel.selectedHydrant = nil
                        mapViewModel.selectedFireStation = nil
                        flowVM.openIncident(
                            incident,
                            firefighterLocation: locationProvider.currentLocation
                        )
                    },
                    onSelectHydrant: { hydrant in
                        mapViewModel.selectedFireStation = nil
                        if flowVM.selectedIncident != nil {
                            flowVM.selectHydrant(
                                hydrant,
                                firefighterLocation: locationProvider.currentLocation
                            )
                        } else {
                            mapViewModel.selectedHydrant = hydrant
                        }
                    },
                    onSelectFireStation: { station in
                        mapViewModel.selectedHydrant = nil
                        mapViewModel.selectedFireStation = station
                    }
                )

                MapTopControls(
                    mapViewModel: mapViewModel,
                    flowVM: flowVM,
                    mapScope: mapScope,
                    isPlacingPin: flowVM.isPlacingPin,
                    onOpenMapModes: {
                        isShowingMapModes = true
                    }
                )

                BottomSheet(isExpanded: $isSheetExpanded) {
                    IncidentControllerSheet(
                        mapViewModel: mapViewModel,
                        flowVM: flowVM,
                        claimVM: claimVM,
                        reportVM: reportVM,
                        locationProvider: locationProvider,
                        isExpanded: isSheetExpanded,
                        onReportCondition: { reportingHydrant = $0 }
                    )
                }
            }
            .mapScope(mapScope)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $isShowingMapModes) {
                MapModeSelectionSheet(selectedMode: $mapViewModel.mapStyleMode)
            }
            .alert(
                "Unable to Calculate Route",
                isPresented: isRouteErrorPresented
            ) {
                Button("OK", role: .cancel) {
                    flowVM.routeErrorMessage = nil
                }
            } message: {
                Text(flowVM.routeErrorMessage ?? "A driving route to this hydrant could not be found.")
            }
            .alert(
                "Akhiri laporan ini?",
                isPresented: $flowVM.isShowingRemoveIncidentConfirmation
            ) {
                Button("Akhiri Laporan", role: .destructive) {
                    // Free any hydrants this unit held for the incident before it
                    // closes, so they drop off every other unit's map too.
                    if let incidentID = flowVM.selectedIncident?.id {
                        Task { await claimVM.releaseAll(forIncident: incidentID) }
                    }
                    flowVM.confirmRemoveIncident()
                }
                Button("Batalkan", role: .cancel) {
                    flowVM.cancelRemoveIncident()
                }
            } message: {
                Text("Ini akan menghapus laporan insiden, rekomendasi hidran, dan semua rute yang sedang aktif.")
            }
            .onAppear {
                locationProvider.requestAuthorization()
            }
            .task {
                // Probe iCloud, register for live updates, and pull the shared
                // incident list + active claims. No-op when cloud is offline.
                await flowVM.startCloudSync()
                await claimVM.start()
                await reportVM.start()
            }
            .refreshable {
                await flowVM.refreshFromCloud()
                await claimVM.refresh()
                await reportVM.refresh()
            }
            .sheet(item: $reportingHydrant) { hydrant in
                ConditionReportSheet(
                    hydrant: hydrant,
                    incidentID: flowVM.selectedIncident?.id,
                    onSubmit: { level, condition, note in
                        Task {
                            await reportVM.submit(
                                hydrant: hydrant,
                                level: level,
                                condition: condition,
                                note: note,
                                incidentID: flowVM.selectedIncident?.id
                            )
                        }
                    }
                )
            }
            .alert(
                "Klaim Hidran",
                isPresented: Binding(
                    get: { claimVM.conflictMessage != nil },
                    set: { if !$0 { claimVM.conflictMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) { claimVM.conflictMessage = nil }
            } message: {
                Text(claimVM.conflictMessage ?? "")
            }
            .onChange(of: locationProvider.currentLocation) { _, location in
                if let location {
                    flowVM.locationUpdated(location)
                }
            }
            .onChange(of: flowVM.state) { _, _ in
                isSheetExpanded = false
            }
        }
    }
}

#Preview {
    ContentView()
}
