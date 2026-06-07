import SwiftUI

// MARK: - We Care Schedule View (Stage 4)
//
// Renders the generated schedule as a per-cabin timeline of cycle cards, with
// completion tracking. The e-form requirement is surfaced on categories 3 to 8.

struct WeCareScheduleView: View {
    let schedule: WeCareSchedule
    let config: WeCareConfig
    var rules: WeCareRules = WeCareRulesLoader.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(schedule.cabins, id: \.cabin) { cabin in
                    cabinSection(cabin)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Cabin Section

    @ViewBuilder
    private func cabinSection(_ cabin: WeCareCabinSchedule) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(Self.cabinName(cabin.cabin))
                    .font(.headline)
                Spacer()
                Text("\(cabin.crewCount) crew per cycle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(summary(for: cabin))
                .font(.caption)
                .foregroundStyle(.secondary)

            if let note = rules.cabin(cabin.cabin)?.notes {
                Text(note)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if cabin.cycles.isEmpty {
                Text("No cycles fit in the available window.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(cabin.cycles, id: \.start) { cycle in
                    cycleCard(cabin.cabin, cycle)
                }
            }
        }
    }

    // MARK: - Cycle Card

    @ViewBuilder
    private func cycleCard(_ cabin: WeCareCabinCode, _ cycle: WeCareCycleWindow) -> some View {
        let done = config.isCycleCompleted(cabin, start: cycle.start)
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(cycle.isCleanlinessOnly ? "Cleanliness-only cycle" : "Cycle \(cycle.index)")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(Self.hhmm(cycle.start)) to \(Self.hhmm(cycle.end))")
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 6) {
                ForEach(cycle.legs, id: \.kind) { leg in
                    Text("\(leg.kind.label) \(leg.durationMinutes)m")
                        .font(.caption2)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.secondary.opacity(0.12), in: Capsule())
                }
            }

            HStack {
                if cycle.eFormRequired {
                    Label("We Care e-form required", systemImage: "doc.text")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
                Spacer()
                Toggle("Completed", isOn: Binding(
                    get: { done },
                    set: { config.setCycleCompleted(cabin, start: cycle.start, $0) }
                ))
                .labelsHidden()
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(done ? Color.green.opacity(0.12) : Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(done ? Color.green.opacity(0.4) : Color.clear, lineWidth: 1)
        )
    }

    // MARK: - Summary

    /// Cycles before the first meal service (for between-services cabins) and
    /// the total before landing.
    private func summary(for cabin: WeCareCabinSchedule) -> String {
        let total = cabin.cycles.count
        let firstServiceStart = config.mealBlocks.map(\.start).min()
        if let firstStart = firstServiceStart {
            let beforeService = cabin.cycles.filter { $0.end <= firstStart }.count
            return "\(total) cycle(s) before landing, \(beforeService) before the first service."
        }
        return "\(total) cycle(s) before landing."
    }

    // MARK: - Helpers

    private static func cabinName(_ cabin: WeCareCabinCode) -> String {
        switch cabin {
        case .FCL: return "First"
        case .JCL: return "Business"
        case .WCL: return "Premium Economy"
        case .YCL: return "Economy"
        }
    }

    private static func hhmm(_ minutes: Int) -> String {
        let v = ((minutes % 1440) + 1440) % 1440
        return String(format: "%02d:%02d", v / 60, v % 60)
    }
}
