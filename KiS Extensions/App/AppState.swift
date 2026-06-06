import Foundation
import SwiftUI

// MARK: - Detail Navigation

enum NavigationDestination: Hashable {
    case tripsList
    case crewTable(tripIndex: Int, doPositions: Bool)
}

// MARK: - App State

@Observable
class AppState {
    /// A mini-app presented over the dashboard. `nil` shows the single-page
    /// dashboard. Set when a feature tile is tapped.
    var openedFeature: FeatureID?

    /// Open a mini-app within the chrome.
    func open(_ feature: FeatureID) {
        openedFeature = feature
    }

    /// Each mini-app owns its own navigation stack so back stacks stay isolated
    var allocatePositionsPath = NavigationPath()
    var flightPlannerPath = NavigationPath()
    var ekCrewRestPath = NavigationPath()
    var dxbAirportPath = NavigationPath()
    var polaroidEvidencePath = NavigationPath()
    var flightCrewChecklistPath = NavigationPath()

    var parsedTrips: [ParsedTrip] = []
    var errorMessage: String?
    var showError = false

    func loadTrips(_ trips: [ParsedTrip]) {
        parsedTrips = trips
        openedFeature = .allocatePositions
        allocatePositionsPath = NavigationPath()
        allocatePositionsPath.append(NavigationDestination.tripsList)
    }

    func selectTrip(at index: Int, doPositions: Bool = true) {
        allocatePositionsPath.append(NavigationDestination.crewTable(tripIndex: index, doPositions: doPositions))
    }

    func showError(_ message: String) {
        errorMessage = message
        showError = true
    }

    func reset() {
        parsedTrips = []
        allocatePositionsPath = NavigationPath()
        flightPlannerPath = NavigationPath()
        ekCrewRestPath = NavigationPath()
        dxbAirportPath = NavigationPath()
        polaroidEvidencePath = NavigationPath()
        flightCrewChecklistPath = NavigationPath()
    }

    /// Return to the dashboard.
    func returnToDashboard() {
        openedFeature = nil
    }
}
