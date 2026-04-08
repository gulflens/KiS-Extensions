import SwiftUI

struct TripsListView: View {
    @Environment(AppState.self) private var appState
    @State private var showSettings = false
    @State private var showOlderFlights = false

    /// Indices of trips with flightDate >= start of today (current/future), sorted by date ascending
    private var upcomingIndices: [Int] {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        return appState.parsedTrips.enumerated()
            .filter { $0.element.flightInfo.flightDate >= startOfToday }
            .sorted { $0.element.flightInfo.flightDate < $1.element.flightInfo.flightDate }
            .map(\.offset)
    }

    /// Indices of trips with flightDate < start of today (past), sorted by date descending (most recent first)
    private var olderIndices: [Int] {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        return appState.parsedTrips.enumerated()
            .filter { $0.element.flightInfo.flightDate < startOfToday }
            .sorted { $0.element.flightInfo.flightDate > $1.element.flightInfo.flightDate }
            .map(\.offset)
    }

    var body: some View {
        @Bindable var appState = appState
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Current & upcoming flights
                if upcomingIndices.isEmpty && olderIndices.isEmpty {
                    ContentUnavailableView("No Trips", systemImage: "airplane", description: Text("Import crew data to see trips here."))
                        .frame(maxWidth: .infinity, minHeight: 300)
                } else {
                    if !upcomingIndices.isEmpty {
                        VStack(spacing: 12) {
                            ForEach(upcomingIndices, id: \.self) { index in
                                TripSelectionCard(
                                    trip: $appState.parsedTrips[index],
                                    onGenerate: { appState.selectTrip(at: index, doPositions: true) },
                                    onListOnly: { appState.selectTrip(at: index, doPositions: false) }
                                )
                            }
                        }
                    }

                    // Older flights section
                    if !olderIndices.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Button {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    showOlderFlights.toggle()
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: showOlderFlights ? "chevron.down" : "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .frame(width: 14)
                                    Text("Older Flights")
                                        .font(.subheadline.weight(.semibold))
                                    Text("(\(olderIndices.count))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                }
                                .foregroundStyle(.secondary)
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)

                            if showOlderFlights {
                                VStack(spacing: 12) {
                                    ForEach(olderIndices, id: \.self) { index in
                                        TripSelectionCard(
                                            trip: $appState.parsedTrips[index],
                                            onGenerate: { appState.selectTrip(at: index, doPositions: true) },
                                            onListOnly: { appState.selectTrip(at: index, doPositions: false) }
                                        )
                                        .opacity(0.75)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Select Trip")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView()
            }
        }
    }
}

// MARK: - Trip Selection Card

struct TripSelectionCard: View {
    @Binding var trip: ParsedTrip
    let onGenerate: () -> Void
    let onListOnly: () -> Void

    @State private var regDraft: String = ""
    @State private var breakToggles: [Bool] = []
    @FocusState private var regFocused: Bool

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd MMM"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: Header — blue row
            HStack(spacing: 8) {
                Text("EK \(trip.flightInfo.flightNumber)")
                    .font(.headline)

                Text(trip.flightInfo.flightLegs.joined(separator: " – "))
                    .font(.subheadline)
                    .monospaced()
                    .opacity(0.85)
                    .lineLimit(1)

                Spacer()

                Label(Self.dateFormatter.string(from: trip.flightInfo.flightDate), systemImage: "calendar")
                    .font(.subheadline)

                Label(durationText, systemImage: "clock")
                    .font(.subheadline)

                if trip.flightInfo.isULR {
                    Text("ULR")
                        .font(.caption2.bold())
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.white)
                        .clipShape(Capsule())
                }
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.blue)

            // MARK: Body — single row
            HStack(spacing: 12) {
                // Registration input
                HStack(spacing: 2) {
                    Image(systemName: "airplane")
                        .font(.caption)
                        .foregroundStyle(regDraft.isEmpty ? .orange : .blue)
                        .padding(.trailing, 4)

                    Text("A6-")
                        .font(.caption.weight(.semibold).monospaced())
                        .foregroundStyle(.primary)
                        .fixedSize()

                    TextField("___", text: $regDraft)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .font(.caption.weight(.semibold).monospaced())
                        .foregroundStyle(regForegroundStyle)
                        .focused($regFocused)
                        .submitLabel(.done)
                        .onSubmit { commitRegistration() }
                        .onChange(of: regFocused) { _, focused in
                            if !focused { commitRegistration() }
                        }
                        .onChange(of: regDraft) { _, newValue in
                            if newValue.count > 3 {
                                regDraft = String(newValue.prefix(3))
                            }
                        }
                        .onAppear {
                            regDraft = suffixFromRegistration(trip.registration)
                            syncBreakToggles()
                        }
                        .onChange(of: trip.registration) { _, newValue in
                            if !regFocused { regDraft = suffixFromRegistration(newValue) }
                        }
                        .frame(width: 36)

                    if !aircraftTypeText.isEmpty {
                        Text(aircraftTypeText)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .padding(.leading, 4)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(regDraft.isEmpty ? Color.orange.opacity(0.5) : Color(.systemGray4), lineWidth: 1)
                )

                // Warning when no registration
                if regDraft.isEmpty {
                    Label("No registration", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.red)
                }

                Divider().frame(height: 16)

                // Sectors stepper
                HStack(spacing: 0) {
                    Button {
                        if trip.flightInfo.sectors > 1 {
                            trip.flightInfo.sectors -= 1
                            syncBreakToggles()
                        }
                    } label: {
                        Image(systemName: "minus")
                            .font(.caption2.weight(.bold))
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                    .disabled(trip.flightInfo.sectors <= 1)

                    Text("\(trip.flightInfo.sectors)")
                        .font(.caption.weight(.semibold).monospaced())
                        .frame(width: 20)
                        .multilineTextAlignment(.center)

                    Button {
                        trip.flightInfo.sectors += 1
                        syncBreakToggles()
                    } label: {
                        Image(systemName: "plus")
                            .font(.caption2.weight(.bold))
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)

                    Text("sec")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 2)
                }

                Divider().frame(height: 16)

                // Crew count
                Label("\(trip.crewMembers.count) crew", systemImage: "person.2")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Divider().frame(height: 16)

                // Break checkboxes
                HStack(spacing: 8) {
                    Text("Breaks:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(0..<trip.flightInfo.sectors, id: \.self) { i in
                        Button {
                            if breakToggles.indices.contains(i) {
                                breakToggles[i].toggle()
                            }
                        } label: {
                            HStack(spacing: 3) {
                                Image(systemName: (breakToggles.indices.contains(i) && breakToggles[i]) ? "checkmark.square.fill" : "square")
                                    .foregroundStyle((breakToggles.indices.contains(i) && breakToggles[i]) ? Color.blue : .secondary)
                                Text("S\(i + 1)")
                                    .font(.caption2)
                                    .foregroundStyle(.primary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer()

                if trip.registration == nil {
                    Button {
                        regFocused = true
                    } label: {
                        Label("Add Registration", systemImage: "exclamationmark.triangle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.6, green: 0.1, blue: 0.1))
                    .controlSize(.small)
                } else {
                    Button("Generate", systemImage: "wand.and.stars") { onGenerate() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                }

                Button("List", systemImage: "list.bullet") { onListOnly() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 3)
    }

    // MARK: - Helpers

    private func syncBreakToggles() {
        let count = trip.flightInfo.sectors
        if breakToggles.count < count {
            breakToggles.append(contentsOf: Array(repeating: false, count: count - breakToggles.count))
        } else if breakToggles.count > count {
            breakToggles = Array(breakToggles.prefix(count))
        }
    }

    private var aircraftTypeText: String {
        guard let reg = trip.registration,
              let typeCode = FleetRegistry.fleet[reg],
              let acType = AircraftTypes.types[typeCode] else { return "" }
        return acType.description
    }

    private var fullRegistration: String {
        let suffix = regDraft.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        return suffix.isEmpty ? "" : "A6\(suffix)"
    }

    private var regForegroundStyle: Color {
        let full = fullRegistration
        if full.isEmpty { return .orange }
        return FleetRegistry.fleet[full] != nil ? .primary : .red
    }

    private func commitRegistration() {
        let suffix = regDraft.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        regDraft = suffix
        let newValue: String? = suffix.isEmpty ? nil : "A6\(suffix)"
        if trip.registration != newValue {
            trip.registration = newValue
        }
    }

    private func suffixFromRegistration(_ reg: String?) -> String {
        guard let reg else { return "" }
        let upper = reg.uppercased()
        if upper.hasPrefix("A6-") { return String(upper.dropFirst(3)) }
        if upper.hasPrefix("A6") { return String(upper.dropFirst(2)) }
        return upper
    }

    private var durationText: String {
        trip.flightInfo.durations
            .map { String(format: "%.1fh", $0) }
            .joined(separator: " → ")
    }
}
