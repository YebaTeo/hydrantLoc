import MapKit
import SwiftUI

// App start screen: a full-screen map of available hydrants centered on the
// user's current location, with a floating panel docked at the bottom.
struct HomeView: View {
    @State private var viewModel = HydrantMapViewModel()
    @State private var locationProvider = LocationProvider()

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $viewModel.cameraPosition) {
                ForEach(viewModel.availableHydrants) { hydrant in
                    Annotation(hydrant.title, coordinate: hydrant.coordinate) {
                        HydrantMarker(isUsable: hydrant.isUsable)
                            .accessibilityLabel(hydrant.accessibilityLabel)
                    }
                }

                UserAnnotation()
            }
            .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            .ignoresSafeArea()

            floatingPanel
        }
        .onAppear {
            locationProvider.requestAuthorization()
        }
        .onChange(of: locationProvider.currentLocation) { _, location in
            guard let location else { return }
            viewModel.updateCamera(to: location, span: 0.008)
        }
    }

    // Placeholder floating section, styled like the hydrant detail sheet.
    private var floatingPanel: some View {
        VStack(spacing: 12) {
            Capsule()
                .fill(.secondary)
                .frame(width: 40, height: 5)
                .padding(.top, 8)

            VStack(spacing: 6) {
                Text("Panel")
                    .font(.headline)
                Text("Konten akan ditambahkan di sini.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 8, y: 2)
        .padding(.horizontal)
        .padding(.bottom, 12)
    }
}

#Preview {
    HomeView()
}
