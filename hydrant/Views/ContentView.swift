//
//  ContentView.swift
//  hydrant
//
//  Created by Yeba Teo on 18/08/26.
//

import MapKit
import SwiftUI

// Map screen with hydrant filters, search, and a detail sheet.
struct ContentView: View {
    @State private var viewModel = HydrantMapViewModel()
    @State private var locationProvider = LocationProvider()

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
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
                    Button {
                        locationProvider.requestLocation()
                    } label: {
                        Image(systemName: "location")
                    }
                    .accessibilityLabel("Perbarui lokasi")

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
