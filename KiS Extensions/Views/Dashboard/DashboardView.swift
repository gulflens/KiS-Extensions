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

    private var filteredTrips: [SavedTrip] {
        guard !searchText.isEmpty else { return savedTrips }
        let lowered = searchText.lowercased()
        return savedTrips.filter { trip in
            trip.flightNumber.lowercased().contains(lowered) ||
            trip.routeString.lowercased().contains(lowered) ||
            trip.crewAllocations.contains(where: {
                $0.fullname.lowercased().contains(lowered) ||
                $0.nickname.lowercased().contains(lowered) ||
                $0.staffNumber.lowercased().contains(lowered)
            })
        }
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd MMM yyyy"
        return f
    }()

    var body: some View {
        Group {
            if savedTrips.isEmpty && searchText.isEmpty {
                emptyState
            } else {
                tripList
            }
        }
        .navigationTitle("KiS Extensions")
        .searchable(text: $searchText, prompt: "Search trips, crew, staff number...")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    Button {
                        showCrewSearch = true
                    } label: {
                        Image(systemName: "person.2.badge.gearshape")
                    }

                    Button {
                        showPortalBrowser = true
                    } label: {
                        Label("Import Trip", systemImage: "plus.circle")
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showPortalBrowser) {
            PortalBrowserView()
        }
        .sheet(isPresented: $showCrewSearch) {
            CrewSearchView()
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
        List {
            ForEach(filteredTrips) { trip in
                TripCardView(trip: trip) {
                    // View: load saved trip into CrewTableView
                    let parsed = trip.toParsedTrip()
                    appState.parsedTrips = [parsed]
                    appState.selectTrip(at: 0, doPositions: false)
                } onReAllocate: {
                    // Re-allocate: reload from raw data and run allocation
                    let parsed = trip.toParsedTrip()
                    appState.parsedTrips = [parsed]
                    appState.selectTrip(at: 0, doPositions: true)
                } onDelete: {
                    tripToDelete = trip
                    showDeleteConfirmation = true
                }
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Trip Card

struct TripCardView: View {
    let trip: SavedTrip
    let onView: () -> Void
    let onReAllocate: () -> Void
    let onDelete: () -> Void

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd MMM yyyy"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header row
            HStack {
                Text("EK \(trip.flightNumber)")
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

                Text(Self.dateFormatter.string(from: trip.flightDate))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Route
            Text(trip.routeString)
                .font(.subheadline.monospaced())
                .foregroundStyle(.secondary)

            // Details row
            HStack(spacing: 16) {
                if let reg = trip.registration {
                    Label(reg, systemImage: "airplane")
                        .font(.caption)
                }
                Label("\(trip.crewAllocations.count) crew", systemImage: "person.2")
                    .font(.caption)
                Label(trip.durationText, systemImage: "clock")
                    .font(.caption)
                Label("\(trip.sectors) sector\(trip.sectors == 1 ? "" : "s")", systemImage: "arrow.triangle.swap")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)

            // Notes preview
            if !trip.notes.isEmpty {
                Text(trip.notes)
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .lineLimit(1)
            }

            // Action buttons
            HStack(spacing: 12) {
                Button {
                    onView()
                } label: {
                    Label("View", systemImage: "eye")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                Button {
                    onReAllocate()
                } label: {
                    Label("Re-allocate", systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Spacer()

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 8)
    }
}
