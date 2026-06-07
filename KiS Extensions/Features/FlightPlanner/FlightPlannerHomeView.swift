import SwiftUI
import SwiftData

// MARK: - Preview

#Preview("Flight Planner Layout", traits: .landscapeLeft) {
    let currentSectors: [(String, String, String, String, String, String)] = [
        ("DXB", "MAN", "03:45", "08:30", "EK0019", "09-May-26"),
        ("MAN", "DXB", "21:20", "08:30", "EK0020", "09-May-26"),
        ("DXB", "TPE", "03:45", "16:10", "EK0366", "08-May-26"),
        ("TPE", "DXB", "23:05", "04:35", "EK0367", "08-May-26"),
    ]

    let upcomingTrips: [(String, String, Int)] = [
        ("DXB - LHR - DXB", "15 May", 2),
        ("DXB - JFK - DXB", "22 May", 2),
        ("DXB - SYD - BKK - DXB", "01 Jun", 3),
    ]

    ScrollView {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Current")
                    .font(.title3.bold())

                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3),
                    alignment: .leading,
                    spacing: 8
                ) {
                    ForEach(0..<4, id: \.self) { i in
                        let d = currentSectors[i]
                        SectorCardPreview(
                            dep: d.0, arr: d.1,
                            depTime: d.2, arrTime: d.3,
                            flight: d.4,
                            date: d.5
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)

            VStack(alignment: .leading, spacing: 12) {
                Text("Upcoming")
                    .font(.title3.bold())

                VStack(spacing: 0) {
                    ForEach(0..<upcomingTrips.count, id: \.self) { i in
                        let trip = upcomingTrips[i]
                        HStack(spacing: 12) {
                            Text(trip.1)
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.secondary)
                                .frame(width: 55, alignment: .leading)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(trip.0)
                                    .font(.subheadline.bold())
                                HStack(spacing: 4) {
                                    Text("\(trip.2) sectors")
                                }
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)

                        if i < upcomingTrips.count - 1 {
                            Divider()
                                .padding(.horizontal, 14)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 1)
                .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 5)
            }
            .frame(minWidth: 300, maxWidth: 360)
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

private struct SectorCardPreview: View {
    let dep: String
    let arr: String
    let depTime: String
    let arrTime: String
    let flight: String
    let date: String

    var body: some View {
        VStack(spacing: 2) {
            HStack {
                Text(date)
                    .font(.caption2)
                Spacer()
                Text(flight)
                    .font(.caption2.bold())
            }

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(dep)
                        .font(.title2.bold())
                    Text(depTime)
                        .font(.caption.monospaced())
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "airplane")
                    .font(.subheadline)
                    .foregroundStyle(.red)

                VStack(alignment: .trailing, spacing: 1) {
                    Text(arr)
                        .font(.title2.bold())
                    Text(arrTime)
                        .font(.caption.monospaced())
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 1)
        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 8)
    }
}

// MARK: - Flight Planner Home

/// Home screen for the Flight Planner mini-app. Reads only from `PlannedFlight`
/// — it never touches `SavedTrip`, so Allocate Positions imports/deletes do not
/// affect what appears here.
struct FlightPlannerHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PlannedSector.date) private var allSectors: [PlannedSector]
    @Query(sort: \PlannedFlight.flightDate) private var allTrips: [PlannedFlight]
    @State private var selectedSectorID: UUID?

    // Edit / delete / multi-select state
    @State private var isSelecting = false
    @State private var selectedTripIDs: Set<UUID> = []
    @State private var tripToEdit: PlannedFlight?
    @State private var tripToDelete: PlannedFlight?
    @State private var showDeleteConfirm = false
    @State private var showDeleteSelectedConfirm = false
    @State private var showRosterImport = false
    @State private var expandedRecentMonths: Set<String> = []
    @State private var showHistoryTrips = false
    @State private var expandedTripIDs: Set<UUID> = []
    @State private var cachedUpcomingTrips: [PlannedFlight] = []
    @State private var cachedCurrentSectors: [PlannedSector] = []
    @State private var cachedRecentTripsByMonth: [(month: String, trips: [PlannedFlight])] = []
    @State private var cachedHistoryTrips: [PlannedFlight] = []

    private var selectedSector: PlannedSector? {
        guard let id = selectedSectorID else { return nil }
        return allSectors.first { $0.id == id }
    }

    // MARK: - Landing Time Helper

    /// Builds an absolute `Date` from the sector's departure date and a local
    /// time string, using the given station's timezone. Falls back to device
    /// timezone if the station is unknown.
    private func absoluteDateTime(for sector: PlannedSector, time: String, station: String) -> Date {
        let parts = time.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return sector.date }

        let tz = StationTimezones.timeZone(for: station) ?? .current
        var cal = Calendar.current
        cal.timeZone = tz

        let day = cal.dateComponents([.year, .month, .day], from: sector.date)
        var components = DateComponents()
        components.year = day.year
        components.month = day.month
        components.day = day.day
        components.hour = parts[0]
        components.minute = parts[1]
        components.timeZone = tz
        return cal.date(from: components) ?? sector.date
    }

    /// Combines the sector date with its landing time (actual or scheduled)
    /// to produce a full `Date` for comparison. Handles overnight flights.
    /// Times are interpreted in their respective station timezones.
    private func landingDateTime(for sector: PlannedSector) -> Date {
        let timeString = sector.actualLandingTime ?? sector.arrivalTime
        var landing = absoluteDateTime(for: sector, time: timeString, station: sector.arrivalStation)
        let departure = departureDateTime(for: sector)
        if landing < departure {
            let tz = StationTimezones.timeZone(for: sector.arrivalStation) ?? .current
            var cal = Calendar.current
            cal.timeZone = tz
            landing = cal.date(byAdding: .day, value: 1, to: landing) ?? landing
        }
        return landing
    }

    // MARK: - Departure Time Helper

    private func departureDateTime(for sector: PlannedSector) -> Date {
        absoluteDateTime(for: sector, time: sector.departureTime, station: sector.departureStation)
    }

    // MARK: - Trip Timing Helpers

    /// Departure datetime of the first sector departing from DXB (falls back to first sector).
    private func tripDXBDeparture(for trip: PlannedFlight) -> Date {
        let sorted = trip.sortedSectors
        if let sector = sorted.first(where: { $0.departureStation == "DXB" }) {
            return departureDateTime(for: sector)
        }
        guard let first = sorted.first else { return trip.flightDate }
        return departureDateTime(for: first)
    }

    /// Arrival datetime of the last sector arriving at DXB (falls back to last sector).
    private func tripDXBArrival(for trip: PlannedFlight) -> Date {
        let sorted = trip.sortedSectors
        if let sector = sorted.last(where: { $0.arrivalStation == "DXB" }) {
            return landingDateTime(for: sector)
        }
        guard let last = sorted.last else { return trip.flightDate }
        return landingDateTime(for: last)
    }

    // MARK: - Section Cache

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM yyyy"
        return f
    }()

    private func recomputeSections() {
        let now = Date()
        let cutoff24h = now.addingTimeInterval(24 * 3600)
        let start = Calendar.current.startOfDay(for: now)
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: start) ?? start

        var departures: [UUID: Date] = [:]
        var arrivals: [UUID: Date] = [:]
        for trip in allTrips where !trip.sectors.isEmpty {
            departures[trip.id] = tripDXBDeparture(for: trip)
            arrivals[trip.id] = tripDXBArrival(for: trip)
        }

        cachedUpcomingTrips = allTrips
            .filter { !$0.sectors.isEmpty && (departures[$0.id] ?? .distantPast) > cutoff24h }
            .sorted { $0.flightDate < $1.flightDate }

        let currentTripIDs = Set(allTrips.filter { trip in
            guard !trip.sectors.isEmpty else { return false }
            let dep = departures[trip.id] ?? .distantPast
            let arr = arrivals[trip.id] ?? .distantPast
            return dep <= cutoff24h && arr.addingTimeInterval(24 * 3600) > now
        }.map(\.id))

        cachedCurrentSectors = allSectors
            .filter { currentTripIDs.contains($0.parentTrip?.id ?? UUID()) }
            .sorted { $0.date < $1.date || ($0.date == $1.date && $0.departureTime < $1.departureTime) }

        let recentTripIDs = Set(allTrips.filter { trip in
            guard !trip.sectors.isEmpty else { return false }
            let arr = arrivals[trip.id] ?? .distantPast
            return arr.addingTimeInterval(24 * 3600) <= now && trip.flightDate >= thirtyDaysAgo
        }.map(\.id))

        let recentTrips = allTrips
            .filter { recentTripIDs.contains($0.id) }
            .sorted { $0.flightDate > $1.flightDate }

        let cal = Calendar.current
        let grouped = Dictionary(grouping: recentTrips) { trip in
            cal.dateComponents([.year, .month], from: trip.flightDate)
        }
        cachedRecentTripsByMonth = grouped
            .sorted {
                let a = cal.date(from: $0.key) ?? .distantPast
                let b = cal.date(from: $1.key) ?? .distantPast
                return a > b
            }
            .map {
                let label = Self.monthFormatter.string(from: cal.date(from: $0.key) ?? Date())
                return (month: label, trips: $0.value.sorted { $0.flightDate > $1.flightDate })
            }

        let historyTripIDs = Set(allTrips.filter { $0.flightDate < thirtyDaysAgo }.map(\.id))
        cachedHistoryTrips = allTrips
            .filter { historyTripIDs.contains($0.id) }
            .sorted { $0.flightDate > $1.flightDate }
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                if allSectors.isEmpty {
                    emptyState
                } else {
                    sectorList
                }
            }

            // Bulk selection bar
            if isSelecting {
                VStack(spacing: 0) {
                    Divider()
                    HStack(spacing: 16) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if selectedTripIDs.count == allTrips.count {
                                    selectedTripIDs.removeAll()
                                } else {
                                    selectedTripIDs = Set(allTrips.map { $0.id })
                                }
                            }
                        } label: {
                            Text(selectedTripIDs.count == allTrips.count ? "Deselect All" : "Select All")
                        }

                        Spacer()

                        Text("\(selectedTripIDs.count) selected")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Button(role: .destructive) {
                            showDeleteSelectedConfirm = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "trash")
                                Text("Delete")
                            }
                        }
                        .disabled(selectedTripIDs.isEmpty)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
                .background(.bar)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Confirm button + version
            if !isSelecting {
                VStack(spacing: 8) {
                    if let sector = selectedSector {
                        NavigationLink {
                            SectorDetailView(sector: sector)
                                .navigationBarBackButtonHidden(true)
                        } label: {
                            Text("Confirm Selection")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 12)
                                .background(Color.accentColor, in: Capsule())
                                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(.bottom, 16)
            }
        }
        .background(Color(.systemGroupedBackground))
        .animation(.easeInOut(duration: 0.2), value: selectedSectorID)
        .navigationTitle("Flight Planner")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isSelecting.toggle()
                        if !isSelecting { selectedTripIDs.removeAll() }
                    }
                } label: {
                    Text(isSelecting ? "Done" : "Select")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 10) {
                    if !isSelecting {
                        Button {
                            showRosterImport = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.down.doc")
                                Text("Import from Portal")
                                    .fontWeight(.bold)
                            }
                            .foregroundStyle(.white)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)

                        NavigationLink {
                            AddTripView()
                                .navigationBarBackButtonHidden(true)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                Text("Add Trip")
                                    .fontWeight(.bold)
                            }
                            .foregroundStyle(.white)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showRosterImport) {
            NavigationStack {
                RosterImportView()
            }
        }
        .confirmationDialog(
            "Delete \(selectedTripIDs.count) trip\(selectedTripIDs.count == 1 ? "" : "s")?",
            isPresented: $showDeleteSelectedConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteBulkTrips()
            }
        } message: {
            Text("This will permanently remove the selected trips and all their sectors.")
        }
        .onAppear { recomputeSections() }
        .onChange(of: allTrips.count) { recomputeSections() }
        .onChange(of: allSectors.count) { recomputeSections() }
    }

    // MARK: - Bulk Delete

    private func deleteBulkTrips() {
        let tripsToDelete = allTrips.filter { selectedTripIDs.contains($0.id) }
        for trip in tripsToDelete {
            for sector in trip.sectors {
                modelContext.delete(sector)
            }
            modelContext.delete(trip)
        }
        try? modelContext.save()
        withAnimation {
            selectedTripIDs.removeAll()
            isSelecting = false
        }
    }

    // MARK: - Selection Toggle

    private func toggleSelection(for trip: PlannedFlight) {
        withAnimation(.easeInOut(duration: 0.15)) {
            if selectedTripIDs.contains(trip.id) {
                selectedTripIDs.remove(trip.id)
            } else {
                selectedTripIDs.insert(trip.id)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Flights", systemImage: "airplane.departure")
        } description: {
            Text("Flight Planner is empty. Tap Add Trip to get started.")
        }
    }

    // MARK: - Sector List

    private var sectorList: some View {
        GeometryReader { geo in
        ScrollView {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    RosterStaleBanner(onRefresh: { showRosterImport = true })

                    if !cachedCurrentSectors.isEmpty {
                        sectorSection("Current", sectors: cachedCurrentSectors)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(cachedRecentTripsByMonth, id: \.month) { group in
                            collapsibleTripSection(
                                group.month,
                                trips: group.trips,
                                isExpanded: Binding(
                                    get: { expandedRecentMonths.contains(group.month) },
                                    set: { newValue in
                                        if newValue { expandedRecentMonths.insert(group.month) }
                                        else { expandedRecentMonths.remove(group.month) }
                                    }
                                )
                            )
                        }
                        if !cachedHistoryTrips.isEmpty {
                            collapsibleTripSection("History", trips: cachedHistoryTrips, isExpanded: $showHistoryTrips)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, max(24, geo.size.height * 0.45))
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)

                upcomingCard
                    .frame(minWidth: 300, maxWidth: 360)
            }
            .padding()
        }
        }
    }

    @ViewBuilder
    private func sectorSection(_ title: String, sectors: [PlannedSector]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3.bold())

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3),
                alignment: .leading,
                spacing: 8
            ) {
                ForEach(sectors) { sector in
                    SectorCard(sector: sector, isSelected: selectedSectorID == sector.id)
                        .onTapGesture {
                            if selectedSectorID == sector.id {
                                selectedSectorID = nil
                            } else {
                                selectedSectorID = sector.id
                            }
                        }
                }
            }
        }
    }

    // MARK: - Collapsible Trip Section

    @ViewBuilder
    private func collapsibleTripSection(_ title: String, trips: [PlannedFlight], isExpanded: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
                Text("\(trips.count) trip\(trips.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { isExpanded.wrappedValue },
                    set: { newValue in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded.wrappedValue = newValue
                        }
                    }
                ))
                .labelsHidden()
                .tint(.red)
            }

            if isExpanded.wrappedValue {
                VStack(spacing: 0) {
                    ForEach(Array(trips.enumerated()), id: \.element.id) { index, trip in
                        let isTripExpanded = expandedTripIDs.contains(trip.id)

                        Button {
                            if isSelecting {
                                toggleSelection(for: trip)
                            } else {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    if isTripExpanded {
                                        expandedTripIDs.remove(trip.id)
                                    } else {
                                        expandedTripIDs = [trip.id]
                                    }
                                }
                            }
                        } label: {
                            TripRow(trip: trip, isExpanded: isSelecting ? false : isTripExpanded, isSelected: selectedTripIDs.contains(trip.id), showSelection: isSelecting)
                        }
                        .buttonStyle(.plain)

                        if isTripExpanded {
                            LazyVGrid(
                                columns: [GridItem(.adaptive(minimum: 180, maximum: 260), spacing: 16)],
                                alignment: .leading,
                                spacing: 16
                            ) {
                                ForEach(trip.sortedSectors) { sector in
                                    SectorCard(sector: sector, isSelected: selectedSectorID == sector.id)
                                        .onTapGesture {
                                            if selectedSectorID == sector.id {
                                                selectedSectorID = nil
                                            } else {
                                                selectedSectorID = sector.id
                                            }
                                        }
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.bottom, 10)
                            .transition(.opacity)
                        }

                        if index < trips.count - 1 {
                            Divider()
                                .padding(.horizontal, 14)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color(.separator).opacity(0.15), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 1)
                .shadow(color: .black.opacity(0.10), radius: 8, x: 0, y: 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Upcoming Card

    private var upcomingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming")
                .font(.title3.bold())

            if cachedUpcomingTrips.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.title2)
                        .foregroundStyle(.tertiary)
                    Text("No upcoming trips")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(cachedUpcomingTrips.enumerated()), id: \.element.id) { index, trip in
                        if isSelecting {
                            Button { toggleSelection(for: trip) } label: {
                                TripRow(trip: trip, isSelected: selectedTripIDs.contains(trip.id), showSelection: true)
                            }
                            .buttonStyle(.plain)
                        } else {
                            NavigationLink {
                                AddTripView(flightToEdit: trip)
                                    .navigationBarBackButtonHidden(true)
                            } label: {
                                TripRow(trip: trip)
                            }
                            .buttonStyle(.plain)
                        }

                        if index < cachedUpcomingTrips.count - 1 {
                            Divider()
                                .padding(.horizontal, 14)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color(.separator).opacity(0.15), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 1)
                .shadow(color: .black.opacity(0.10), radius: 8, x: 0, y: 4)
            }
        }
    }
}

// MARK: - Upcoming Trip Row

struct TripRow: View {
    let trip: PlannedFlight
    var isExpanded: Bool = false
    var isSelected: Bool = false
    var showSelection: Bool = false

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd MMM"
        return f
    }()

    var body: some View {
        HStack(spacing: 12) {
            if showSelection {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? .accentColor : Color(.tertiaryLabel))
                    .animation(.easeInOut(duration: 0.15), value: isSelected)
            }

            Text(Self.dateFormatter.string(from: trip.flightDate))
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 55, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(trip.routeString)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)

                HStack(spacing: 4) {
                    if !trip.tripNumber.isEmpty {
                        Text("Trip \(trip.tripNumber)")
                    }
                    Text("·")
                    Text("\(trip.sectors.count) sector\(trip.sectors.count == 1 ? "" : "s")")
                }
                .font(.caption)
                .foregroundStyle(.tertiary)
            }

            Spacer()

            if !showSelection {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .animation(.easeInOut(duration: 0.2), value: isExpanded)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .contentShape(Rectangle())
    }
}

// MARK: - Sector Card

struct SectorCard: View {
    let sector: PlannedSector
    var isSelected: Bool = false

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd-MMM-yy"
        return f
    }()

    var body: some View {
        VStack(spacing: 2) {
            HStack {
                Text(Self.dateFormatter.string(from: sector.date))
                    .font(.caption2)
                Spacer()
                Text(sector.flightNumber)
                    .font(.caption2.bold())
            }

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(sector.departureStation)
                        .font(.title2.bold())
                    Text(sector.departureTime)
                        .font(.caption.monospaced())
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "airplane")
                    .font(.subheadline)
                    .foregroundStyle(.red)

                VStack(alignment: .trailing, spacing: 1) {
                    Text(sector.arrivalStation)
                        .font(.title2.bold())
                    Text(sector.arrivalTime)
                        .font(.caption.monospaced())
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isSelected ? Color.green : Color(.separator).opacity(0.3), lineWidth: isSelected ? 2.5 : 0.5)
        )
        .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 1)
        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 8)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}
