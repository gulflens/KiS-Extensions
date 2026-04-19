import SwiftUI

// MARK: - Flight Crew Checklist View

struct FlightCrewChecklistView: View {

    // MARK: - Inputs

    @State private var takeoffDate: Date = Self.defaultTakeoff()
    @State private var durationHours: Int = 6
    @State private var durationMinutes: Int = 0

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

    private var initialCallDate: Date {
        let raw = takeoffDate.addingTimeInterval(TimeInterval(Self.initialCallOffsetMin * 60))
        return Self.roundToNearestHalfHour(raw)
    }

    // MARK: - Schedule

    private var scheduleEntries: [ScheduleEntry] {
        guard durationSeconds > 0 else { return [] }
        guard twentyToTopDate > initialCallDate else { return [] }

        var entries: [ScheduleEntry] = []
        var current = initialCallDate
        var isFirst = true
        while current < twentyToTopDate {
            entries.append(ScheduleEntry(
                time: current,
                note: isFirst ? "Initial call" : ""
            ))
            current = current.addingTimeInterval(30 * 60)
            isFirst = false
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
                keyTimesCard
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
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Flight Crew Checklist")
                .font(.title.bold())
            Text("Plan crew calls and brief duties around takeoff, top of descent, and landing.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Inputs Card

    private var inputsCard: some View {
        card("Flight Times") {
            HStack(alignment: .top, spacing: 32) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Take off")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    DatePicker("", selection: $takeoffDate, displayedComponents: [.hourAndMinute])
                        .labelsHidden()
                        .datePickerStyle(.compact)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Flight duration")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 16) {
                        Stepper(value: $durationHours, in: 0...18) {
                            Text("\(durationHours)h")
                                .font(.headline.monospacedDigit())
                                .frame(width: 36, alignment: .leading)
                        }
                        Stepper(value: $durationMinutes, in: 0...55, step: 5) {
                            Text(String(format: "%02dm", durationMinutes))
                                .font(.headline.monospacedDigit())
                                .frame(width: 44, alignment: .leading)
                        }
                    }
                }

                Spacer(minLength: 0)
            }
        }
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
            VStack(alignment: .leading, spacing: 12) {
                guidelineSection(
                    title: "Rules and regulations",
                    body: "Placeholder — add full procedure on calling the flight crew, response timing, and how to log non-response."
                )
                guidelineSection(
                    title: "Permitted meals",
                    body: "Placeholder — add food types the flight crew may have, allergen handling, and service timing."
                )
                guidelineSection(
                    title: "Etiquette",
                    body: "Placeholder — add general etiquette: knock procedure, voice level, lighting, refreshments, and rest considerations."
                )
            }
        }
    }

    private func guidelineSection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.bold())
            Text(body)
                .font(.subheadline)
                .foregroundStyle(.secondary)
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
