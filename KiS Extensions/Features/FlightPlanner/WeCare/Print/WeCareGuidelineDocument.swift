import SwiftUI

// MARK: - We Care Guideline Document (Stage 5)
//
// A print-friendly, monochrome one-page guideline: the timing/crew matrix, the
// governance and suspension rules verbatim from the rule base, and the
// generated per-cabin schedule for the sector. Rendered to PDF for export.

struct WeCareGuidelineDocument: View {
    let schedule: WeCareSchedule
    let sectorLabel: String
    var rules: WeCareRules = WeCareRulesLoader.shared

    private let ink = Color.black
    private let hairline = Color.black.opacity(0.4)

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            matrixSection
            rulesSection
            scheduleSection
        }
        .padding(28)
        .frame(width: 540, alignment: .leading)
        .foregroundStyle(ink)
        .background(Color.white)
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("We Care Crew Guideline")
                .font(.system(size: 20, weight: .bold))
            Text("Source: Cabin Crew Service Training Manual, Ch. 11, \(rules.sourceVersion)")
                .font(.system(size: 10))
            Text(sectorLabel)
                .font(.system(size: 12, weight: .semibold))
                .padding(.top, 2)
        }
    }

    // MARK: Matrix

    private var matrixSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionTitle("Timing and crew matrix")
            Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 6) {
                GridRow {
                    cell("Cabin", bold: true)
                    cell("Interval", bold: true)
                    cell("Clean", bold: true)
                    cell("Care", bold: true)
                    cell("Refresh", bold: true)
                    cell("Crew", bold: true)
                }
                Divider().overlay(hairline).gridCellColumns(6)
                ForEach(rules.cabins) { rule in
                    GridRow {
                        cell(Self.cabinName(rule.code))
                        cell("\(rule.cycleIntervalMinutes) min")
                        cell("\(rule.duties.cleanliness)")
                        cell("\(rule.duties.customerCare)")
                        cell("\(rule.duties.refreshments)")
                        cell(Self.crewText(rule))
                    }
                }
            }
        }
    }

    // MARK: Rules

    private var rulesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionTitle("Governance and suspension")
            ForEach(Array(rules.governanceRules.enumerated()), id: \.offset) { index, rule in
                HStack(alignment: .top, spacing: 6) {
                    Text("\(index + 1).")
                        .font(.system(size: 10, weight: .semibold))
                    Text(rule)
                        .font(.system(size: 10))
                }
            }
        }
    }

    // MARK: Schedule

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Schedule for this sector")
            ForEach(schedule.cabins, id: \.cabin) { cabin in
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(Self.cabinName(cabin.cabin)) — \(cabin.crewCount) crew per cycle")
                        .font(.system(size: 11, weight: .semibold))
                    if cabin.cycles.isEmpty {
                        Text("No cycles in the available window.")
                            .font(.system(size: 10))
                    } else {
                        ForEach(cabin.cycles, id: \.start) { cycle in
                            Text(Self.cycleLine(cycle))
                                .font(.system(size: 10))
                        }
                    }
                }
            }
        }
    }

    // MARK: Helpers

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .bold))
    }

    private func cell(_ text: String, bold: Bool = false) -> some View {
        Text(text)
            .font(.system(size: 10, weight: bold ? .semibold : .regular))
    }

    private static func cabinName(_ cabin: WeCareCabinCode) -> String {
        switch cabin {
        case .FCL: return "First"
        case .JCL: return "Business"
        case .WCL: return "Premium Economy"
        case .YCL: return "Economy"
        }
    }

    private static func crewText(_ rule: WeCareCabinRule) -> String {
        switch rule.crew.mode {
        case .manual:
            return "Manual"
        case .fixed:
            if let value = rule.crew.value { return "\(value)" }
            if let byAircraft = rule.crew.byAircraft {
                return byAircraft.sorted { $0.key < $1.key }
                    .map { "\($0.key) \($0.value)" }
                    .joined(separator: ", ")
            }
            return "Fixed"
        }
    }

    private static func cycleLine(_ cycle: WeCareCycleWindow) -> String {
        let window = "\(hhmm(cycle.start)) to \(hhmm(cycle.end))"
        let label = cycle.isCleanlinessOnly ? "Cleanliness-only" : "Cycle \(cycle.index)"
        let duties = cycle.legs.map { "\($0.kind.label) \($0.durationMinutes)" }.joined(separator: ", ")
        let eForm = cycle.eFormRequired ? "  e-form required" : ""
        return "\(label)  \(window)  —  \(duties)\(eForm)"
    }

    private static func hhmm(_ minutes: Int) -> String {
        let v = ((minutes % 1440) + 1440) % 1440
        return String(format: "%02d:%02d", v / 60, v % 60)
    }
}
