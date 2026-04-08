import Foundation
import SwiftUI

// MARK: - Sidebar Sections

enum SidebarSection: String, CaseIterable, Identifiable {
    case crewPositions = "Crew Positions"
    case timeline = "Timeline"
    case kisReports = "KIS Reports"
    case settings = "Settings"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .crewPositions: return "person.3.sequence"
        case .timeline: return "calendar.day.timeline.leading"
        case .kisReports: return "doc.text.magnifyingglass"
        case .settings: return "gearshape"
        }
    }

    /// The main feature sections (excludes Settings)
    static var featureSections: [SidebarSection] {
        [.crewPositions, .timeline, .kisReports]
    }
}

// MARK: - Detail Navigation

enum NavigationDestination: Hashable {
    case tripsList
    case crewTable(tripIndex: Int, doPositions: Bool)
}

// MARK: - App State

@Observable
class AppState {
    var selectedSection: SidebarSection = .crewPositions
    var navigationPath = NavigationPath()
    var parsedTrips: [ParsedTrip] = []
    var errorMessage: String?
    var showError = false

    func loadTrips(_ trips: [ParsedTrip]) {
        parsedTrips = trips
        selectedSection = .crewPositions
        navigationPath.append(NavigationDestination.tripsList)
    }

    func selectTrip(at index: Int, doPositions: Bool = true) {
        navigationPath.append(NavigationDestination.crewTable(tripIndex: index, doPositions: doPositions))
    }

    func showError(_ message: String) {
        errorMessage = message
        showError = true
    }

    func reset() {
        parsedTrips = []
        navigationPath = NavigationPath()
    }
}
