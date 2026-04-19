import Foundation
import SwiftUI

// MARK: - Sidebar Sections

enum SidebarSection: String, CaseIterable, Identifiable {
    case flightPlanner = "Flight Planner"
    case ekCrewRest = "EK Crew Rest"
    case allocatePositions = "Allocate Positions"
    case dxbAirport = "DXB Airport"
    case polaroidEvidence = "Polaroid Evidence"
    case timeConverter = "Time Converter"
    case flightCrewChecklist = "Flight Crew Checklist"
    case settings = "Settings"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .allocatePositions: return "person.3.sequence"
        case .flightPlanner: return "calendar.day.timeline.leading"
        case .ekCrewRest: return "bed.double"
        case .dxbAirport: return "airplane.departure"
        case .polaroidEvidence: return "camera.viewfinder"
        case .timeConverter: return "clock.arrow.2.circlepath"
        case .flightCrewChecklist: return "phone.connection"
        case .settings: return "gearshape"
        }
    }

    /// Per-icon font size tuned so all sidebar icons appear the same visual weight
    var iconSize: CGFloat {
        switch self {
        case .allocatePositions: return 14
        case .flightPlanner: return 16
        case .ekCrewRest: return 16
        case .dxbAirport: return 16
        case .polaroidEvidence: return 16
        case .timeConverter: return 16
        case .flightCrewChecklist: return 16
        case .settings: return 18
        }
    }

    /// The main feature sections (excludes Settings)
    static var featureSections: [SidebarSection] {
        [.flightPlanner, .ekCrewRest, .allocatePositions, .dxbAirport, .polaroidEvidence, .timeConverter, .flightCrewChecklist]
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
    /// nil = dashboard launcher is visible; non-nil = that mini-app is active
    var selectedSection: SidebarSection? = nil

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
        selectedSection = .allocatePositions
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

    /// Return to the dashboard launcher
    func returnToDashboard() {
        selectedSection = nil
    }
}
