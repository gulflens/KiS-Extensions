import SwiftUI
import SwiftData

// MARK: - We Care Input View (Stage 3)
//
// Lets the planner build and persist a We Care configuration for a sector,
// then validate it through the schedule engine. The generated schedule is
// rendered in Stage 4; here the detail panel shows a validation summary.

struct WeCareInputView: View {
    let sector: PlannedSector
    /// Take-off and landing carried forward from the timeline tab, as minutes
    /// from midnight (Dubai).
    let timelineTakeoffMinute: Int
    let timelineLandingMinute: Int

    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var sizeClass

    @State private var config: WeCareConfig?

    private var isRegular: Bool { sizeClass == .regular }

    var body: some View {
        Group {
            if let config {
                WeCareConfigForm(sector: sector, config: config, isRegular: isRegular)
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear(perform: loadOrCreate)
    }

    // MARK: - Load or Create

    private func loadOrCreate() {
        if config == nil {
            let id = sector.id
            let descriptor = FetchDescriptor<WeCareConfig>(predicate: #Predicate { $0.sectorID == id })
            if let existing = try? modelContext.fetch(descriptor).first {
                config = existing
            } else {
                let new = WeCareConfig(sectorID: id)
                applyDefaults(to: new)
                modelContext.insert(new)
                config = new
            }
        }
        // Always carry the times forward from the timeline.
        config?.takeoffMinute = timelineTakeoffMinute
        config?.landingMinute = timelineLandingMinute
    }

    /// Seed a new config from the sector: aircraft and operating cabins from the
    /// registration, take-off and landing from saved times.
    private func applyDefaults(to config: WeCareConfig) {
        if let reg = sector.registration {
            let clean = reg.replacingOccurrences(of: "-", with: "")
            if let opType = FleetRegistry.fleet[clean], let aircraft = AircraftTypes.types[opType] {
                config.aircraftKey = aircraft.aircraftModel
                config.operatingCabins = WeCareCabinAvailability.cabins(
                    model: aircraft.aircraftModel, classes: aircraft.classes
                )
            }
        }
        if config.operatingCabins.isEmpty {
            config.operatingCabins = [.JCL, .YCL]
        }
        // Take-off and landing are carried forward from the timeline, not seeded here.
    }
}

// MARK: - Config Form

private struct WeCareConfigForm: View {
    let sector: PlannedSector
    @Bindable var config: WeCareConfig
    let isRegular: Bool

    @State private var lastSchedule: WeCareSchedule?
    @State private var lastError: String?

    private let aircraftKeys = ["A380", "B773", "B772", "A350"]

    var body: some View {
        if isRegular {
            HStack(alignment: .top, spacing: 0) {
                form.frame(maxWidth: .infinity)
                Divider()
                detailPanel.frame(width: 360)
            }
        } else {
            ScrollView {
                VStack(spacing: 16) {
                    formBody
                    detailPanel
                }
                .padding()
            }
        }
    }

    // MARK: Form

    private var form: some View {
        Form { formContent }
    }

    @ViewBuilder private var formBody: some View {
        Form { formContent }
            .frame(minHeight: 480)
    }

    @ViewBuilder private var formContent: some View {
        Section("Aircraft and category") {
            Picker("Aircraft", selection: Binding(
                get: { config.aircraftKey ?? aircraftKeys[0] },
                set: { config.aircraftKey = $0 }
            )) {
                ForEach(aircraftKeys, id: \.self) { Text($0).tag($0) }
            }
            Picker("Flight category", selection: Binding(
                get: { config.flightCategory ?? 5 },
                set: { config.flightCategory = $0 }
            )) {
                ForEach(1...8, id: \.self) { Text("Category \($0)").tag($0) }
            }
        }

        Section("Operating cabins") {
            ForEach(WeCareCabinCode.allCases) { cabin in
                Toggle(Self.cabinName(cabin), isOn: Binding(
                    get: { config.isOperating(cabin) },
                    set: { config.setOperating(cabin, $0) }
                ))
            }
        }

        Section("Times (Dubai, from timeline)") {
            LabeledContent("Take-off", value: Self.hhmm(config.takeoffMinute))
            LabeledContent("Landing", value: Self.hhmm(config.landingMinute))
            Stepper("Before-landing buffer: \(config.beforeLandingBufferMinutes ?? 30) min",
                    value: Binding(get: { config.beforeLandingBufferMinutes ?? 30 },
                                   set: { config.beforeLandingBufferMinutes = $0 }),
                    in: 0...90, step: 5)
            Text("Take-off and landing are carried forward from the timeline.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }

        Section("Meal services") {
            ForEach(Array(config.mealBlocks.enumerated()), id: \.element.id) { index, _ in
                HStack {
                    DatePicker("Start", selection: mealBinding(index, isStart: true), displayedComponents: .hourAndMinute)
                    DatePicker("End", selection: mealBinding(index, isStart: false), displayedComponents: .hourAndMinute)
                    Button(role: .destructive) { removeMeal(index) } label: {
                        Image(systemName: "minus.circle")
                    }
                    .buttonStyle(.borderless)
                }
            }
            Button { addMeal() } label: {
                Label("Add meal service", systemImage: "plus")
            }
        }

        if config.isOperating(.YCL) || config.isOperating(.WCL) {
            Section("Manual crew per cycle") {
                if config.isOperating(.YCL) {
                    Stepper("Economy crew: \(config.manualYCLCrew ?? 0)",
                            value: Binding(get: { config.manualYCLCrew ?? 0 },
                                           set: { config.manualYCLCrew = $0 }),
                            in: 0...12)
                }
                if config.isOperating(.WCL) {
                    Stepper("Premium Economy crew: \(config.manualWCLCrew ?? 0)",
                            value: Binding(get: { config.manualWCLCrew ?? 0 },
                                           set: { config.manualWCLCrew = $0 }),
                            in: 0...12)
                }
                Text("Supervisor-entered. Economy crew may backfill Premium Economy.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Detail panel

    private var detailPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("We Care schedule")
                .font(.headline)

            Button { generate() } label: {
                Label("Generate schedule", systemImage: "wand.and.stars")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            if let lastError {
                Label(lastError, systemImage: "exclamationmark.triangle.fill")
                    .font(.callout)
                    .foregroundStyle(.red)
            } else if let lastSchedule {
                let totalCycles = lastSchedule.cabins.reduce(0) { $0 + $1.cycles.count }
                VStack(alignment: .leading, spacing: 8) {
                    Label("Schedule is valid", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                    Text("\(lastSchedule.cabins.count) cabin(s), \(totalCycles) cycle(s).")
                        .font(.callout)
                    ForEach(lastSchedule.cabins, id: \.cabin) { cabin in
                        Text("\(Self.cabinName(cabin.cabin)): \(cabin.cycles.count) cycle(s), \(cabin.crewCount) crew")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text("The full timeline is rendered in the schedule view.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            } else {
                Text("Fill in the configuration, then generate to validate it.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Actions

    private func generate() {
        config.updatedAt = Date()
        do {
            lastSchedule = try WeCareScheduleEngine.generate(context: config.makeContext())
            lastError = nil
        } catch let error as WeCareScheduleError {
            lastError = error.message
            lastSchedule = nil
        } catch {
            lastError = "An unexpected error occurred while generating the schedule."
            lastSchedule = nil
        }
    }

    private func addMeal() {
        let takeoff = config.takeoffMinute ?? 0
        var blocks = config.mealBlocks
        blocks.append(WeCareMealBlock(start: takeoff + 30, end: takeoff + 75))
        config.mealBlocks = blocks
    }

    private func removeMeal(_ index: Int) {
        var blocks = config.mealBlocks
        guard index < blocks.count else { return }
        blocks.remove(at: index)
        config.mealBlocks = blocks
    }

    // MARK: Bindings & helpers

    private static func hhmm(_ minutes: Int?) -> String {
        guard let m = minutes else { return "Not set" }
        let v = ((m % 1440) + 1440) % 1440
        return String(format: "%02d:%02d", v / 60, v % 60)
    }

    private func mealBinding(_ index: Int, isStart: Bool) -> Binding<Date> {
        Binding(
            get: {
                let blocks = config.mealBlocks
                guard index < blocks.count else { return Self.date(fromMinutes: 0) }
                return Self.date(fromMinutes: isStart ? blocks[index].start : blocks[index].end)
            },
            set: { newValue in
                var blocks = config.mealBlocks
                guard index < blocks.count else { return }
                if isStart { blocks[index].start = Self.minutes(from: newValue) }
                else { blocks[index].end = Self.minutes(from: newValue) }
                config.mealBlocks = blocks
            }
        )
    }

    private static func cabinName(_ cabin: WeCareCabinCode) -> String {
        switch cabin {
        case .FCL: return "First"
        case .JCL: return "Business"
        case .WCL: return "Premium Economy"
        case .YCL: return "Economy"
        }
    }

    private static func date(fromMinutes minutes: Int) -> Date {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let clamped = ((minutes % 1440) + 1440) % 1440
        return calendar.date(byAdding: .minute, value: clamped, to: start) ?? start
    }

    private static func minutes(from date: Date) -> Int {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
    }
}
