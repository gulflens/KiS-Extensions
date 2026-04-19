import SwiftUI
import SwiftData

// MARK: - Main App View

struct MainAppView: View {
    @Environment(AppState.self) private var appState
    @Query private var settingsArray: [AppSettings]

    private var colorScheme: ColorScheme? {
        switch settingsArray.first?.appearanceMode ?? .light {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }

    var body: some View {
        Group {
            switch appState.selectedSection {
            case .allocatePositions:
                AllocatePositionsApp()
            case .flightPlanner:
                FlightPlannerApp()
            case .ekCrewRest:
                EKCrewRestApp()
            case .dxbAirport:
                DXBAirportApp()
            case .polaroidEvidence:
                PolaroidEvidenceApp()
            case .timeConverter:
                TimeConverterApp()
            case .flightCrewChecklist:
                FlightCrewChecklistApp()
            case .settings:
                SettingsApp()
            case .none:
                DashboardLauncher()
            }
        }
        .preferredColorScheme(colorScheme)
    }
}

// MARK: - Dashboard Launcher

struct DashboardLauncher: View {
    @Environment(AppState.self) private var appState
    @AppStorage("dashboardDestinationCode") private var destinationCode = ""
    @State private var showDestinationPicker = false

    private static let utcDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "EEEE, dd MMM yyyy"
        return f
    }()

    private static let utcTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    private static let dubaiDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeZone = TimeZone(identifier: "Asia/Dubai")
        f.dateFormat = "EEEE, dd MMM yyyy"
        return f
    }()

    private static let dubaiTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeZone = TimeZone(identifier: "Asia/Dubai")
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    private let gridColumns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                HStack(spacing: 24) {
                    dubaiClock
                    utcClock
                    destinationClock
                }
                .padding(.top, 40)

                LazyVGrid(columns: gridColumns, spacing: 16) {
                    ForEach(SidebarSection.allCases) { section in
                        Button {
                            appState.selectedSection = section
                        } label: {
                            DashboardTile(section: section)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
            }
            .frame(maxWidth: 900)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showDestinationPicker) {
            DestinationPickerView(selectedCode: $destinationCode)
        }
    }

    // MARK: - Clock Card

    private func clockCard(
        label: String,
        icon: String,
        accentColor: Color,
        time: String,
        date: String
    ) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.caption2.weight(.semibold))
                Text(label)
                    .font(.caption2.weight(.bold))
                    .tracking(1.5)
            }
            .foregroundStyle(accentColor)

            Text(time)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)

            Text(date)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(width: 200)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(alignment: .top) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(accentColor.opacity(0.25), lineWidth: 1)
        }
    }

    // MARK: - Dubai Clock

    private var dubaiClock: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            clockCard(
                label: "Dubai",
                icon: "building.2",
                accentColor: .orange,
                time: Self.dubaiTimeFormatter.string(from: context.date),
                date: Self.dubaiDateFormatter.string(from: context.date)
            )
        }
    }

    // MARK: - UTC Clock

    private var utcClock: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            clockCard(
                label: "UTC",
                icon: "globe",
                accentColor: .blue,
                time: Self.utcTimeFormatter.string(from: context.date),
                date: Self.utcDateFormatter.string(from: context.date)
            )
        }
    }

    // MARK: - Destination Clock

    private var destinationClock: some View {
        Group {
            if !destinationCode.isEmpty, let tz = StationTimezones.timeZone(for: destinationCode) {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    clockCard(
                        label: StationTimezones.cityName(for: destinationCode) ?? destinationCode,
                        icon: "airplane",
                        accentColor: .green,
                        time: Self.formatTime(context.date, in: tz),
                        date: Self.formatDate(context.date, in: tz)
                    )
                }
            } else {
                emptyDestinationCard
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { showDestinationPicker = true }
    }

    private var emptyDestinationCard: some View {
        VStack(spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: "airplane")
                    .font(.caption2.weight(.semibold))
                Text("Destination")
                    .font(.caption2.weight(.bold))
                    .tracking(1.5)
            }
            .foregroundStyle(.green)

            Image(systemName: "plus.circle")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(.green.opacity(0.5))
                .padding(.vertical, 6)

            Text("Tap to select")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(width: 200)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(alignment: .top) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.green.opacity(0.25), lineWidth: 1)
        }
    }

    private static func formatTime(_ date: Date, in tz: TimeZone) -> String {
        let f = DateFormatter()
        f.timeZone = tz
        f.dateFormat = "HH:mm:ss"
        return f.string(from: date)
    }

    private static func formatDate(_ date: Date, in tz: TimeZone) -> String {
        let f = DateFormatter()
        f.timeZone = tz
        f.dateFormat = "EEEE, dd MMM yyyy"
        return f.string(from: date)
    }
}

// MARK: - Dashboard Tile

struct DashboardTile: View {
    let section: SidebarSection

    private var subtitle: String {
        switch section {
        case .flightPlanner: return "Browse saved trips and sectors"
        case .ekCrewRest: return "Service and rest schedule calculator"
        case .allocatePositions: return "Import trips and assign crew"
        case .dxbAirport: return "Search bays, gates, and lounges"
        case .polaroidEvidence: return "Capture cabin evidence"
        case .timeConverter: return "Convert DXB time to any station"
        case .flightCrewChecklist: return "Plan flight crew calls and briefs"
        case .settings: return "Customize app preferences"
        }
    }

    private var tileGradient: LinearGradient {
        switch section {
        case .flightPlanner:
            return LinearGradient(
                colors: [Color(red: 0.15, green: 0.35, blue: 0.70), Color(red: 0.10, green: 0.25, blue: 0.55)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .ekCrewRest:
            return LinearGradient(
                colors: [Color(red: 0.78, green: 0.14, blue: 0.18), Color(red: 0.55, green: 0.08, blue: 0.12)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .allocatePositions:
            return LinearGradient(
                colors: [Color(red: 0.00, green: 0.45, blue: 0.65), Color(red: 0.00, green: 0.30, blue: 0.50)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .dxbAirport:
            return LinearGradient(
                colors: [Color(red: 0.00, green: 0.18, blue: 0.38), Color(red: 0.00, green: 0.10, blue: 0.25)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .polaroidEvidence:
            return LinearGradient(
                colors: [Color(red: 0.72, green: 0.60, blue: 0.28), Color(red: 0.55, green: 0.45, blue: 0.18)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .timeConverter:
            return LinearGradient(
                colors: [Color(red: 0.40, green: 0.55, blue: 0.30), Color(red: 0.25, green: 0.40, blue: 0.18)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .flightCrewChecklist:
            return LinearGradient(
                colors: [Color(red: 0.40, green: 0.30, blue: 0.65), Color(red: 0.28, green: 0.20, blue: 0.50)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .settings:
            return LinearGradient(
                colors: [Color(red: 0.40, green: 0.40, blue: 0.42), Color(red: 0.28, green: 0.28, blue: 0.30)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 20)

            Image(systemName: section.icon)
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)

            Spacer(minLength: 16)

            VStack(spacing: 4) {
                Text(section.rawValue)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 170)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(tileGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
        .contentShape(Rectangle())
    }
}

// MARK: - Destination Picker

struct DestinationPickerView: View {
    @Binding var selectedCode: String
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private struct RegionGroup: Identifiable {
        let region: String
        let codes: [String]
        var id: String { region }
    }

    private static let allRegions: [RegionGroup] = {
        var grouped: [String: [String]] = [:]
        for code in StationTimezones.allCodes {
            guard let tz = StationTimezones.timeZone(for: code) else { continue }
            let region = tz.identifier.components(separatedBy: "/").first ?? "Other"
            let display: String
            switch region {
            case "America": display = "Americas"
            case "Indian": display = "Indian Ocean"
            default: display = region
            }
            grouped[display, default: []].append(code)
        }
        return grouped
            .map { RegionGroup(region: $0.key, codes: $0.value.sorted()) }
            .sorted { $0.region < $1.region }
    }()

    private var filteredRegions: [RegionGroup] {
        guard !searchText.isEmpty else { return Self.allRegions }
        let query = searchText.uppercased()
        return Self.allRegions.compactMap { group in
            let filtered = group.codes.filter { code in
                code.contains(query) ||
                (StationTimezones.cityName(for: code)?.uppercased().contains(query) ?? false)
            }
            guard !filtered.isEmpty else { return nil }
            return RegionGroup(region: group.region, codes: filtered)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredRegions) { group in
                    Section(group.region) {
                        ForEach(group.codes, id: \.self) { code in
                            Button {
                                selectedCode = code
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    Text(code)
                                        .font(.system(.body, design: .monospaced))
                                        .fontWeight(.medium)
                                    if let city = StationTimezones.cityName(for: code) {
                                        Text(city)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if code == selectedCode {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.green)
                                            .fontWeight(.semibold)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search by code or city")
            .navigationTitle("Select Destination")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear") {
                        selectedCode = ""
                        dismiss()
                    }
                    .disabled(selectedCode.isEmpty)
                }
            }
        }
    }
}
