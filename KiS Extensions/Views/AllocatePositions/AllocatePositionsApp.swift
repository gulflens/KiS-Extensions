import SwiftUI

// MARK: - Allocate Positions Mini-App

/// Self-contained mini-app that owns trip import, crew allocation, and
/// trip/crew navigation. Runs inside its own NavigationStack so its back
/// stack is isolated from other mini-apps.
struct AllocatePositionsApp: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState

        NavigationStack(path: $appState.allocatePositionsPath) {
            DashboardView()
                .navigationDestination(for: NavigationDestination.self) { destination in
                    switch destination {
                    case .tripsList:
                        TripsListView()
                    case .crewTable(let tripIndex, let doPositions):
                        if tripIndex < appState.parsedTrips.count {
                            CrewTableView(trip: appState.parsedTrips[tripIndex], doPositions: doPositions)
                        }
                    }
                }
        }
    }
}
