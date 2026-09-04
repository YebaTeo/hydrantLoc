import MapKit
import SwiftUI

struct HomeView: View {
    @State private var viewModel = HydrantMapViewModel()
    @State private var locationProvider = LocationProvider()
    @State private var fireIncidents = FireIncidentStore.load()
    @State private var mapMode: MapMode = .explore
    @State private var hasCenteredOnUser = false
    @State private var shouldFocusOnNextLocation = false
    @State private var showMapModeSheet = false
    @State private var sheetDetent: PresentationDetent = .height(140)

    private var isLocating: Bool {
        !hasCenteredOnUser
        && locationProvider.authorizationStatus != .denied
        && locationProvider.authorizationStatus != .restricted
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Map(position: $viewModel.cameraPosition) {
                ForEach(viewModel.availableHydrants) { hydrant in
                    Annotation(hydrant.title, coordinate: hydrant.coordinate) {
                        HydrantMarker(isUsable: hydrant.isUsable)
                            .accessibilityLabel(hydrant.accessibilityLabel)
                    }
                }

                ForEach(viewModel.fireStations) { station in
                    Annotation(station.title, coordinate: station.coordinate) {
                        FireStationMarker()
                            .accessibilityLabel(station.accessibilityLabel)
                    }
                }

                ForEach(fireIncidents) { incident in
                    Annotation(incident.title, coordinate: incident.coordinate) {
                        FireMarker()
                            .accessibilityLabel("Kebakaran, \(incident.title)")
                    }
                }

                UserAnnotation()
            }
            .mapStyle(mapMode.mapStyle)
            .ignoresSafeArea()

            mapControls
                .padding(.horizontal)
                .padding(.bottom, 152)
        }
        .overlay(alignment: .top) {
            if isLocating {
                locatingIndicator
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onAppear {
            locationProvider.requestAuthorization()
        }
        .onChange(of: locationProvider.currentLocation) { _, location in
            guard let location else { return }
            if !hasCenteredOnUser {
                focus(on: location.coordinate)
                withAnimation(.easeInOut) { hasCenteredOnUser = true }
            } else if shouldFocusOnNextLocation {
                shouldFocusOnNextLocation = false
                focus(on: location.coordinate)
            }
        }
        .sheet(isPresented: .constant(true)) {
            FireListSheet(
                incidents: fireIncidents,
                mapMode: $mapMode,
                showMapModeSheet: $showMapModeSheet,
                onSelect: select
            )
            .presentationDetents([.height(140), .medium, .large], selection: $sheetDetent)
            .presentationDragIndicator(.visible)
            .presentationBackgroundInteraction(.enabled(upThrough: .medium))
            .interactiveDismissDisabled()
        }
    }

    private var locatingIndicator: some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
            Text("Mencari lokasi Anda…")
                .font(.subheadline.weight(.medium))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: Capsule())
        .shadow(radius: 4, y: 2)
        .padding(.top, 8)
    }

    private var mapControls: some View {
        VStack(spacing: 0) {
            Button {
                showMapModeSheet = true
            } label: {
                controlIcon(mapMode.systemImage)
            }
            .accessibilityLabel("Mode peta")

            Divider().frame(width: 44)

            Button(action: focusOnUser) {
                controlIcon("location.fill")
            }
            .accessibilityLabel("Fokus ke lokasi saya")
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 6, y: 2)
    }

    private func controlIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 18, weight: .medium))
            .frame(width: 44, height: 44)
    }

    private func focusOnUser() {
        if let location = locationProvider.currentLocation {
            focus(on: location.coordinate)
        } else {
            shouldFocusOnNextLocation = true
            locationProvider.requestLocation()
        }
    }

    private func select(_ incident: FireIncident) {
        withAnimation { sheetDetent = .height(140) }
        focus(on: incident.coordinate, span: 0.006)
    }

    private func focus(on coordinate: CLLocationCoordinate2D, span: Double = 0.008) {
        withAnimation(.easeInOut(duration: 0.9)) {
            viewModel.cameraPosition = .region(
                MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span)
                )
            )
        }
    }
}

#Preview {
    HomeView()
}
