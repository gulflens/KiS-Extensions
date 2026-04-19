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
                if upcomingIndices.isEmpty && olderIndices.isEmpty {
                    ContentUnavailableView("No Trips", systemImage: "airplane", description: Text("Import crew data to see trips here."))
                        .frame(maxWidth: .infinity, minHeight: 300)
                } else {
                    if !upcomingIndices.isEmpty {
                        VStack(spacing: 16) {
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
                                VStack(spacing: 16) {
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
        .background(Color(.systemGroupedBackground))
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
    @FocusState private var regFocused: Bool

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd MMM yyyy"
        return f
    }()

    private static let dayOfWeekFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: Header
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 10) {
                    Text("EK \(trip.flightInfo.flightNumber)")
                        .font(.title2.bold())

                    Text(trip.flightInfo.flightLegs.joined(separator: " — "))
                        .font(.title2.bold().monospaced())

                    if trip.flightInfo.isULR {
                        Text("ULR")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.red)
                            .clipShape(Capsule())
                    }

                    Spacer()
                }

                HStack(spacing: 12) {
                    Text(Self.dateFormatter.string(from: trip.flightInfo.flightDate))
                        .font(.subheadline.weight(.semibold))
                    Text(Self.dayOfWeekFormatter.string(from: trip.flightInfo.flightDate))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))

            Divider()

            // MARK: Details Grid
            VStack(alignment: .leading, spacing: 16) {
                // Aircraft row
                HStack(spacing: 16) {
                    detailLabel("Aircraft")

                    HStack(spacing: 2) {
                        Image(systemName: "airplane")
                            .font(.subheadline)
                            .foregroundStyle(regDraft.isEmpty ? .orange : .primary)
                            .padding(.trailing, 4)

                        Text("A6-")
                            .font(.subheadline.weight(.semibold).monospaced())
                            .foregroundStyle(.primary)
                            .fixedSize()

                        TextField("___", text: $regDraft)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .font(.subheadline.weight(.semibold).monospaced())
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
                                syncHasBreaks()
                            }
                            .onChange(of: trip.registration) { _, newValue in
                                if !regFocused { regDraft = suffixFromRegistration(newValue) }
                            }
                            .frame(width: 40)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(.systemGray6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(regDraft.isEmpty ? Color.orange.opacity(0.5) : Color(.systemGray4), lineWidth: 1)
                    )

                    if !aircraftTypeText.isEmpty {
                        Text(aircraftTypeText)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }

                    if let features = aircraftFeaturesText {
                        Text(features)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.red)
                    }

                    if regDraft.isEmpty {
                        Label("No registration", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.red)
                    }

                    Spacer()
                }

                Divider()

                // Sectors & crew row
                HStack(spacing: 24) {
                    HStack(spacing: 16) {
                        detailLabel("Sectors")

                        HStack(spacing: 4) {
                            Button {
                                if trip.flightInfo.sectors > 1 {
                                    trip.flightInfo.sectors -= 1
                                    syncHasBreaks()
                                }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .disabled(trip.flightInfo.sectors <= 1)

                            Text("\(trip.flightInfo.sectors)")
                                .font(.title3.weight(.semibold).monospaced())
                                .frame(width: 24)
                                .multilineTextAlignment(.center)

                            Button {
                                trip.flightInfo.sectors += 1
                                syncHasBreaks()
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Divider().frame(height: 20)

                    HStack(spacing: 8) {
                        detailLabel("Crew")
                        Text("\(trip.crewMembers.count)")
                            .font(.title3.weight(.semibold).monospaced())
                    }

                    Divider().frame(height: 20)

                    HStack(spacing: 8) {
                        detailLabel("Duration")
                        Text(durationText)
                            .font(.subheadline.weight(.semibold).monospaced())
                    }

                    Spacer()
                }

                Divider()

                // Breaks row
                HStack(spacing: 16) {
                    detailLabel("Breaks")

                    ForEach(0..<trip.flightInfo.sectors, id: \.self) { i in
                        Button {
                            if trip.flightInfo.hasBreaks.indices.contains(i) {
                                trip.flightInfo.hasBreaks[i].toggle()
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: (trip.flightInfo.hasBreaks.indices.contains(i) && trip.flightInfo.hasBreaks[i]) ? "checkmark.square.fill" : "square")
                                    .font(.title3)
                                    .foregroundStyle((trip.flightInfo.hasBreaks.indices.contains(i) && trip.flightInfo.hasBreaks[i]) ? Color.accentColor : .secondary)
                                Text("Sector \(i + 1)")
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()
                }

                // Rest facility picker
                if facilityOptions.count > 1 {
                    Divider()

                    HStack(spacing: 16) {
                        detailLabel("Rest")

                        Picker("Rest facility", selection: facilityBinding) {
                            ForEach(facilityOptions, id: \.rawValue) { facility in
                                Text(facility.label).tag(facility.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 300)

                        Spacer()
                    }
                }
            }
            .padding(16)

            Divider()

            // MARK: Action Buttons
            HStack(spacing: 12) {
                Spacer()

                Button {
                    onListOnly()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "list.bullet")
                        Text("View Crew List")
                    }
                    .frame(minWidth: 160)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                if trip.registration != nil {
                    Button {
                        onGenerate()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "wand.and.stars")
                            Text("Generate Positions")
                        }
                        .frame(minWidth: 200)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                } else {
                    Button {
                        regFocused = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text("Add Registration to Generate")
                        }
                        .frame(minWidth: 200)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.6, green: 0.1, blue: 0.1))
                    .controlSize(.large)
                }

                Spacer()
            }
            .padding(16)
            .background(Color(.systemGroupedBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }

    // MARK: - Subviews

    private func detailLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(width: 64, alignment: .trailing)
    }

    // MARK: - Helpers

    private var facilityOptions: [Facility] {
        let suffix = regDraft.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard suffix.count == 3,
              let entry = FleetLoader.shared.entry(forSuffix: suffix) else { return [] }
        return entry.facilityOptions
    }

    private var facilityBinding: Binding<String> {
        Binding(
            get: {
                if let selected = trip.flightInfo.selectedFacility { return selected }
                return facilityOptions.first?.rawValue ?? ""
            },
            set: { newValue in
                trip.flightInfo.selectedFacility = newValue
            }
        )
    }

    private func syncHasBreaks() {
        let count = trip.flightInfo.sectors
        if trip.flightInfo.hasBreaks.count < count {
            trip.flightInfo.hasBreaks.append(contentsOf: Array(repeating: false, count: count - trip.flightInfo.hasBreaks.count))
        } else if trip.flightInfo.hasBreaks.count > count {
            trip.flightInfo.hasBreaks = Array(trip.flightInfo.hasBreaks.prefix(count))
        }
    }

    private var aircraftTypeText: String {
        guard let reg = trip.registration,
              let typeCode = FleetRegistry.fleet[reg],
              let acType = AircraftTypes.types[typeCode] else { return "" }
        return acType.description
    }

    private var aircraftFeaturesText: String? {
        let suffix = regDraft.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard suffix.count == 3,
              let entry = FleetLoader.shared.entry(forSuffix: suffix) else { return nil }
        var parts: [String] = []
        parts.append(entry.crc ?? "No CRC")
        parts.append(entry.hasCrewSeats ? "Crew seats" : "No crew seats")
        parts.append("\(entry.capacity) pax")
        parts.append(entry.configuration)
        return parts.joined(separator: " · ")
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
