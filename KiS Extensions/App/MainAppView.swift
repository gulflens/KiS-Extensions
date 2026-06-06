import SwiftUI
import SwiftData

// MARK: - Main App View

/// Root of the app. A single-page dashboard hosting every feature as a tile.
/// On the dashboard, the day strip sits at the top of the chrome and the
/// floating quick-access capsule sits in the bottom safe area. When a mini-app
/// is opened, the dashboard chrome is replaced with a minimal back-button bar.
struct MainAppView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Query private var settingsArray: [AppSettings]

    private var isRegular: Bool { sizeClass == .regular }

    private var colorScheme: ColorScheme? {
        switch settingsArray.first?.appearanceMode ?? .light {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }

    @State private var showPortalImport = false
    @State private var showAddTrip = false

    var body: some View {
        VStack(spacing: 0) {
            if let opened = appState.openedFeature {
                AppTopBar(
                    featureTitle: FeatureRegistry.module(for: opened).title,
                    onBack: { appState.openedFeature = nil }
                )
                rootView(for: opened)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Calendar strip is always pinned above the dashboard.
                // zIndex lifts the bar's bottom shadow over the dashboard.
                calendarStripBar
                    .zIndex(1)

                dashboardHome(header: nil)
            }
        }
        .background(AppColor.background)
        .tint(AppColor.navyAccent)
        .preferredColorScheme(colorScheme)
        .fullScreenCover(isPresented: $showPortalImport) {
            PortalBrowserView()
        }
        .sheet(isPresented: $showAddTrip) {
            NavigationStack {
                AddTripView()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showAddTrip = false }
                        }
                    }
            }
        }
    }

    // MARK: - Dashboard Chrome

    /// The day calendar strip, wired to open Flight Planner. Built once and
    /// placed either above the dashboard (pinned) or inside its scroll view
    /// as a header (unpinned).
    private var calendarStrip: DayCalendarStrip {
        DayCalendarStrip(
            onOpenSector: { _ in appState.open(.flightPlanner) },
            onEditTrip: { flight in
                var path = NavigationPath()
                path.append(FlightPlannerDestination.editTrip(flight.id))
                appState.flightPlannerPath = path
                appState.open(.flightPlanner)
            }
        )
    }

    /// The calendar strip as a full-width white band across the top of the
    /// dashboard, with a bottom drop shadow. The white background spans edge to
    /// edge while the strip content is centered and inset to match the
    /// dashboard's framing. Used identically whether pinned above the dashboard
    /// or carried as its scrolling header, so toggling never moves the strip.
    private var calendarStripBar: some View {
        calendarStrip
            .padding(.horizontal, isRegular ? AppSpacing.xxxl : AppSpacing.lg)
            .padding(.top, AppSpacing.sm)
            .padding(.bottom, AppSpacing.sm)
            .frame(maxWidth: 1180)
            .frame(maxWidth: .infinity)
            .background(AppColor.surface)
            .shadow(color: .black.opacity(0.18), radius: 14, x: 0, y: 7)
    }

    /// The dashboard plus its floating quick-access capsule. `header` carries
    /// the calendar strip into the scroll view when the strip is unpinned.
    private func dashboardHome(header: AnyView?) -> some View {
        DashboardHomeView(
            onOpen: { appState.open($0) },
            onImportPortal: { showPortalImport = true },
            onAddManually: { showAddTrip = true },
            scrollingHeader: header
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            QuickAccessCapsule(
                onOpen: { appState.open($0) }
            )
        }
    }

    // MARK: - Feature Root Views

    /// Type-safe root view for each feature. Keeps `FeatureRegistry` free of
    /// view imports while staying the single place a feature is wired in.
    @ViewBuilder
    private func rootView(for id: FeatureID) -> some View {
        switch id {
        case .dashboard:           DashboardHomeView(onOpen: { appState.open($0) },
                                                     onImportPortal: { showPortalImport = true },
                                                     onAddManually: { showAddTrip = true })
        case .flightPlanner:       FlightPlannerApp()
        case .ekCrewRest:          EKCrewRestApp()
        case .allocatePositions:   AllocatePositionsApp()
        case .timeConverter:       TimeConverterApp()
        case .dxbAirport:          DXBAirportApp()
        case .polaroidEvidence:    PolaroidEvidenceApp()
        case .flightCrewChecklist: FlightCrewChecklistApp()
        case .settings:            SettingsApp()
        }
    }
}
