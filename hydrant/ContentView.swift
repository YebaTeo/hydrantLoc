//
//  ContentView.swift
//  hydrant
//
//  Created by Yeba Teo on 18/08/26.
//

import MapKit
import SwiftUI

// Main screen that shows the hydrant map, filters, search, and detail sheet.
struct ContentView: View {
    // Holds all map data and UI state for filtering, selection, and camera position.
    @State private var viewModel = HydrantMapViewModel()

    // Handles Core Location permission and the officer's current location.
    @State private var locationProvider = LocationProvider()

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Displays filtered hydrants as tappable annotations on Apple Maps.
                Map(position: $viewModel.cameraPosition) {
                    ForEach(viewModel.filteredHydrants) { hydrant in
                        Annotation(hydrant.title, coordinate: hydrant.coordinate) {
                            Button {
                                viewModel.select(hydrant)
                            } label: {
                                HydrantMarker(isUsable: hydrant.isUsable)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(hydrant.accessibilityLabel)
                        }
                    }

                    // Shows the user's current location when permission is available.
                    UserAnnotation()
                }
                .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))
                .mapControls {
                    MapCompass()
                    MapScaleView()
                    MapUserLocationButton()
                    MapPitchToggle()
                }
                .ignoresSafeArea(edges: .bottom)

                // Floating summary and filter controls above the map.
                VStack(spacing: 10) {
                    statusBar
                    filterBar
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .navigationTitle("Hidran Jakarta")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Cari wilayah, alamat, atau nama")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    // Requests or refreshes the user's current location.
                    Button {
                        locationProvider.requestLocation()
                    } label: {
                        Image(systemName: "location")
                    }
                    .accessibilityLabel("Perbarui lokasi")

                    // Selects the nearest usable hydrant, or asks for location first.
                    Button {
                        if !viewModel.selectNearestUsableHydrant(from: locationProvider.currentLocation) {
                            locationProvider.requestLocation()
                        }
                    } label: {
                        Image(systemName: "scope")
                    }
                    .accessibilityLabel("Hidran terdekat yang bisa digunakan")
                }
            }
            .sheet(item: $viewModel.selectedHydrant) { hydrant in
                HydrantDetailView(
                    hydrant: hydrant,
                    userLocation: locationProvider.currentLocation,
                    openDirections: { MapsNavigationService.openDirections(to: hydrant) }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .overlay(alignment: .bottom) {
                // Appears when search and filter settings hide every hydrant.
                if viewModel.filteredHydrants.isEmpty {
                    ContentUnavailableView(
                        "Hidran tidak ditemukan",
                        systemImage: "magnifyingglass",
                        description: Text("Ubah pencarian atau filter kondisi.")
                    )
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                    .padding()
                }
            }
            .onAppear {
                locationProvider.requestAuthorization()
            }
            .onChange(of: locationProvider.currentLocation) { _, location in
                guard let location else { return }
                viewModel.updateCamera(to: location)
            }
        }
    }

    // Shows total, usable, and unusable hydrant counts.
    private var statusBar: some View {
        HStack {
            Spacer()
            Spacer()
            Spacer()
            MetricView(value: viewModel.hydrants.count.formatted(), label: "Total")
            Spacer()
            Spacer()
            MetricView(value: viewModel.usableCount.formatted(), label: "Siap")
            Spacer()
            Spacer()
            MetricView(value: viewModel.unusableCount.formatted(), label: "Rusak")
            Spacer()
            Spacer()
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    // Lets the user switch between all, usable, and unusable hydrants.
    private var filterBar: some View {
        Picker("Kondisi", selection: $viewModel.statusFilter) {
            ForEach(HydrantStatusFilter.allCases) { filter in
                Text(filter.title).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .padding(8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    ContentView()
}
