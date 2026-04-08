import SwiftUI
import SwiftData

struct CrewSearchView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var results: [CrewSearchResult] = []

    struct CrewSearchResult: Identifiable {
        let id = UUID()
        let crew: SavedCrewAllocation
        let trip: SavedTrip
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd MMM yyyy"
        return f
    }()

    var body: some View {
        NavigationStack {
            Group {
                if searchText.isEmpty {
                    ContentUnavailableView(
                        "Search Crew",
                        systemImage: "person.2.badge.gearshape",
                        description: Text("Search by name, staff number, nationality, or grade")
                    )
                } else if results.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    List(results) { result in
                        Button {
                            navigateToTrip(result.trip)
                        } label: {
                            crewResultRow(result)
                        }
                        .tint(.primary)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Search Crew")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Name, staff number, nationality...")
            .onChange(of: searchText) { _, newValue in
                performSearch(query: newValue)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func crewResultRow(_ result: CrewSearchResult) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(result.crew.fullname)
                    .font(.body.bold())

                Spacer()

                Text(result.crew.gradeRaw)
                    .font(.caption.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(.systemGray5))
                    .cornerRadius(4)
            }

            HStack(spacing: 12) {
                Label(result.crew.staffNumber, systemImage: "person.text.rectangle")
                    .font(.caption)
                Label(result.crew.nationality, systemImage: "globe")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)

            HStack(spacing: 4) {
                Image(systemName: "airplane")
                    .font(.caption2)
                Text("EK \(result.trip.flightNumber)")
                    .font(.caption.bold())
                Text(result.trip.routeString)
                    .font(.caption)
                Text(Self.dateFormatter.string(from: result.trip.flightDate))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(.blue)
        }
        .padding(.vertical, 4)
    }

    private func performSearch(query: String) {
        guard !query.isEmpty else {
            results = []
            return
        }

        let lowered = query.lowercased()

        let descriptor = FetchDescriptor<SavedTrip>(
            sortBy: [SortDescriptor(\.flightDate, order: .reverse)]
        )
        guard let trips = try? modelContext.fetch(descriptor) else {
            results = []
            return
        }

        var found: [CrewSearchResult] = []
        for trip in trips {
            for crew in trip.crewAllocations {
                let matches =
                    crew.fullname.lowercased().contains(lowered) ||
                    crew.nickname.lowercased().contains(lowered) ||
                    crew.staffNumber.lowercased().contains(lowered) ||
                    crew.nationality.lowercased().contains(lowered) ||
                    crew.gradeRaw.lowercased().contains(lowered)

                if matches {
                    found.append(CrewSearchResult(crew: crew, trip: trip))
                }
            }
        }
        results = found
    }

    private func navigateToTrip(_ trip: SavedTrip) {
        dismiss()
        let parsed = trip.toParsedTrip()
        appState.parsedTrips = [parsed]
        appState.selectTrip(at: 0, doPositions: false)
    }
}
