import SwiftUI

// MARK: - DXB Airport Home

struct DXBAirportHomeView: View {
    @Environment(DXBDataStore.self) private var dataStore
    @State private var query: String = ""
    @State private var selectedBay: Bay?
    @State private var selectedZone: Concourse?

    private var concourseColor: (Concourse) -> Color = { concourse in
        switch concourse {
        case .A: return Color(red: 0.15, green: 0.35, blue: 0.70)
        case .B: return Color(red: 0.10, green: 0.55, blue: 0.42)
        case .C: return Color(red: 0.75, green: 0.45, blue: 0.10)
        case .D: return Color(red: 0.50, green: 0.25, blue: 0.65)   // T1 — purple
        case .F: return Color(red: 0.45, green: 0.45, blue: 0.50)   // T2 — slate
        case .G: return Color(red: 0.55, green: 0.40, blue: 0.20)   // Apron G — bronze
        case .E: return Color(red: 0.10, green: 0.45, blue: 0.55)   // Apron E — teal
        case .H: return Color(red: 0.70, green: 0.55, blue: 0.10)   // Apron H — royal gold
        case .Q: return Color(red: 0.55, green: 0.20, blue: 0.20)   // Apron Q — maintenance red
        case .S: return Color(red: 0.40, green: 0.40, blue: 0.40)   // Apron S — neutral gray
        }
    }

    // MARK: Derived data

    /// All bays grouped by zone, in Concourse.allCases order, non-empty only.
    private var allGroups: [(concourse: Concourse, bays: [Bay])] {
        dataStore.grouped(dataStore.catalog.bays)
    }

    /// Search hits flattened across every zone (used when query is non-empty).
    private var searchResults: [Bay] {
        dataStore.search(query)
    }

    /// Bays in the currently-selected zone.
    private var selectedZoneBays: [Bay] {
        guard let zone = selectedZone else { return [] }
        return allGroups.first(where: { $0.concourse == zone })?.bays ?? []
    }

    private var totalBayCount: Int {
        dataStore.catalog.bays.count
    }

    // MARK: Body

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                featureCardsRow
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                browseSection
            }
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("DXB Airport")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $query,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search bay, gate, or old gate"
        )
        .textInputAutocapitalization(.characters)
        .autocorrectionDisabled()
        .onChange(of: query) { _, newValue in
            // Active search overrides any zone filter so results are
            // always global until the search is cleared.
            if !newValue.isEmpty { selectedZone = nil }
        }
        .sheet(item: $selectedBay) { bay in
            BayDetailSheet(bay: bay)
        }
        .navigationDestination(for: DXBAirportRoute.self) { route in
            Group {
                switch route {
                case .lounges:
                    LoungesListView()
                case .routePlanner:
                    RoutePlannerView()
                case .map(let plannedRoute):
                    DXBSchematicMapView(route: plannedRoute)
                }
            }
            // Single back affordance lives in the app top bar.
            .navigationBarBackButtonHidden(true)
        }
    }

    // MARK: - Browse section (the only thing that switches on state)

    @ViewBuilder
    private var browseSection: some View {
        if !query.isEmpty {
            searchResultsView
        } else if let zone = selectedZone {
            zoneDetailView(zone)
        } else {
            zoneGridView
        }
    }

    // MARK: - Zone grid (default view)

    private var zoneGridView: some View {
        let columns = Array(
            repeating: GridItem(.flexible(), spacing: 10),
            count: 4
        )
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Browse by zone")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(totalBayCount) bays")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .padding(.horizontal, 16)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(allGroups, id: \.concourse) { group in
                    Button {
                        selectedZone = group.concourse
                    } label: {
                        zoneTile(group.concourse, count: group.bays.count)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func zoneTile(_ zone: Concourse, count: Int) -> some View {
        let color = concourseColor(zone)
        return VStack(spacing: 4) {
            Text(zone.rawValue)
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundStyle(color)

            Text(zone.compactName)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text("\(count)")
                .font(.caption.weight(.bold))
                .foregroundStyle(color)
                .monospacedDigit()
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(color.opacity(0.12), in: Capsule())
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(color.opacity(0.20), lineWidth: 1)
        )
    }

    // MARK: - Zone detail (drilled-in view)

    private func zoneDetailView(_ zone: Concourse) -> some View {
        let bays = selectedZoneBays
        return VStack(spacing: 12) {
            HStack {
                Button {
                    selectedZone = nil
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.subheadline.weight(.bold))
                        Text("All zones")
                            .font(.subheadline.weight(.semibold))
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(concourseColor(zone))
                Spacer()
            }
            .padding(.horizontal, 16)

            zoneDetailHeader(zone, count: bays.count)
                .padding(.horizontal, 16)

            LazyVStack(spacing: 8) {
                ForEach(bays) { bay in
                    Button {
                        selectedBay = bay
                    } label: {
                        BayRowView(bay: bay)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func zoneDetailHeader(_ zone: Concourse, count: Int) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(concourseColor(zone))
                .frame(width: 5, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(zone.displayName)
                    .font(.title2.weight(.bold))
                Text(zone.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(count)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(concourseColor(zone))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(concourseColor(zone).opacity(0.12), in: Capsule())
        }
    }

    // MARK: - Search results (search query non-empty)

    private var searchResultsView: some View {
        let results = searchResults
        return VStack(spacing: 10) {
            HStack {
                Text("\(results.count) result\(results.count == 1 ? "" : "s")")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                Spacer()
            }
            .padding(.horizontal, 16)

            if results.isEmpty {
                ContentUnavailableView(
                    "No matching bay or gate",
                    systemImage: "magnifyingglass",
                    description: Text("Try a bay id (A06), a gate id (A24), or an old gate number (217).")
                )
                .padding(.top, 40)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(results) { bay in
                        Button {
                            selectedBay = bay
                        } label: {
                            BayRowView(bay: bay)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Feature Cards Row

    private var featureCardsRow: some View {
        HStack(spacing: 12) {
            NavigationLink(value: DXBAirportRoute.map(route: nil)) {
                featureCard(
                    icon: "map.fill",
                    title: "Airport Map",
                    subtitle: "Concourses and gates",
                    gradient: LinearGradient(
                        colors: [Color(red: 0.00, green: 0.55, blue: 0.55), Color(red: 0.00, green: 0.40, blue: 0.45)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
            }
            .buttonStyle(.plain)

            NavigationLink(value: DXBAirportRoute.lounges) {
                featureCard(
                    icon: "cup.and.saucer.fill",
                    title: "Lounges",
                    subtitle: "\(dataStore.lounges.count) across A, B, C",
                    gradient: LinearGradient(
                        colors: [Color(red: 0.72, green: 0.60, blue: 0.15), Color(red: 0.55, green: 0.42, blue: 0.10)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
            }
            .buttonStyle(.plain)

            NavigationLink(value: DXBAirportRoute.routePlanner) {
                featureCard(
                    icon: "point.topleft.down.to.point.bottomright.curvepath.fill",
                    title: "Route Planner",
                    subtitle: "Gate-to-gate transit",
                    gradient: LinearGradient(
                        colors: [Color(red: 0.00, green: 0.18, blue: 0.50), Color(red: 0.00, green: 0.12, blue: 0.35)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Feature Card

    private func featureCard(
        icon: String,
        title: String,
        subtitle: String,
        gradient: LinearGradient
    ) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)

            VStack(spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(gradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Routing

enum DXBAirportRoute: Hashable {
    case lounges
    case routePlanner
    case map(route: PlannedRoute?)
}
