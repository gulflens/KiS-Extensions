import SwiftUI
import SwiftData

// MARK: - Dashboard Home View

/// The operational command center. Replaces the legacy tile launcher.
/// Navigation-agnostic: opening a mini-app is delegated through `onOpen`.
struct DashboardHomeView: View {

    /// Invoked when the crew opens a mini-app from a card.
    var onOpen: (FeatureID) -> Void
    /// Invoked when the crew taps the Add Trip tile → Import from Portal.
    var onImportPortal: () -> Void
    /// Invoked when the crew taps the Add Trip tile → Add manually.
    var onAddManually: () -> Void
    /// Optional content rendered as the first row inside the scroll view.
    /// Used to let the day calendar strip scroll with content when unpinned;
    /// `nil` when the strip is pinned above the dashboard instead.
    var scrollingHeader: AnyView? = nil

    // MARK: Environment & State

    @Environment(\.horizontalSizeClass) private var sizeClass
    @AppStorage("dashboardDestinationCode") private var destinationCode = ""
    @AppStorage("dashboardDestinationCode2") private var destinationCode2 = ""
    @State private var editingSlot: DestinationSlot?

    /// Identifies which destination clock the picker is editing.
    private struct DestinationSlot: Identifiable { let id: Int }

    // MARK: Queries

    @Query private var sectors: [PlannedSector]
    @Query private var plannedFlights: [PlannedFlight]
    @Query private var savedTrips: [SavedTrip]

    // MARK: Derived

    private var isRegular: Bool { sizeClass == .regular }

    private var heroFlight: OperationalHeroCard.Flight? {
        DashboardFlightResolver.resolveHero(sectors: sectors)
    }

    private var rotation: OperationalContext.Rotation? {
        OperationalContext.rotation(sectors: sectors)
    }

    private var monthSummary: OperationalContext.MonthSummary {
        OperationalContext.monthSummary(sectors: sectors)
    }

    // MARK: Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xxl) {
                if let scrollingHeader { scrollingHeader }
                clocksRow
                mainZone
                featuresSection
                rotationSection
                monthSection
            }
            .padding(.horizontal, isRegular ? AppSpacing.xxxl : AppSpacing.lg)
            .padding(.vertical, AppSpacing.xxl)
            .frame(maxWidth: 1180)
            .frame(maxWidth: .infinity)
        }
        .background(AppColor.background)
        .sheet(item: $editingSlot) { slot in
            DestinationPickerView(selectedCode: slot.id == 1 ? $destinationCode : $destinationCode2)
        }
    }

    // MARK: - Clocks Row

    private var clocksRow: some View {
        HStack(alignment: .top, spacing: AppSpacing.lg) {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                ClockCard(label: "Dubai", systemImage: "building.2",
                          accent: AppColor.gold,
                          time: Self.timeString(context.date, Self.dubaiTZ),
                          date: Self.dateString(context.date, Self.dubaiTZ),
                          isNight: Self.isNight(context.date, Self.dubaiTZ))
            }
            TimelineView(.periodic(from: .now, by: 1)) { context in
                ClockCard(label: "UTC", systemImage: "globe",
                          accent: AppColor.info,
                          time: Self.timeString(context.date, Self.utcTZ),
                          date: Self.dateString(context.date, Self.utcTZ),
                          isNight: Self.isNight(context.date, Self.utcTZ))
            }
            destinationClock(code: destinationCode, slot: 1, accent: AppColor.positive)
            destinationClock(code: destinationCode2, slot: 2, accent: AppColor.warning)
        }
    }

    /// One of the two selectable destination clocks. Shows the prompt state
    /// when `code` is empty; tapping opens the picker bound to `slot`.
    private func destinationClock(code: String, slot: Int, accent: Color) -> some View {
        Group {
            if !code.isEmpty,
               let tz = StationTimezones.timeZone(for: code) {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    ClockCard(label: code,
                              systemImage: "airplane",
                              accent: accent,
                              time: Self.timeString(context.date, tz),
                              date: Self.dateString(context.date, tz),
                              isNight: Self.isNight(context.date, tz))
                }
            } else {
                ClockCard(label: "Destination", systemImage: "airplane",
                          accent: accent, promptText: "Tap to select")
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { editingSlot = DestinationSlot(id: slot) }
    }

    // MARK: - Main Zone

    @ViewBuilder
    private var mainZone: some View {
        OperationalHeroCard(flight: heroFlight)
            .frame(maxWidth: .infinity)
    }

    // MARK: - Features

    /// Every mini-app, presented as tiles. The dashboard entry is skipped
    /// since this view is the dashboard; Flight Planner, Allocate Positions,
    /// Time Converter, DXB Airport and Settings are skipped since they live in
    /// the bottom toolbar.
    private var featureModules: [FeatureModule] {
        let hidden: Set<FeatureID> = [.dashboard, .flightPlanner, .allocatePositions, .timeConverter, .dxbAirport, .settings]
        return FeatureRegistry.modules.filter { !hidden.contains($0.id) }
    }

    private var featureColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: AppSpacing.lg),
              count: isRegular ? 3 : 2)
    }

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(title: "Features", systemImage: "square.grid.2x2")
            LazyVGrid(columns: featureColumns, spacing: AppSpacing.lg) {
                AddTripTile(onImportPortal: onImportPortal,
                            onAddManually: onAddManually)
                ForEach(featureModules) { module in
                    DashboardCard(
                        title: module.title,
                        description: module.summary,
                        systemImage: module.icon,
                        accent: AppColor.accent(for: module.id),
                        action: { onOpen(module.id) }
                    )
                }
            }
        }
    }

    // MARK: - Rotation

    @ViewBuilder
    private var rotationSection: some View {
        if let rotation, rotation.steps.count > 1 {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                SectionHeader(title: "Rotation Overview", systemImage: "point.topleft.down.to.point.bottomright.curvepath",
                              trailingText: rotation.title)
                RotationStrip(rotation: rotation)
                    .padding(AppSpacing.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .dashboardCard()
            }
        }
    }

    // MARK: - This Month

    private var monthSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(title: "This Month", systemImage: "chart.bar",
                          trailingText: monthSummary.monthLabel)
            MonthOverviewStats(summary: monthSummary, isRegular: isRegular)
        }
    }

    // MARK: - Time Formatting

    private static let dubaiTZ = TimeZone(identifier: "Asia/Dubai")!
    private static let utcTZ = TimeZone(identifier: "UTC")!

    private static func timeString(_ date: Date, _ tz: TimeZone) -> String {
        let f = DateFormatter()
        f.timeZone = tz
        f.dateFormat = "HH:mm:ss"
        return f.string(from: date)
    }

    private static func dateString(_ date: Date, _ tz: TimeZone) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_GB")
        f.timeZone = tz
        f.dateFormat = "EEEE, dd MMM yyyy"
        return f.string(from: date)
    }

    /// Night-time approximation for a location given only its timezone:
    /// dark from 18:00 up to 06:00 local. Mirrors the Apple Clock list, which
    /// renders night-time cities dark.
    private static func isNight(_ date: Date, _ tz: TimeZone) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = tz
        let hour = calendar.component(.hour, from: date)
        return hour < 6 || hour >= 18
    }
}
