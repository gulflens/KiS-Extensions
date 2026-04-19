import SwiftUI

// MARK: - Flight Planner Mini-App

/// Read-only lens over SavedTrip data. Does not import or delete trips.
struct FlightPlannerApp: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState

        NavigationStack(path: $appState.flightPlannerPath) {
            FlightPlannerHomeView()
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
