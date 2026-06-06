import SwiftUI
import SwiftData

// MARK: - Flight Planner Destination

/// Hashable destinations supported by the Flight Planner navigation stack.
/// Used for deep-linking from outside the mini-app (e.g. the dashboard's
/// trip popup pushing the user straight into trip edit).
enum FlightPlannerDestination: Hashable {
    case editTrip(UUID)
}

// MARK: - Flight Planner Mini-App

/// Read-only lens over SavedTrip data. Does not import or delete trips.
struct FlightPlannerApp: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState

        NavigationStack(path: $appState.flightPlannerPath) {
            FlightPlannerHomeView()
                .navigationDestination(for: FlightPlannerDestination.self) { destination in
                    switch destination {
                    case .editTrip(let id):
                        EditTripLookupView(flightID: id)
                    }
                }
        }
    }
}

// MARK: - Edit Trip Lookup

/// Loads a `PlannedFlight` by id from SwiftData and presents `AddTripView`
/// in edit mode. Falls back to a "not found" message if the flight has been
/// deleted between the time the destination was pushed and resolved.
private struct EditTripLookupView: View {
    let flightID: UUID
    @Query private var flights: [PlannedFlight]

    var body: some View {
        if let flight = flights.first(where: { $0.id == flightID }) {
            AddTripView(flightToEdit: flight)
        } else {
            ContentUnavailableView(
                "Trip Not Found",
                systemImage: "exclamationmark.triangle",
                description: Text("This trip may have been deleted.")
            )
        }
    }
}
