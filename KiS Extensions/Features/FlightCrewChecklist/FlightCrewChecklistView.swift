import SwiftUI

// MARK: - Flight Crew Checklist View

struct FlightCrewChecklistView: View {

    // MARK: - Inputs

    @State private var takeoffDate: Date
    @State private var durationHours: Int
    @State private var durationMinutes: Int
    @State private var initialCallOverride: Date? = nil
    @State private var callIntervalMinutes: Int = 30
    @State private var shareURL: URL? = nil
    @State private var didLoadFromSector = false

    private let sector: PlannedSector?

    init(
        initialTakeoff: Date? = nil,
        initialDurationMinutes: Int? = nil,
        sector: PlannedSector? = nil
    ) {
        _takeoffDate = State(initialValue: initialTakeoff ?? Self.defaultTakeoff())
        let totalMinutes = initialDurationMinutes ?? (6 * 60)
        _durationHours = State(initialValue: totalMinutes / 60)
        _durationMinutes = State(initialValue: totalMinutes % 60)
        self.sector = sector
    }

    // MARK: - Crew

    @State private var captain1 = CrewSlot()
    @State private var captain2: CrewSlot? = nil
    @State private var firstOfficer1 = CrewSlot()
    @State private var firstOfficer2: CrewSlot? = nil

    // MARK: - Constants

    private static let topOfDescentOffsetMin = 30
    private static let initialCallOffsetMin = 45
    private static let twentyToTopOffsetMin = 20

    // MARK: - Derived Times

    private var durationSeconds: TimeInterval {
        TimeInterval(durationHours * 3600 + durationMinutes * 60)
    }

    private var landingDate: Date {
        takeoffDate.addingTimeInterval(durationSeconds)
    }

    private var topOfDescentDate: Date {
        landingDate.addingTimeInterval(-TimeInterval(Self.topOfDescentOffsetMin * 60))
    }

    private var twentyToTopDate: Date {
        topOfDescentDate.addingTimeInterval(-TimeInterval(Self.twentyToTopOffsetMin * 60))
    }

    private var autoInitialCallDate: Date {
        let rawInitial = takeoffDate.addingTimeInterval(TimeInterval(Self.initialCallOffsetMin * 60))
        let rounded = Self.roundToNearestHalfHour(rawInitial)
        // If rounding would push the call beyond +45min from takeoff,
        // keep the call within the 45-minute window (unrounded).
        return rounded > rawInitial ? rawInitial : rounded
    }

    private var initialCallDate: Date {
        initialCallOverride ?? autoInitialCallDate
    }

    // MARK: - Schedule

    private var scheduleEntries: [ScheduleEntry] {
        guard durationSeconds > 0 else { return [] }

        let intervalSeconds = TimeInterval(callIntervalMinutes * 60)
        let firstCall: Date
        let cadenceStart: Date

        if let override = initialCallOverride {
            firstCall = override
            cadenceStart = Self.roundToNearestHalfHour(override.addingTimeInterval(intervalSeconds))
        } else {
            let rawInitial = takeoffDate.addingTimeInterval(TimeInterval(Self.initialCallOffsetMin * 60))
            let rounded = Self.roundToNearestHalfHour(rawInitial)
            if rounded > rawInitial {
                firstCall = rawInitial
                cadenceStart = Self.roundToNearestHalfHour(rawInitial.addingTimeInterval(intervalSeconds))
            } else {
                firstCall = rounded
                cadenceStart = rounded.addingTimeInterval(intervalSeconds)
            }
        }

        guard twentyToTopDate > firstCall else { return [] }

        var entries: [ScheduleEntry] = [
            ScheduleEntry(time: firstCall, note: "Initial call")
        ]

        var current = cadenceStart
        while current < twentyToTopDate {
            entries.append(ScheduleEntry(time: current, note: ""))
            current = current.addingTimeInterval(intervalSeconds)
        }

        entries.append(ScheduleEntry(
            time: twentyToTopDate,
            note: "20 minutes to top of descent — final crew brief"
        ))

        return entries
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                inputsCard
                crewCard
                scheduleCard
                guidelinesCard
            }
            .padding()
            .frame(maxWidth: 900, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Flight Crew Checklist")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadFromSector() }
        .onChange(of: persistenceSnapshot) { saveToSector() }
    }

    // MARK: - Sector Persistence

    private struct PersistenceSnapshot: Equatable {
        let c1Name: String, c1Role: String
        let c2Name: String?, c2Role: String?
        let f1Name: String, f1Role: String
        let f2Name: String?, f2Role: String?
        let override: Date?
        let interval: Int
    }

    private var persistenceSnapshot: PersistenceSnapshot {
        PersistenceSnapshot(
            c1Name: captain1.name, c1Role: captain1.role.rawValue,
            c2Name: captain2?.name, c2Role: captain2?.role.rawValue,
            f1Name: firstOfficer1.name, f1Role: firstOfficer1.role.rawValue,
            f2Name: firstOfficer2?.name, f2Role: firstOfficer2?.role.rawValue,
            override: initialCallOverride,
            interval: callIntervalMinutes
        )
    }

    private func loadFromSector() {
        guard !didLoadFromSector else { return }
        didLoadFromSector = true
        guard let sector,
              let data = sector.flightCrewChecklistJSON,
              let payload = try? JSONDecoder().decode(SectorFlightCrewChecklistData.self, from: data)
        else { return }

        captain1 = CrewSlot(
            name: payload.captain1Name,
            role: CrewRole(rawValue: payload.captain1Role) ?? .operating
        )
        if let n = payload.captain2Name, let r = payload.captain2Role {
            captain2 = CrewSlot(name: n, role: CrewRole(rawValue: r) ?? .operating)
        }
        firstOfficer1 = CrewSlot(
            name: payload.firstOfficer1Name,
            role: CrewRole(rawValue: payload.firstOfficer1Role) ?? .operating
        )
        if let n = payload.firstOfficer2Name, let r = payload.firstOfficer2Role {
            firstOfficer2 = CrewSlot(name: n, role: CrewRole(rawValue: r) ?? .operating)
        }
        initialCallOverride = payload.initialCallOverride
        if let interval = payload.callIntervalMinutes {
            callIntervalMinutes = interval
        }
    }

    private func saveToSector() {
        guard let sector, didLoadFromSector else { return }
        let payload = SectorFlightCrewChecklistData(
            captain1Name: captain1.name,
            captain1Role: captain1.role.rawValue,
            captain2Name: captain2?.name,
            captain2Role: captain2?.role.rawValue,
            firstOfficer1Name: firstOfficer1.name,
            firstOfficer1Role: firstOfficer1.role.rawValue,
            firstOfficer2Name: firstOfficer2?.name,
            firstOfficer2Role: firstOfficer2?.role.rawValue,
            initialCallOverride: initialCallOverride,
            callIntervalMinutes: callIntervalMinutes
        )
        sector.flightCrewChecklistJSON = try? JSONEncoder().encode(payload)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Flight Crew Checklist")
                    .font(.title.bold())
                Text("Plan crew calls and brief duties around takeoff, top of descent, and landing.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                shareChecklist()
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
                    .font(.subheadline.weight(.medium))
            }
            .buttonStyle(.bordered)
            Button {
                printChecklist()
            } label: {
                Label("Print", systemImage: "printer")
                    .font(.subheadline.weight(.medium))
            }
            .buttonStyle(.bordered)
        }
        .sheet(item: shareURLBinding) { wrapper in
            ShareSheet(items: [wrapper.url]) {
                shareURL = nil
            }
        }
    }

    private struct ShareURLWrapper: Identifiable {
        let id = UUID()
        let url: URL
    }

    private var shareURLBinding: Binding<ShareURLWrapper?> {
        Binding(
            get: { shareURL.map { ShareURLWrapper(url: $0) } },
            set: { shareURL = $0?.url }
        )
    }

    private func shareChecklist() {
        let label: String = {
            guard let sector else { return "" }
            return "\(sector.departureStation) - \(sector.arrivalStation)"
        }()
        let url = FlightCrewChecklistPDFExporter.makePDF(
            takeoff: takeoffDate,
            landing: landingDate,
            topOfDescent: topOfDescentDate,
            twentyToTop: twentyToTopDate,
            durationMinutes: durationHours * 60 + durationMinutes,
            crew: buildExporterCrew(),
            schedule: scheduleEntries.map {
                FlightCrewChecklistPDFExporter.ScheduleRow(time: $0.time, note: $0.note)
            },
            sectorLabel: label
        )
        shareURL = url
    }

    private func buildExporterCrew() -> [FlightCrewChecklistPDFExporter.CrewRow] {
        chainOfCommand().map {
            FlightCrewChecklistPDFExporter.CrewRow(
                role: $0.role,
                name: $0.slot.name,
                assignment: $0.slot.role.rawValue
            )
        }
    }

    // MARK: - Printing

    private func printChecklist() {
        let crewRows = chainOfCommand().map {
            FlightCrewChecklistPrinter.CrewRow(
                role: $0.role,
                name: $0.slot.name,
                assignment: $0.slot.role.rawValue
            )
        }

        let scheduleRows = scheduleEntries.map {
            FlightCrewChecklistPrinter.ScheduleRow(time: $0.time, note: $0.note)
        }

        let label: String = {
            guard let sector else { return "" }
            return "\(sector.departureStation) - \(sector.arrivalStation)"
        }()

        FlightCrewChecklistPrinter.print(
            takeoff: takeoffDate,
            landing: landingDate,
            topOfDescent: topOfDescentDate,
            twentyToTop: twentyToTopDate,
            durationMinutes: durationHours * 60 + durationMinutes,
            crew: crewRows,
            schedule: scheduleRows,
            sectorLabel: label
        )
    }

    /// Returns the crew ordered by chain of command:
    /// Operating Captain → Operating First Officer → Augmenting Captain → Augmenting First Officer.
    /// Only applied to print/share output, not the input view.
    private func chainOfCommand() -> [(role: String, slot: CrewSlot)] {
        var entries: [(role: String, slot: CrewSlot)] = [
            ("Captain", captain1)
        ]
        if let c2 = captain2 { entries.append(("Captain", c2)) }
        entries.append(("First Officer", firstOfficer1))
        if let f2 = firstOfficer2 { entries.append(("First Officer", f2)) }

        return entries.sorted { lhs, rhs in
            let lhsAssign = lhs.slot.role == .operating ? 0 : 1
            let rhsAssign = rhs.slot.role == .operating ? 0 : 1
            if lhsAssign != rhsAssign { return lhsAssign < rhsAssign }
            let lhsRole = lhs.role == "Captain" ? 0 : 1
            let rhsRole = rhs.role == "Captain" ? 0 : 1
            return lhsRole < rhsRole
        }
    }

    // MARK: - Inputs Card

    private var inputsCard: some View {
        card("Flight Times") {
            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Take off")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    steppedPicker(time: $takeoffDate, timeZone: .dubai)
                }

                Spacer(minLength: 16)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Flight duration")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    steppedPicker(time: durationBinding, timeZone: Self.durationTZ)
                }

                Spacer(minLength: 16)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("Initial call")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        if initialCallOverride != nil {
                            Button {
                                initialCallOverride = nil
                            } label: {
                                Label("Auto", systemImage: "arrow.counterclockwise")
                                    .font(.caption2)
                                    .labelStyle(.titleAndIcon)
                            }
                        }
                    }
                    steppedPicker(time: initialCallBinding, timeZone: .dubai)
                }

                Spacer(minLength: 16)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Call interval")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Picker("", selection: $callIntervalMinutes) {
                        Text("30 min").tag(30)
                        Text("45 min").tag(45)
                        Text("1 hr").tag(60)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }
            }
        }
    }

    @ViewBuilder
    private func steppedPicker(time: Binding<Date>, timeZone: TimeZone) -> some View {
        HStack(spacing: 8) {
            Button {
                time.wrappedValue = time.wrappedValue.addingTimeInterval(-60)
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(.red, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .buttonStyle(.plain)

            DatePicker("", selection: time, displayedComponents: [.hourAndMinute])
                .labelsHidden()
                .datePickerStyle(.compact)
                .environment(\.locale, Locale(identifier: "en_GB"))
                .environment(\.timeZone, timeZone)

            Button {
                time.wrappedValue = time.wrappedValue.addingTimeInterval(60)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(Color(red: 0.0, green: 0.5, blue: 0.0), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private var initialCallBinding: Binding<Date> {
        Binding(
            get: { initialCallDate },
            set: { initialCallOverride = $0 }
        )
    }

    private static let durationTZ = TimeZone(identifier: "UTC")!

    private var durationBinding: Binding<Date> {
        Binding(
            get: {
                var cal = Calendar.current
                cal.timeZone = Self.durationTZ
                let base = cal.startOfDay(for: Date(timeIntervalSinceReferenceDate: 0))
                return cal.date(
                    bySettingHour: durationHours,
                    minute: durationMinutes,
                    second: 0,
                    of: base
                ) ?? base
            },
            set: { newValue in
                var cal = Calendar.current
                cal.timeZone = Self.durationTZ
                let comps = cal.dateComponents([.hour, .minute], from: newValue)
                durationHours = comps.hour ?? 0
                durationMinutes = comps.minute ?? 0
            }
        )
    }

    // MARK: - Key Times Card

    private var keyTimesCard: some View {
        card("Key Times") {
            VStack(spacing: 8) {
                keyTimeRow("Flight duration", value: formatDuration(durationSeconds))
                Divider()
                keyTimeRow("Take off", value: Self.timeFormatter.string(from: takeoffDate))
                Divider()
                keyTimeRow("20 to top", value: Self.timeFormatter.string(from: twentyToTopDate))
                Divider()
                keyTimeRow("Top of descent", value: Self.timeFormatter.string(from: topOfDescentDate))
                Divider()
                keyTimeRow("Landing", value: Self.timeFormatter.string(from: landingDate))
            }
        }
    }

    private func keyTimeRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.headline.monospacedDigit())
        }
    }

    // MARK: - Crew Card

    private var crewCard: some View {
        card("Flight Crew") {
            VStack(alignment: .leading, spacing: 16) {
                crewGroup(
                    title: "Captain",
                    first: $captain1,
                    second: $captain2
                )
                Divider()
                crewGroup(
                    title: "First Officer",
                    first: $firstOfficer1,
                    second: $firstOfficer2
                )
            }
        }
    }

    @ViewBuilder
    private func crewGroup(title: String, first: Binding<CrewSlot>, second: Binding<CrewSlot?>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.subheadline.bold())
                Spacer()
                Button {
                    if second.wrappedValue == nil {
                        second.wrappedValue = CrewSlot()
                    } else {
                        second.wrappedValue = nil
                    }
                } label: {
                    Label(
                        second.wrappedValue == nil ? "Add second \(title.lowercased())" : "Remove second \(title.lowercased())",
                        systemImage: second.wrappedValue == nil ? "plus.circle" : "minus.circle"
                    )
                    .labelStyle(.titleAndIcon)
                    .font(.caption)
                }
            }

            crewSlotRow(slot: first, placeholder: "\(title) 1 name")
            if second.wrappedValue != nil {
                crewSlotRow(
                    slot: Binding(
                        get: { second.wrappedValue ?? CrewSlot() },
                        set: { second.wrappedValue = $0 }
                    ),
                    placeholder: "\(title) 2 name"
                )
            }
        }
    }

    private func crewSlotRow(slot: Binding<CrewSlot>, placeholder: String) -> some View {
        HStack(spacing: 12) {
            TextField(placeholder, text: slot.name)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.words)

            Picker("", selection: slot.role) {
                ForEach(CrewRole.allCases) { role in
                    Text(role.rawValue).tag(role)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .frame(width: 220)
        }
    }

    // MARK: - Schedule Card

    private var scheduleCard: some View {
        card("Call Schedule") {
            if scheduleEntries.isEmpty {
                Text("Enter take off time and a positive flight duration to generate the call schedule.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 0) {
                    HStack {
                        Text("Time")
                            .font(.caption.bold())
                            .frame(width: 110, alignment: .leading)
                            .foregroundStyle(.secondary)
                        Text("Notes")
                            .font(.caption.bold())
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color(.systemGroupedBackground))

                    Divider()

                    ForEach(Array(scheduleEntries.enumerated()), id: \.element.id) { index, entry in
                        HStack {
                            Text(Self.timeFormatter.string(from: entry.time))
                                .font(.headline.monospacedDigit())
                                .frame(width: 110, alignment: .leading)
                            Text(entry.note)
                                .font(.subheadline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundStyle(entry.note.isEmpty ? .tertiary : .primary)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)

                        if index < scheduleEntries.count - 1 {
                            Divider()
                        }
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }

    // MARK: - Guidelines Card

    private var guidelinesCard: some View {
        card("Guidelines") {
            VStack(alignment: .leading, spacing: 18) {
                Text("Cabin crew's first interaction with the flight crew is during the pre-flight briefing. Flight-crew comfort and well-being is the responsibility of cabin crew.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                responsibleCrewSection
                Text("On A380 2/3 Class, ML2 is responsible for flight-crew service; remaining crew support when required.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                guidelineSection(
                    title: "Communication",
                    bullets: [
                        "Note from the briefing how each pilot wishes to be called.",
                        "Speak to the captain first as a sign of respect.",
                        "When entering the flight deck, wait before talking so you don't interrupt the flight crew's work.",
                        "If a pilot holds up their hand, hold — they're receiving communication.",
                        "Always answer an interphone call from the flight crew immediately."
                    ]
                )
                guidelineSection(
                    title: "General service — Do not serve",
                    bullets: [
                        "Shellfish, molluscs or crustaceans.",
                        "The same appetiser, main course or dessert for both pilots (food-poisoning risk so the flight deck remains fit to fly).",
                        "Any food from the First Class galley, including caviar.",
                        "It is prohibited to serve, consume or bring any alcoholic beverage into the flight deck."
                    ]
                )
                guidelineSection(
                    title: "General service — Must do",
                    bullets: [
                        "Take care to prevent contaminated food from reaching the flight crew.",
                        "Serve heated meals promptly to avoid serving them cold."
                    ]
                )
                guidelineSection(
                    title: "Equipment",
                    bullets: [
                        "Paper cups and lids are loaded for flight crew use only and must be used for all drinks.",
                        "For safety, glassware and mugs/cups are prohibited in the flight deck.",
                        "All drinks served in the flight deck must be served in a flight-crew paper cup with lid.",
                        "If there are no flight-crew paper cups/lids available, use paper cups + lids from other cabins (e.g. JCL, WCL)."
                    ]
                )
                guidelineSection(
                    title: "Catering — Food",
                    bullets: [
                        "CC Dry Stores — Crew Products container is loaded on all flight categories, with a dedicated drawer for the flight deck.",
                        "Snacks tray (sandwiches, fruits, etc.) and bread box/bag carry a 'Pilot' sticker.",
                        "Hot meals are labelled TCR and loaded in foils — plating is NOT required.",
                        "Meal items are bulk-loaded; assemble/arrange per requested items."
                    ]
                )
                mealCountCard
                guidelineSection(
                    title: "Drinks",
                    bullets: [
                        "Each flight-crew member receives a bottle of water.",
                        "Category 1 flights: ask if a small or large water bottle is preferred.",
                        "Categories 2-8 flights: give a large bottle of water.",
                        "Hand the bottle of water directly to the flight crew.",
                        "Prepared drinks (hot/cold) must use flight-crew cups; do not pass over the centre console."
                    ]
                )
                dutiesSection
            }
        }
    }

    private var mealCountCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Hot meals per crew member per sector")
                .font(.subheadline.bold())
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Text("FLIGHT CATEGORIES").frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 10)
                    Text("EX-DUBAI").frame(width: 90, alignment: .center)
                    Text("RETURN").frame(width: 80, alignment: .center)
                }
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
                .padding(.vertical, 6)
                .background(Color(.secondarySystemFill))
                Divider()
                mealCountRow("Cat 1 and 2", exDxb: "1", ret: "—")
                Divider()
                mealCountRow("Cat 3 – 8", exDxb: "2", ret: "—")
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color(.separator).opacity(0.4), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    private func mealCountRow(_ category: String, exDxb: String, ret: String) -> some View {
        HStack(spacing: 0) {
            Text(category).font(.subheadline).frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 10)
            Text(exDxb).font(.subheadline.monospaced().bold()).frame(width: 90, alignment: .center)
            Text(ret).font(.subheadline.monospaced().bold()).frame(width: 80, alignment: .center)
        }
        .padding(.vertical, 8)
    }

    private var responsibleCrewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Responsible crew for flight crew service")
                .font(.subheadline.bold())
            VStack(spacing: 0) {
                responsibleCrewRow(aircraft: "A380 4 Class", primary: "MR3A", onRest: "ML5", isHeader: false)
                Divider()
                responsibleCrewRow(aircraft: "A380 3 Class", primary: "ML2", onRest: "ML5", isHeader: false)
                Divider()
                responsibleCrewRow(aircraft: "A380 2 Class", primary: "ML2", onRest: "ML5", isHeader: false)
                Divider()
                responsibleCrewRow(aircraft: "B777 3 Class", primary: "L1", onRest: "R1", isHeader: false)
                Divider()
                responsibleCrewRow(aircraft: "B777 2 Class", primary: "L1A", onRest: "R1", isHeader: false)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color(.separator).opacity(0.4), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            Text("Header row legend: Aircraft  /  Responsible crew  /  If on rest, responsibility goes to")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    private func responsibleCrewRow(aircraft: String, primary: String, onRest: String, isHeader: Bool) -> some View {
        HStack(spacing: 0) {
            Text(aircraft)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
            Text(primary)
                .font(.subheadline.monospaced().bold())
                .frame(width: 80, alignment: .center)
                .foregroundStyle(.blue)
            Text(onRest)
                .font(.subheadline.monospaced().bold())
                .frame(width: 80, alignment: .center)
                .foregroundStyle(.orange)
        }
        .padding(.vertical, 8)
    }

    private var dutiesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Cabin crew duties — flight crew")
                .font(.subheadline.bold())
            dutyBlock(
                title: "Before departure",
                bullets: [
                    "Introduce yourself.",
                    "Ask the flight crew for a drink order.",
                    "Take the drinks, water bottles, snacks (wrapped) and a tissue box to the flight deck.",
                    "Do not place the contents of the flight-deck food foils in a bag.",
                    "Place a bar waste bag in the flight deck — used for disposal of items.",
                    "Check the flight-crew food and make a note of what is available.",
                    "Before the last cabin door is closed: remove food and drinks except water bottles.",
                    "On turnaround flights, the flight crew may eat on the ground."
                ]
            )
            dutyBlock(
                title: "After take-off",
                bullets: [
                    "Ask the purser when to contact the flight crew and how often during cruise.",
                    "Return the collected food and drinks to the flight deck.",
                    "Flight crew may need lavatory priority — delay customers as needed."
                ]
            )
            dutyBlock(
                title: "Inflight — during cruise",
                bullets: [
                    "B777 2 Class — during service times: close curtains when flight crew exit flight deck; open when they return.",
                    "Meal service: tell the flight crew what food is available.",
                    "Tell the flight crew when you will take part in a meal service.",
                    "Arrange a suitable time to prepare a flight-crew meal.",
                    "The captain decides who eats first.",
                    "The meal must not be ready before the arranged time.",
                    "Offer a drink with the meal.",
                    "Give a table linen when delivering the meal tray."
                ]
            )
            dutyBlock(
                title: "Before landing",
                bullets: ["Remove food and drinks (except water bottles) from the flight deck."]
            )
            dutyBlock(
                title: "After landing",
                bullets: [
                    "Collect the Emirates plastic bag / waste collection bag and the used water bottles.",
                    "Place by the waste bin in the galley nearest the flight deck."
                ]
            )
            dutyBlock(
                title: "Aircraft-specific waste setup",
                bullets: [
                    "A380 / A350: place 2 bar waste bags in the pilot's individual waste bins (outboard side, adjacent to the seat).",
                    "B777: attach a reusable hook and bar waste bag to the centre console."
                ]
            )
        }
    }

    private func dutyBlock(title: String, bullets: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.primary)
            ForEach(bullets, id: \.self) { item in
                HStack(alignment: .top, spacing: 6) {
                    Text("•")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text(item)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func guidelineSection(title: String, bullets: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.bold())
            ForEach(bullets, id: \.self) { item in
                HStack(alignment: .top, spacing: 6) {
                    Text("•")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(item)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Card Container

    @ViewBuilder
    private func card<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3.bold())
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 1)
        .shadow(color: .black.opacity(0.10), radius: 8, x: 0, y: 4)
    }

    // MARK: - Helpers

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let totalMinutes = max(0, Int(seconds / 60))
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        return String(format: "%02d:%02d", h, m)
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    private static func defaultTakeoff() -> Date {
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month, .day], from: Date())
        comps.hour = 9
        comps.minute = 0
        return cal.date(from: comps) ?? Date()
    }

    /// Rounds to the nearest :00 or :30. Tiebreak: minute in [0,15) → :00,
    /// [15,45) → :30, [45,60) → next :00.
    private static func roundToNearestHalfHour(_ date: Date) -> Date {
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let minute = comps.minute ?? 0
        comps.minute = 0
        let onTheHour = cal.date(from: comps) ?? date
        if minute < 15 {
            return onTheHour
        } else if minute < 45 {
            return onTheHour.addingTimeInterval(30 * 60)
        } else {
            return onTheHour.addingTimeInterval(60 * 60)
        }
    }
}

// MARK: - Sector-Scoped Persistence Payload

struct SectorFlightCrewChecklistData: Codable {
    var captain1Name: String
    var captain1Role: String
    var captain2Name: String?
    var captain2Role: String?
    var firstOfficer1Name: String
    var firstOfficer1Role: String
    var firstOfficer2Name: String?
    var firstOfficer2Role: String?
    var initialCallOverride: Date?
    var callIntervalMinutes: Int?
}

// MARK: - Crew Slot Model

struct CrewSlot {
    var name: String = ""
    var role: CrewRole = .operating
}

// MARK: - Crew Role

enum CrewRole: String, CaseIterable, Identifiable {
    case operating = "Operating"
    case augmenting = "Augmenting"
    var id: String { rawValue }
}

// MARK: - Schedule Entry

private struct ScheduleEntry: Identifiable {
    let id = UUID()
    let time: Date
    let note: String
}

// MARK: - Preview

#Preview {
    NavigationStack {
        FlightCrewChecklistView()
    }
}
