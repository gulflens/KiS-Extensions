import SwiftUI

// MARK: - Flight Crew Checklist Mini-App

/// Standalone calculator for flight-crew call timing. Owns its own
/// NavigationStack so its back stack stays isolated from other mini-apps.
struct FlightCrewChecklistApp: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState

        NavigationStack(path: $appState.flightCrewChecklistPath) {
            FlightCrewChecklistView()
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            appState.returnToDashboard()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "square.grid.2x2")
                                Text("Dashboard")
                            }
                        }
                    }
                }
        }
    }
}
