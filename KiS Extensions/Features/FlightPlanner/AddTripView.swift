import SwiftUI
import SwiftData

// MARK: - Sector Draft

/// Temporary state for a sector being entered in the form.
struct SectorDraft: Identifiable {
    let id = UUID()
    /// When editing, the id of the existing PlannedSector this draft maps to.
    /// Nil for newly-added sectors.
    var sourceSectorID: UUID? = nil
    var flightNumber: String = ""
    var date: Date = Date()
    var departureStation: String = ""
    var arrivalStation: String = ""
    var departureDate: Date = Date()
    var departureTime: Date = Calendar.current.date(
        bySettingHour: 12, minute: 0, second: 0, of: Date()
    ) ?? Date()
    var arrivalDate: Date = Date()
    var arrivalTime: Date = Calendar.current.date(
        bySettingHour: 12, minute: 0, second: 0, of: Date()
    ) ?? Date()
    var registration: String = ""
    var flightTime: String = ""
    var isLayover: Bool = true

    var isComplete: Bool {
        !flightNumber.trimmingCharacters(in: .whitespaces).isEmpty
        && EmiratesDestinations.isValid(departureStation)
        && EmiratesDestinations.isValid(arrivalStation)
    }

    init() {}

    init(from sector: PlannedSector) {
        self.sourceSectorID = sector.id
        self.flightNumber = Self.stripEKPrefix(sector.flightNumber)
        self.date = sector.date
        self.departureStation = sector.departureStation
        self.arrivalStation = sector.arrivalStation
        self.departureDate = sector.date
        self.arrivalDate = sector.date
        self.registration = sector.registration ?? ""
        self.flightTime = sector.savedFlightTime ?? ""
        self.isLayover = sector.savedIsLayover ?? true
        let cal = Calendar.current
        let noon = cal.date(bySettingHour: 12, minute: 0, second: 0, of: sector.date) ?? sector.date
        self.departureTime = Self.dateFrom(hhmm: sector.departureTime, on: sector.date) ?? noon
        self.arrivalTime = Self.dateFrom(hhmm: sector.arrivalTime, on: sector.date) ?? noon
    }

    static func stripEKPrefix(_ value: String) -> String {
        var s = value.trimmingCharacters(in: .whitespaces)
        if s.uppercased().hasPrefix("EK") {
            s = String(s.dropFirst(2)).trimmingCharacters(in: .whitespaces)
        }
        return s
    }

    private static func dateFrom(hhmm: String, on date: Date) -> Date? {
        let parts = hhmm.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return nil }
        return Calendar.current.date(bySettingHour: parts[0], minute: parts[1], second: 0, of: date)
    }
}

// MARK: - Add Trip View

struct AddTripView: View {
    let flightToEdit: PlannedFlight?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var sectors: [SectorDraft] = [SectorDraft(), SectorDraft()]
    @State private var tripNumber: String = ""
    @State private var tripType: TripType = .turnaround

    init(flightToEdit: PlannedFlight? = nil) {
        self.flightToEdit = flightToEdit
        if let trip = flightToEdit {
            _tripNumber = State(initialValue: trip.tripNumber)
            _tripType = State(initialValue: trip.tripType)
            _tripDate = State(initialValue: trip.flightDate)
            let drafts = trip.sortedSectors.map { SectorDraft(from: $0) }
            // Ensure at least 2 sectors when editing legacy single-sector trips.
            let padded = drafts.count >= 2 ? drafts : drafts + Array(repeating: SectorDraft(), count: 2 - drafts.count)
            _sectors = State(initialValue: padded)
        }
    }

    private var isEditing: Bool { flightToEdit != nil }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    /// Trip numbers are 4 numerical digits beginning with 2, 6, or 7.
    private var isTripNumberValid: Bool {
        let trimmed = tripNumber.trimmingCharacters(in: .whitespaces)
        let digitsOnly = trimmed.filter(\.isNumber)
        return digitsOnly.count == 4
            && (digitsOnly.hasPrefix("2") || digitsOnly.hasPrefix("6") || digitsOnly.hasPrefix("7"))
    }

    private var canSave: Bool {
        isTripNumberValid
            && sectors.count >= 2
            && sectors.allSatisfy { $0.isComplete }
    }

    @State private var tripDate: Date = Date()
    @State private var showDeleteConfirmation = false
    @FocusState private var focusedFlightIndex: Int?

    // MARK: - Body

    var body: some View {
        Form {
            // MARK: Trip Details
            Section {
                HStack(spacing: 12) {
                    labeledField("Trip no.", width: 100) {
                        TextField("6001", text: $tripNumber)
                            .keyboardType(.numberPad)
                            .autocorrectionDisabled()
                            .onChange(of: tripNumber) { _, newValue in
                                let filtered = String(newValue.filter(\.isNumber).prefix(4))
                                if filtered != newValue {
                                    tripNumber = filtered
                                }
                                autoFillFlightNumber()
                            }
                    }

                    labeledField("Type", width: 140) {
                        Picker("", selection: $tripType) {
                            ForEach(TripType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .labelsHidden()
                    }

                    labeledField("Date", width: 160) {
                        DatePicker("", selection: $tripDate, displayedComponents: .date)
                            .labelsHidden()
                            .onChange(of: tripDate) { _, newDate in
                                for i in sectors.indices {
                                    sectors[i].date = newDate
                                    sectors[i].departureDate = newDate
                                    sectors[i].arrivalDate = newDate
                                }
                            }
                    }

                    Spacer()
                }
            } header: {
                Text("Trip Details")
            } footer: {
                if !tripNumber.isEmpty && !isTripNumberValid {
                    Text("4 digits starting with 2, 6, or 7")
                        .foregroundStyle(.red)
                } else if sectors.count < 2 {
                    Text("A trip requires at least 2 sectors")
                        .foregroundStyle(.red)
                }
            }

            // MARK: Sectors
            ForEach(Array(sectors.enumerated()), id: \.element.id) { index, _ in
                if index > 0 {
                    layoverRow(from: index - 1, to: index)
                }
                sectorSection(index: index)
            }

            Button {
                addSector()
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Sector")
                }
            }

        }
        .safeAreaInset(edge: .bottom) {
            if isEditing {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Text("Delete Trip")
                        .font(.body)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }
        }
        .navigationTitle(isEditing ? "Edit Trip" : "Add Trip")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { saveTrip() }
                    .disabled(!canSave)
            }
        }
        .onChange(of: focusedFlightIndex) { old, _ in
            if let idx = old, idx < sectors.count, !sectors[idx].flightNumber.isEmpty {
                sectors[idx].flightNumber = padFlightDigits(sectors[idx].flightNumber)
            }
        }
        .alert("Delete this trip?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { deleteTrip() }
        } message: {
            Text("This action cannot be undone. The trip and all its sectors will be permanently removed.")
        }
    }

    // MARK: - Sector Section

    @ViewBuilder
    private func sectorSection(index: Int) -> some View {
        Section {
            HStack(spacing: 12) {
                labeledField("Flight", width: 120) {
                    HStack(spacing: 2) {
                        Text("EK")
                            .font(.caption.weight(.semibold).monospaced())
                            .foregroundStyle(.secondary)
                        TextField("0602", text: $sectors[index].flightNumber)
                            .keyboardType(.numberPad)
                            .autocorrectionDisabled()
                            .focused($focusedFlightIndex, equals: index)
                            .onChange(of: sectors[index].flightNumber) { _, newValue in
                                let digitsOnly = String(newValue.filter(\.isNumber).prefix(4))
                                if digitsOnly != newValue {
                                    sectors[index].flightNumber = digitsOnly
                                }
                            }
                    }
                }

                labeledField("From", width: 80) {
                    HStack(spacing: 4) {
                        TextField("DXB", text: $sectors[index].departureStation)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .onChange(of: sectors[index].departureStation) { _, newValue in
                                if newValue.count > 3 {
                                    sectors[index].departureStation = String(newValue.prefix(3))
                                }
                            }
                        stationValidationIcon(sectors[index].departureStation)
                    }
                }

                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                    .padding(.top, 14)

                labeledField("To", width: 80) {
                    HStack(spacing: 4) {
                        TextField("LHR", text: $sectors[index].arrivalStation)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .onChange(of: sectors[index].arrivalStation) { _, newValue in
                                if newValue.count > 3 {
                                    sectors[index].arrivalStation = String(newValue.prefix(3))
                                }
                                let nextIndex = index + 1
                                if nextIndex < sectors.count {
                                    sectors[nextIndex].departureStation = String(newValue.prefix(3)).uppercased()
                                }
                            }
                        stationValidationIcon(sectors[index].arrivalStation)
                    }
                }

                labeledField("Date", width: 160) {
                    DatePicker("", selection: $sectors[index].departureDate, displayedComponents: .date)
                        .labelsHidden()
                }

                labeledField("Dep. time", width: 100) {
                    DatePicker("", selection: $sectors[index].departureTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .environment(\.locale, Locale(identifier: "en_GB"))
                }

                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                    .padding(.top, 14)

                labeledField("Arr. time", width: 100) {
                    DatePicker("", selection: $sectors[index].arrivalTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .environment(\.locale, Locale(identifier: "en_GB"))
                }

                labeledField("Flt. time", width: 80) {
                    TextField("07:30", text: $sectors[index].flightTime)
                        .keyboardType(.numbersAndPunctuation)
                        .autocorrectionDisabled()
                        .onChange(of: sectors[index].flightTime) { _, newValue in
                            let allowed = newValue.filter { $0.isNumber || $0 == ":" }
                            if allowed != newValue {
                                sectors[index].flightTime = allowed
                            }
                        }
                }

                labeledField("Reg.", width: 100) {
                    HStack(spacing: 2) {
                        Text("A6-")
                            .font(.caption.weight(.semibold).monospaced())
                            .foregroundStyle(.secondary)
                        TextField("EWJ", text: $sectors[index].registration)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .onChange(of: sectors[index].registration) { _, newValue in
                                let filtered = String(newValue.uppercased().filter(\.isLetter).prefix(3))
                                if filtered != newValue {
                                    sectors[index].registration = filtered
                                }
                            }
                    }
                }

                Spacer()
            }
        } header: {
            HStack {
                Text("Sector \(index + 1)")
                Spacer()
                if sectors.count > 2 {
                    Button("Remove") {
                        removeSector(at: index)
                    }
                    .font(.caption)
                    .foregroundStyle(.red)
                }
            }
        }
    }

    // MARK: - Layover Row

    /// Display-only gap row between two sectors. Type (layover/transit/continuous)
    /// is derived from the calculated gap and matching registration, not a toggle.
    @ViewBuilder
    private func layoverRow(from prevIndex: Int, to nextIndex: Int) -> some View {
        let prev = sectors[prevIndex]
        let station = prev.arrivalStation.uppercased()
        let stationLabel = station.isEmpty ? "..." : station

        let minutes = gapMinutes(from: sectors[prevIndex], to: sectors[nextIndex])
        let isLayover = minutes > TripRules.continuousMaxMinutes
        let continuous = !isLayover && sameRegistration(sectors[prevIndex], sectors[nextIndex])
        let duration = layoverDuration(from: prevIndex, to: nextIndex)

        HStack(spacing: 6) {
            Image(systemName: gapIcon(isLayover: isLayover, continuous: continuous))
                .foregroundStyle(gapColor(isLayover: isLayover, continuous: continuous))
                .font(.caption)
            Text(gapLabel(station: stationLabel, isLayover: isLayover,
                          continuous: continuous, duration: duration))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 16)
    }

    // MARK: - Gap Presentation

    private func gapIcon(isLayover: Bool, continuous: Bool) -> String {
        if isLayover { return "moon.zzz.fill" }
        return continuous ? "airplane" : "arrow.right.arrow.left"
    }

    private func gapColor(isLayover: Bool, continuous: Bool) -> Color {
        if isLayover { return .orange }
        return continuous ? .green : .blue
    }

    private func gapLabel(station: String, isLayover: Bool, continuous: Bool, duration: String?) -> String {
        if isLayover {
            return duration.map { "Layover in \(station):  \($0)" } ?? "Layover in \(station)"
        }
        if continuous {
            return duration.map { "Continuous · same aircraft ·  \($0)" } ?? "Continuous · same aircraft"
        }
        return duration.map { "Transit in \(station):  \($0)" } ?? "Transit in \(station)"
    }

    /// Continuous operation: a ground-time gap on the same registration, so the
    /// crew stay on board and keep their positions. Mirrors `TripClassifier`.
    private func isContinuousOperation(from prevIndex: Int, to nextIndex: Int) -> Bool {
        let minutes = gapMinutes(from: sectors[prevIndex], to: sectors[nextIndex])
        guard minutes <= TripRules.continuousMaxMinutes else { return false }
        return sameRegistration(sectors[prevIndex], sectors[nextIndex])
    }

    private func sameRegistration(_ a: SectorDraft, _ b: SectorDraft) -> Bool {
        let na = a.registration.uppercased().filter { $0.isLetter || $0.isNumber }
        let nb = b.registration.uppercased().filter { $0.isLetter || $0.isNumber }
        return !na.isEmpty && na == nb
    }

    /// Suggest the trip type from the current sectors. The user can still
    /// override the picker afterwards.
    private func applyTripTypeSuggestion() {
        if sectors.count >= 3 {
            tripType = .transit
        } else if sectors.count == 2 {
            let isLayover = gapMinutes(from: sectors[0], to: sectors[1]) > TripRules.continuousMaxMinutes
            tripType = isLayover ? .layover : .turnaround
        } else {
            tripType = .turnaround
        }
    }

    private func gapMinutes(from prev: SectorDraft, to next: SectorDraft) -> Int {
        let cal = Calendar.current
        let arrComps = cal.dateComponents([.hour, .minute], from: prev.arrivalTime)
        let depComps = cal.dateComponents([.hour, .minute], from: next.departureTime)
        guard let arrH = arrComps.hour, let arrM = arrComps.minute,
              let depH = depComps.hour, let depM = depComps.minute,
              let arrival = cal.date(bySettingHour: arrH, minute: arrM, second: 0, of: prev.arrivalDate),
              let departure = cal.date(bySettingHour: depH, minute: depM, second: 0, of: next.departureDate)
        else { return 0 }
        return Int(departure.timeIntervalSince(arrival) / 60)
    }

    private func layoverDuration(from prevIndex: Int, to nextIndex: Int) -> String? {
        let minutes = gapMinutes(from: sectors[prevIndex], to: sectors[nextIndex])
        guard minutes > 0 else { return nil }
        let h = minutes / 60
        let m = minutes % 60
        return String(format: "%dh %02dm", h, m)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func labeledField<Content: View>(_ label: String, width: CGFloat, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            content()
                .padding(8)
                .frame(width: width, alignment: .leading)
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.separator), lineWidth: 0.5)
                )
        }
    }

    @ViewBuilder
    private func stationValidationIcon(_ code: String) -> some View {
        let trimmed = code.trimmingCharacters(in: .whitespaces).uppercased()
        if trimmed.count == 3 {
            if EmiratesDestinations.isValid(trimmed) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.caption)
            } else {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.caption)
            }
        }
    }

    // MARK: - Actions

    /// Derives the flight digits from the trip number.
    /// First digit becomes `0`: trip 6602 → 0602, trip 2925 → 0925, trip 7001 → 0001.
    private func autoFillFlightNumber() {
        let trimmed = tripNumber.trimmingCharacters(in: .whitespaces)
        guard trimmed.count == 4,
              let first = trimmed.first,
              (first == "2" || first == "6" || first == "7") else { return }

        let flightDigits = "0" + trimmed.dropFirst()

        let current = sectors[0].flightNumber.trimmingCharacters(in: .whitespaces)
        if current.isEmpty {
            sectors[0].flightNumber = flightDigits
        }
    }

    /// Pads a digit string to 4 characters with leading zeros.
    private func padFlightDigits(_ input: String) -> String {
        let digits = input.filter(\.isNumber)
        guard !digits.isEmpty else { return input }
        return String(repeating: "0", count: max(0, 4 - digits.count)) + digits
    }

    private func addSector() {
        var newSector = SectorDraft()
        if let lastSector = sectors.last {
            if !lastSector.arrivalStation.isEmpty {
                newSector.departureStation = lastSector.arrivalStation.uppercased()
            }
            newSector.departureDate = lastSector.arrivalDate
        }
        sectors.append(newSector)
        applyTripTypeSuggestion()
    }

    private func removeSector(at index: Int) {
        guard sectors.count > 2 else { return }
        sectors.remove(at: index)
        applyTripTypeSuggestion()
    }

    private func deleteTrip() {
        guard let trip = flightToEdit else { return }
        for sector in trip.sectors {
            modelContext.delete(sector)
        }
        modelContext.delete(trip)
        try? modelContext.save()
        dismiss()
    }

    private func saveTrip() {
        guard let firstSector = sectors.first else { return }

        let lastStation = sectors.last?.arrivalStation ?? firstSector.arrivalStation
        let upperTripNumber = tripNumber.uppercased()
        let firstFlightNumber = "EK " + padFlightDigits(firstSector.flightNumber)
        let firstDeparture = firstSector.departureStation.uppercased()
        let lastArrival = lastStation.uppercased()

        if let trip = flightToEdit {
            // Update existing trip in place
            trip.tripNumber = upperTripNumber
            trip.tripType = tripType
            trip.flightNumber = firstFlightNumber
            trip.flightDate = tripDate
            trip.departure = firstDeparture
            trip.arrival = lastArrival

            // Match drafts to existing sectors by sourceSectorID so each
            // sector's saved actual-time data is preserved across edits.
            let existingByID = Dictionary(uniqueKeysWithValues: trip.sectors.map { ($0.id, $0) })
            var keptIDs = Set<UUID>()

            for (i, draft) in sectors.enumerated() {
                let derivedLayover: Bool? = i > 0
                    ? (gapMinutes(from: sectors[i - 1], to: draft) > TripRules.continuousMaxMinutes)
                    : nil
                if let sourceID = draft.sourceSectorID, let existing = existingByID[sourceID] {
                    existing.sectorIndex = i
                    existing.flightNumber = "EK " + padFlightDigits(draft.flightNumber)
                    existing.date = draft.departureDate
                    existing.departureStation = draft.departureStation.uppercased()
                    existing.arrivalStation = draft.arrivalStation.uppercased()
                    existing.departureTime = Self.timeFormatter.string(from: draft.departureTime)
                    existing.arrivalTime = Self.timeFormatter.string(from: draft.arrivalTime)
                    existing.registration = draft.registration.isEmpty ? nil : "A6\(draft.registration)"
                    existing.savedFlightTime = draft.flightTime.isEmpty ? nil : draft.flightTime
                    existing.savedIsLayover = derivedLayover
                    keptIDs.insert(existing.id)
                } else {
                    let new = PlannedSector(
                        sectorIndex: i,
                        flightNumber: "EK " + padFlightDigits(draft.flightNumber),
                        date: draft.departureDate,
                        departureStation: draft.departureStation.uppercased(),
                        arrivalStation: draft.arrivalStation.uppercased(),
                        departureTime: Self.timeFormatter.string(from: draft.departureTime),
                        arrivalTime: Self.timeFormatter.string(from: draft.arrivalTime)
                    )
                    new.savedIsLayover = derivedLayover
                    new.parentTrip = trip
                    trip.sectors.append(new)
                    keptIDs.insert(new.id)
                }
            }

            // Drop sectors the user removed during editing
            for sector in trip.sectors where !keptIDs.contains(sector.id) {
                modelContext.delete(sector)
            }
        } else {
            // Create a brand-new trip
            let flight = PlannedFlight(
                tripNumber: upperTripNumber,
                tripType: tripType,
                flightNumber: firstFlightNumber,
                flightDate: tripDate,
                departure: firstDeparture,
                arrival: lastArrival
            )

            for (i, draft) in sectors.enumerated() {
                let sector = PlannedSector(
                    sectorIndex: i,
                    flightNumber: "EK " + padFlightDigits(draft.flightNumber),
                    date: draft.departureDate,
                    departureStation: draft.departureStation.uppercased(),
                    arrivalStation: draft.arrivalStation.uppercased(),
                    departureTime: Self.timeFormatter.string(from: draft.departureTime),
                    arrivalTime: Self.timeFormatter.string(from: draft.arrivalTime)
                )
                sector.registration = draft.registration.isEmpty ? nil : "A6\(draft.registration)"
                sector.savedFlightTime = draft.flightTime.isEmpty ? nil : draft.flightTime
                sector.savedIsLayover = i > 0
                    ? (gapMinutes(from: sectors[i - 1], to: draft) > TripRules.continuousMaxMinutes)
                    : nil
                sector.parentTrip = flight
                flight.sectors.append(sector)
            }

            modelContext.insert(flight)
        }

        try? modelContext.save()
        dismiss()
    }
}
