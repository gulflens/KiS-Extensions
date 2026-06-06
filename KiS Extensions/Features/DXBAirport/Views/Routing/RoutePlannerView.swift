import SwiftUI

// MARK: - Route Planner View

/// Gate-to-gate routing UI. Origin and destination are picked via sheets that
/// reuse the home-screen bay search. APM mode and boarding-time inputs feed
/// the verdict. Walking-edge times are placeholders pending field measurement
/// (see Documentation/DXBAirport/GAPS.md).
struct RoutePlannerView: View {
    @Environment(DXBDataStore.self) private var dataStore

    @State private var origin: Bay?
    @State private var destination: Bay?
    @State private var apmMode: APMMode = .peak
    @State private var boardingMinutes: Int = 45
    @State private var showOriginPicker = false
    @State private var showDestPicker = false

    private var route: PlannedRoute? {
        guard let origin, let destination else { return nil }
        return dataStore.routeEngine.plan(
            origin: origin,
            destination: destination,
            apmMode: apmMode,
            boardingMinutes: boardingMinutes
        )
    }

    var body: some View {
        Form {
            inputsSection
            settingsSection

            if let route {
                routeSection(route)
                verdictSection(route)
                mapSection(route)
            }

            disclaimerSection
        }
        .navigationTitle("Plan a route")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showOriginPicker) {
            BayPickerSheet(title: "From") { bay in
                origin = bay
            }
        }
        .sheet(isPresented: $showDestPicker) {
            BayPickerSheet(title: "To") { bay in
                destination = bay
            }
        }
    }

    // MARK: - Inputs

    private var inputsSection: some View {
        Section("Route") {
            pickerRow(
                label: "From",
                bay: origin,
                placeholder: "Select origin gate",
                action: { showOriginPicker = true }
            )
            pickerRow(
                label: "To",
                bay: destination,
                placeholder: "Select destination gate",
                action: { showDestPicker = true }
            )
        }
    }

    private func pickerRow(label: String, bay: Bay?, placeholder: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .foregroundStyle(.secondary)
                Spacer()
                if let bay {
                    Text(bay.displayLabel)
                        .foregroundStyle(.primary)
                } else {
                    Text(placeholder)
                        .foregroundStyle(.tertiary)
                }
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Settings

    private var settingsSection: some View {
        Section("Settings") {
            Picker("APM frequency", selection: $apmMode) {
                ForEach(APMMode.allCases, id: \.self) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Stepper(
                value: $boardingMinutes,
                in: 5...120,
                step: 5
            ) {
                HStack {
                    Text("Boarding in")
                    Spacer()
                    Text("\(boardingMinutes) min")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Route segments

    private func routeSection(_ route: PlannedRoute) -> some View {
        Section("Segments") {
            ForEach(route.segments) { segment in
                RouteSegmentRow(segment: segment)
            }
        }
    }

    // MARK: - Verdict

    private func verdictSection(_ route: PlannedRoute) -> some View {
        Section("Verdict") {
            RouteVerdictView(verdict: route.verdict, totalSeconds: route.totalSeconds)
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                .listRowBackground(Color.clear)
        }
    }

    // MARK: - Map link

    private func mapSection(_ route: PlannedRoute) -> some View {
        Section {
            NavigationLink(value: DXBAirportRoute.map(route: route)) {
                HStack {
                    Image(systemName: "map")
                        .foregroundStyle(.teal)
                    Text("View on map")
                    Spacer()
                }
            }
        }
    }

    // MARK: - Disclaimer

    private var disclaimerSection: some View {
        Section {
            Label {
                Text("Walking-edge times are placeholders pending field measurement (see Documentation/DXBAirport/GAPS.md).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } icon: {
                Image(systemName: "ruler")
                    .foregroundStyle(.orange)
            }
        }
    }
}
