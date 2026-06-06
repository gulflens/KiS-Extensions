import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedTrip.flightDate, order: .reverse) private var savedTrips: [SavedTrip]

    @State private var showPortalBrowser = false

    @State private var showCrewSearch = false
    @State private var searchText = ""
    @State private var tripToDelete: SavedTrip?
    @State private var showDeleteConfirmation = false
    @State private var expandedMonths: Set<String> = []
    @State private var isSelecting = false
    @State private var selectedTripIDs: Set<PersistentIdentifier> = []
    @State private var showDeleteSelectedConfirmation = false
    @State private var cachedTripsByMonth: [MonthGroup] = []

    private func recomputeTrips() {
        let filtered: [SavedTrip]
        if searchText.isEmpty {
            filtered = Array(savedTrips)
        } else {
            let lowered = searchText.lowercased()
            filtered = savedTrips.filter { trip in
                trip.flightNumber.lowercased().contains(lowered) ||
                trip.routeString.lowercased().contains(lowered) ||
                trip.crewAllocations.contains(where: {
                    $0.fullname.lowercased().contains(lowered) ||
                    $0.nickname.lowercased().contains(lowered) ||
                    $0.staffNumber.lowercased().contains(lowered)
                })
            }
        }
        var grouped: [String: [SavedTrip]] = [:]
        for trip in filtered {
            let key = Self.monthKeyFormatter.string(from: trip.flightDate)
            grouped[key, default: []].append(trip)
        }
        cachedTripsByMonth = grouped.keys.sorted(by: >).map { key in
            let trips = grouped[key]!.sorted { $0.flightDate > $1.flightDate }
            return MonthGroup(
                id: key,
                label: Self.monthLabelFormatter.string(from: trips[0].flightDate),
                trips: trips
            )
        }
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd MMM yyyy"
        return f
    }()

    private static let monthKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM"
        return f
    }()

    private static let monthLabelFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }()

    // MARK: - Section Data

    private var currentMonthKey: String {
        Self.monthKeyFormatter.string(from: Date())
    }


    var body: some View {
        Group {
            if savedTrips.isEmpty && searchText.isEmpty {
                emptyState
            } else {
                tripList
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                HStack(spacing: 16) {
                    if isSelecting {
                        HStack(spacing: 12) {
                            Button("Done") {
                                isSelecting = false
                                selectedTripIDs.removeAll()
                            }
                            .fontWeight(.semibold)

                            if !selectedTripIDs.isEmpty {
                                Button {
                                    showDeleteSelectedConfirmation = true
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "trash")
                                        Text("Delete (\(selectedTripIDs.count))")
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.red)
                                .controlSize(.small)
                            }
                        }
                    } else {
                        Button("Select") {
                            isSelecting = true
                        }
                    }
                }
            }

            ToolbarItem(placement: .principal) {
                HStack(spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search trips, crew, staff number...", text: $searchText)
                            .textFieldStyle(.plain)
                            .submitLabel(.search)
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray5), in: Capsule())

                    Button {
                        showCrewSearch = true
                    } label: {
                        Image(systemName: "person.2.badge.gearshape")
                    }
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showPortalBrowser = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle")
                        Text("Add New Flight")
                    }
                    .padding(.horizontal, 8)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .fullScreenCover(isPresented: $showPortalBrowser) {
            PortalBrowserView()
        }
        .sheet(isPresented: $showCrewSearch) {
            CrewSearchView()
        }

        .alert("Delete Selected Trips?", isPresented: $showDeleteSelectedConfirmation) {
            Button("Delete \(selectedTripIDs.count) trip\(selectedTripIDs.count == 1 ? "" : "s")", role: .destructive) {
                deleteSelectedTrips()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete \(selectedTripIDs.count) selected trip\(selectedTripIDs.count == 1 ? "" : "s"). This cannot be undone.")
        }
        .alert("Delete Trip?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let trip = tripToDelete {
                    modelContext.delete(trip)
                    try? modelContext.save()
                }
                tripToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                tripToDelete = nil
            }
        } message: {
            if let trip = tripToDelete {
                Text("Delete EK \(trip.flightNumber) on \(Self.dateFormatter.string(from: trip.flightDate))? This cannot be undone.")
            }
        }
        .onAppear { recomputeTrips() }
        .onChange(of: searchText) { recomputeTrips() }
        .onChange(of: savedTrips.count) { recomputeTrips() }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 8) {
                Image(systemName: "airplane")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                Text("KiS Extensions")
                    .font(.largeTitle.bold())
                Text("Emirates cabin crew inflight tools")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 16) {
                Button {
                    showPortalBrowser = true
                } label: {
                    Label("Import from Crew Portal", systemImage: "globe")
                        .frame(maxWidth: 340)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Text("Log in to the portal, load your trips, then tap Extract Data.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 340)
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Trip List

    private var tripList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(cachedTripsByMonth) { month in
                    let isCurrent = month.id == currentMonthKey
                    let isExpanded = isCurrent || expandedMonths.contains(month.id)

                    VStack(alignment: .leading, spacing: 0) {
                        Button {
                            if !isCurrent {
                                withAnimation {
                                    if expandedMonths.contains(month.id) {
                                        expandedMonths.remove(month.id)
                                    } else {
                                        expandedMonths.insert(month.id)
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text(month.label)
                                    .font(.headline)
                                Text("(\(month.trips.count))")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                if !isCurrent {
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)

                        if isExpanded {
                            Divider()
                                .padding(.horizontal, 16)

                            VStack(spacing: 0) {
                                ForEach(month.trips) { trip in
                                    tripCardRow(for: trip)
                                    if trip.id != month.trips.last?.id {
                                        Divider()
                                            .padding(.horizontal, 16)
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Helpers

    @ViewBuilder
    private func tripCardRow(for trip: SavedTrip) -> some View {
        HStack(spacing: 12) {
            if isSelecting {
                Button {
                    if selectedTripIDs.contains(trip.id) {
                        selectedTripIDs.remove(trip.id)
                    } else {
                        selectedTripIDs.insert(trip.id)
                    }
                } label: {
                    Image(systemName: selectedTripIDs.contains(trip.id) ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(selectedTripIDs.contains(trip.id) ? .blue : .secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }

            TripCardView(trip: trip) {
                let parsed = trip.toParsedTrip()
                appState.parsedTrips = [parsed]
                appState.selectTrip(at: 0, doPositions: false)
            } onDelete: {
                tripToDelete = trip
                showDeleteConfirmation = true
            }
        }
    }

    private func deleteSelectedTrips() {
        for trip in savedTrips where selectedTripIDs.contains(trip.id) {
            modelContext.delete(trip)
        }
        try? modelContext.save()
        selectedTripIDs.removeAll()
        isSelecting = false
    }

    private func expandedMonthBinding(for key: String) -> Binding<Bool> {
        Binding(
            get: { expandedMonths.contains(key) },
            set: { if $0 { expandedMonths.insert(key) } else { expandedMonths.remove(key) } }
        )
    }
}

// MARK: - Month Group

private struct MonthGroup: Identifiable {
    var id: String
    var label: String
    var trips: [SavedTrip]
}

// MARK: - Trip Card

struct TripCardView: View {
    let trip: SavedTrip
    let onView: () -> Void
    let onDelete: () -> Void

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd MMM yyyy"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header row
            HStack(spacing: 8) {
                Text("EK \(trip.flightNumber)")
                    .font(.headline)

                Text("|")
                    .font(.headline)
                    .foregroundStyle(.red)

                Text(trip.routeString)
                    .font(.headline.monospaced())

                Text("|")
                    .font(.headline)
                    .foregroundStyle(.red)

                Text(Self.dateFormatter.string(from: trip.flightDate))
                    .font(.headline)

                if trip.isULR {
                    Text("ULR")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.red)
                        .cornerRadius(4)
                }

                Spacer()

                Button {
                    onView()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "eye")
                        Text("View")
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)


            }

            // Details row
            HStack(spacing: 16) {
                if let reg = trip.registration {
                    Label(reg, systemImage: "airplane")
                        .font(.subheadline)
                }
                Label("\(trip.crewAllocations.count) crew", systemImage: "person.2")
                    .font(.subheadline)
                Label(trip.durationText, systemImage: "clock")
                    .font(.subheadline)
                Label("\(trip.sectors) sector\(trip.sectors == 1 ? "" : "s")", systemImage: "arrow.triangle.swap")
                    .font(.subheadline)
            }
            .foregroundStyle(.secondary)

            // Notes preview
            if !trip.notes.isEmpty {
                Text(trip.notes)
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
    }
}
