//
//  IncidentFlowState.swift
//  hydrant
//

import Foundation

// The single source of truth for which step of the incident workflow is active.
// Replaces the tangle of boolean @State flags that ContentView used to juggle.
enum IncidentFlowState: Equatable {
    // Default: the controller sheet lists existing incident reports.
    case list
    // Passcode entry, either to add a new incident or to remove the selected one.
    case authorizing(purpose: AuthPurpose)
    // Fixed center pin: the user pans the map underneath to aim the new incident.
    case placingPin
    // A selected incident is open; ranked hydrant recommendations are shown.
    case incidentDetail
    // A driving route to the selected hydrant is drawn on the map.
    case routing
}

// Distinguishes the two moments the passcode gate is used.
enum AuthPurpose: Equatable {
    case start
    case end
}
