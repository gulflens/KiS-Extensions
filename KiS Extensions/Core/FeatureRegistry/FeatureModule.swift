import SwiftUI

// MARK: - Feature Identity

/// Stable identity for every top-level destination, including the dashboard
/// root and Settings. Single source of truth — replaces the former parallel
/// `SidebarSection` and `AppTab` enums.
enum FeatureID: String, CaseIterable, Identifiable, Hashable {
    case dashboard
    case flightPlanner
    case ekCrewRest
    case allocatePositions
    case timeConverter
    case dxbAirport
    case polaroidEvidence
    case flightCrewChecklist
    case settings

    var id: String { rawValue }
}

// MARK: - Feature Group

/// Where a feature sits in the adaptive navigation.
enum FeatureGroup {
    case primary      // dashboard — standalone, top
    case operations   // grouped under "Operations"
    case utilities    // grouped under "Utilities"
    case settings     // standalone, bottom
}

// MARK: - Feature Module

/// Navigation descriptor for one feature. View-agnostic: root views are built
/// type-safely in `MainAppView`, so the registry never imports feature views.
struct FeatureModule: Identifiable {
    let id: FeatureID
    let title: String
    let summary: String   // dashboard card copy
    let icon: String
    let group: FeatureGroup
}

// MARK: - Feature Registry

/// Ordered, single source of truth for all features. Adding a mini-app is one
/// entry here plus a case in `MainAppView.rootView(for:)`.
enum FeatureRegistry {
    static let modules: [FeatureModule] = [
        .init(id: .dashboard,           title: "Dashboard",
              summary: "Operational overview",
              icon: "square.grid.2x2",                 group: .primary),
        .init(id: .flightPlanner,       title: "Flight Planner",
              summary: "Browse saved trips and sectors",
              icon: "calendar.day.timeline.leading",   group: .operations),
        .init(id: .ekCrewRest,          title: "EK Crew Rest",
              summary: "Service and rest schedule calculator",
              icon: "bed.double",                      group: .operations),
        .init(id: .allocatePositions,   title: "Allocate Positions",
              summary: "Import trips and assign crew",
              icon: "person.3.sequence",               group: .operations),
        .init(id: .timeConverter,       title: "Time Converter",
              summary: "Convert DXB time to any station",
              icon: "clock.arrow.2.circlepath",        group: .operations),
        .init(id: .dxbAirport,          title: "DXB Airport",
              summary: "Search bays, gates, and lounges",
              icon: "airplane.departure",              group: .utilities),
        .init(id: .polaroidEvidence,    title: "Polaroid Evidence",
              summary: "Capture cabin evidence",
              icon: "camera.viewfinder",               group: .utilities),
        .init(id: .flightCrewChecklist, title: "Flight Crew Checklist",
              summary: "Plan flight crew calls and briefs",
              icon: "phone.connection",                group: .utilities),
        .init(id: .settings,            title: "Settings",
              summary: "Customize app preferences",
              icon: "gearshape",                       group: .settings),
    ]

    /// The registry is exhaustive over `FeatureID`, so this never returns nil.
    static func module(for id: FeatureID) -> FeatureModule {
        modules.first { $0.id == id } ?? modules[0]
    }

    static func modules(in group: FeatureGroup) -> [FeatureModule] {
        modules.filter { $0.group == group }
    }
}
