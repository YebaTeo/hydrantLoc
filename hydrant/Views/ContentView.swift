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
    @State private var locationProvider = LocationProvider()

    // Connects the custom MapKit controls to this map instance.
    @Namespace private var mapScope

    // Whether the controller sheet is expanded. Auto-expands for the passcode step
    // (its keypad is tall) and collapses back on return to the list.
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
                    mapScope: mapScope,
                    onSelectIncident: { incident in
                        mapViewModel.selectedHydrant = nil
                        flowVM.openIncident(
                            incident,
                            firefighterLocation: locationProvider.currentLocation
                        )
                    },
                    onSelectHydrant: { hydrant in
                        if flowVM.selectedIncident != nil {
                            flowVM.selectHydrant(
                                hydrant,
                                firefighterLocation: locationProvider.currentLocation
                            )
                        } else {
                            mapViewModel.selectedHydrant = hydrant
                        }
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
                        locationProvider: locationProvider,
                        isExpanded: isSheetExpanded
                    )
                }
            }
            .mapScope(mapScope)
            .navigationTitle("Hidran Jakarta")
            .navigationBarTitleDisplayMode(.inline)
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
            .onChange(of: locationProvider.currentLocation) { _, location in
                if let location {
                    flowVM.locationUpdated(location)
                }
            }
            .onChange(of: flowVM.state) { _, _ in
                // Expand only for the tall passcode keypad; every other state uses the
                // compact height so the map (and the center pin) stay visible.
                isSheetExpanded = flowVM.isAuthorizing
            }
        }
    }
}

#Preview {
    ContentView()
}
