//
//  IncidentLocationSheet.swift
//  hydrant
//
//  Created by Yeba Teo on 26/08/26.
//

import CoreLocation
import MapKit
import SwiftUI

struct IncidentLocationSheet: View {
    let onSelectCoordinate: (CLLocationCoordinate2D) -> Void
    let onPinpointOnMap: () -> Void

    @State private var searchService = IncidentSearchService()
    @State private var errorMessage: String?
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    searchField
                    searchContent
                    Divider()
                    pinpointButton
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("Incident Location")
            .navigationBarTitleDisplayMode(.inline)
            .alert(
                "Unable to Find Location",
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { isPresented in
                        if !isPresented {
                            errorMessage = nil
                        }
                    }
                )
            ) {
                Button("OK", role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "Try another address or pinpoint the incident on the map.")
            }
            .onAppear {
                isSearchFocused = true
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search or enter address...", text: $searchService.query)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .focused($isSearchFocused)
            if searchService.isSearching {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private var searchContent: some View {
        if searchService.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Text("Enter the incident address or choose Pinpoint on Map.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
        } else if searchService.completions.isEmpty && !searchService.isSearching {
            ContentUnavailableView(
                "No Suggestions",
                systemImage: "magnifyingglass",
                description: Text("Try another address or pinpoint the incident on the map.")
            )
            .padding(.vertical, 16)
        } else {
            VStack(spacing: 0) {
                ForEach(searchService.completions, id: \.self) { completion in
                    Button {
                        resolve(completion)
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(completion.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                            if !completion.subtitle.isEmpty {
                                Text(completion.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if completion != searchService.completions.last {
                        Divider()
                    }
                }
            }
        }
    }

    private var pinpointButton: some View {
        Button {
            isSearchFocused = false
            onPinpointOnMap()
        } label: {
            Label("Pinpoint on Map", systemImage: "mappin.and.ellipse")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
    }

    private func resolve(_ completion: MKLocalSearchCompletion) {
        isSearchFocused = false
        Task {
            do {
                let coordinate = try await searchService.resolve(completion)
                onSelectCoordinate(coordinate)
            } catch {
                print("❌ INCIDENT SEARCH RESOLVE FAILED:", error)
                errorMessage = "Try another address or pinpoint the incident on the map."
            }
        }
    }
}

#Preview {
    IncidentLocationSheet(
        onSelectCoordinate: { _ in },
        onPinpointOnMap: {}
    )
}
