import SwiftUI

// MARK: - Timeline Event

private struct TimelineEvent {
    let label: String
    let start: Int
    let end: Int
    let color: Color
    let badge: String?
    let kind: EventKind
}

private enum EventKind {
    case settling, service, rest
}

private func buildTimeline(_ c: CalculationResult) -> [TimelineEvent] {
    var events: [TimelineEvent] = []

    if c.isLong, let ss = c.settlingStart, let se = c.settlingEnd {
        events.append(TimelineEvent(label: "Settling-in", start: ss, end: se, color: CRTheme.settle, badge: nil, kind: .settling))
    }

    for (i, s) in c.services.enumerated() {
        let badge = (i == 0 && c.svc1Extension > 0) ? "+\(c.svc1Extension)m" : nil
        events.append(TimelineEvent(label: s.label, start: s.start, end: s.end, color: CRTheme.service, badge: badge, kind: .service))
    }

    for b in c.breaks {
        events.append(TimelineEvent(label: b.label, start: b.start, end: b.end, color: CRTheme.rest, badge: nil, kind: .rest))
    }

    events.sort { $0.start < $1.start }
    return events
}

// MARK: - Timeline Filter

private enum TimelineFilter: String, CaseIterable {
    case all, serviceOnly, restOnly

    var label: String {
        switch self {
        case .all: "All"
        case .serviceOnly: "Service only"
        case .restOnly: "Rest only"
        }
    }
}

// MARK: - Timeline Row

private struct TimelineRow: View {
    let label: String
    let start: String
    let end: String
    let dur: String
    let color: Color
    var badge: String? = nil
    var isFirst: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            Text(dur)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .frame(width: 60, alignment: .center)

            Rectangle().fill(Color(uiColor: .separator)).frame(width: 0.5)

            HStack(spacing: 6) {
                Circle().fill(color).frame(width: 10, height: 10)
                ordinalText(label, baseFontSize: 13).font(.system(size: 13))
                if let badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .padding(.horizontal, 5).padding(.vertical, 1)
                        .background(CRTheme.accent.opacity(0.18))
                        .foregroundStyle(CRTheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 10)

            Rectangle().fill(Color(uiColor: .separator)).frame(width: 0.5)

            Text(start)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 55, alignment: .center)

            Rectangle().fill(Color(uiColor: .separator)).frame(width: 0.5)

            Text(end)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 55, alignment: .center)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(color.opacity(0.08))
        .overlay(alignment: .top) {
            if !isFirst {
                Rectangle().fill(Color(uiColor: .separator).opacity(0.5))
                    .frame(height: 0.5)
            }
        }
    }
}

// MARK: - Timeline Table Header

private struct TimelineTableHeader: View {
    var body: some View {
        HStack(spacing: 0) {
            Text("DURATION")
                .frame(width: 60, alignment: .center)
            Rectangle().fill(Color(uiColor: .separator)).frame(width: 0.5)
            Text("PHASE")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 10)
            Rectangle().fill(Color(uiColor: .separator)).frame(width: 0.5)
            Text("START")
                .frame(width: 55, alignment: .center)
            Rectangle().fill(Color(uiColor: .separator)).frame(width: 0.5)
            Text("END")
                .frame(width: 55, alignment: .center)
        }
        .font(.system(size: 9.5, weight: .bold))
        .tracking(0.3)
        .foregroundStyle(.tertiary)
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .background(Color(uiColor: .secondarySystemBackground))
    }
}

// MARK: - Crew Rest Results View

struct CrewRestResultsView: View {
    @Environment(CrewRestState.self) private var state
    @Environment(\.dismiss) private var dismiss

    var embedded: Bool = false
    var breakGroups: [BreakGroupEntry] = []

    @State private var filter: TimelineFilter = .all

    private var c: CalculationResult? { state.result }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {

                // MARK: - Key Times
                if let c {
                    Card(title: "Key times") {
                        VStack(spacing: 8) {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                KeyTimeCell(cap: "Take off", value: TimeFormatter.clock(c.T0))
                                KeyTimeCell(cap: "Landing",  value: TimeFormatter.clock(c.LAND))
                                KeyTimeCell(cap: "20 to top", value: TimeFormatter.clock(c.TWENTY))
                                KeyTimeCell(cap: "TOD",       value: TimeFormatter.clock(c.TOD))
                            }
                            LabeledRow(label: "Total rest", trailing: {
                                Text(TimeFormatter.dur(c.totalRest))
                                    .font(.system(size: 14, design: .monospaced))
                                    .foregroundStyle(.secondary)
                            }, hasTopBorder: true)
                        }
                    }

                    // MARK: - Flight Timeline
                    Card(title: "Flight timeline") {
                        VStack(spacing: 0) {
                            // Filter buttons
                            HStack(spacing: 8) {
                                ForEach(TimelineFilter.allCases, id: \.self) { f in
                                    Button {
                                        filter = f
                                    } label: {
                                        Text(f.label)
                                            .font(.system(size: 12, weight: filter == f ? .semibold : .regular))
                                            .foregroundStyle(filter == f ? .white : .secondary)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(filter == f ? CRTheme.ekRed : Color(uiColor: .secondarySystemBackground))
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                                Spacer()
                            }
                            .padding(.bottom, 10)

                            TimelineTableHeader()
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                            let events = filteredEvents(buildTimeline(c))
                            ForEach(Array(events.enumerated()), id: \.offset) { idx, event in
                                TimelineRow(
                                    label: event.label,
                                    start: TimeFormatter.clock(event.start),
                                    end: TimeFormatter.clock(event.end),
                                    dur: TimeFormatter.dur(event.end - event.start),
                                    color: event.color,
                                    badge: event.badge,
                                    isFirst: idx == 0
                                )
                            }

                            if c.svc1Extension > 0 {
                                Text("\(c.services[0].label) extended by \(c.svc1Extension) min so all crew rest breaks are equal.")
                                    .font(.system(size: 11)).foregroundStyle(.secondary)
                                    .padding(.top, 8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }

                    // MARK: - Timeline Bar
                    Card(title: "Timeline") {
                        ScheduleTimelineBar(c: c)
                            .padding(.bottom, 10)
                        TimelineLegend()
                    }

                    // MARK: - First Class
                    if c.fcApplies, let fc = c.fc {
                        FCCard(c: c, fc: fc)
                    }

                    // MARK: - Break Summary
                    if !breakGroups.isEmpty {
                        BreakSummaryCard(breakGroups: breakGroups)
                    }
                }
            }
            .padding(14)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .if(!embedded) { view in
            view
                .navigationTitle("Schedule")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(CRTheme.ekRed, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button { dismiss() } label: {
                            HStack(spacing: 2) {
                                Image(systemName: "chevron.left")
                                Text("Edit")
                            }
                            .foregroundStyle(.white)
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        if let c {
                            Menu {
                                Button { SchedulePrinter.print(c: c, layout: .onePerSheet) } label: {
                                    Label("1 per sheet", systemImage: "doc")
                                }
                                Button { SchedulePrinter.print(c: c, layout: .twoPerSheet) } label: {
                                    Label("2 per sheet", systemImage: "doc.on.doc")
                                }
                            } label: {
                                Image(systemName: "printer")
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                }
        }
    }

    // MARK: - Filter

    private func filteredEvents(_ events: [TimelineEvent]) -> [TimelineEvent] {
        switch filter {
        case .all: events
        case .serviceOnly: events.filter { $0.kind == .service || $0.kind == .settling }
        case .restOnly: events.filter { $0.kind == .rest }
        }
    }
}

// MARK: - Conditional modifier

private extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Key Time Cell

private struct KeyTimeCell: View {
    let cap: String
    let value: String
    var body: some View {
        VStack(spacing: 2) {
            Text(cap.uppercased())
                .font(.system(size: 9.5, weight: .semibold)).tracking(0.4)
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.system(size: 17, weight: .semibold, design: .monospaced))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Schedule Timeline Bar

private struct ScheduleTimelineBar: View {
    let c: CalculationResult

    var body: some View {
        let total = max(1, c.LAND - c.T0)
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                Rectangle().fill(Color(uiColor: .secondarySystemBackground))
                    .frame(height: 32)

                if c.isLong, let ss = c.settlingStart, let se = c.settlingEnd {
                    block(start: ss, end: se, color: CRTheme.settle, width: geo.size.width, total: total)
                }
                ForEach(Array(c.services.enumerated()), id: \.offset) { _, s in
                    block(start: s.start, end: s.end, color: CRTheme.service, width: geo.size.width, total: total)
                }
                ForEach(Array(c.breaks.enumerated()), id: \.offset) { _, b in
                    block(start: b.start, end: b.end, color: CRTheme.rest, width: geo.size.width, total: total)
                }

                ForEach([(c.T0, "TO"), (c.TWENTY, "20\u{2192}T"), (c.TOD, "TOD"), (c.LAND, "LDG")], id: \.0) { mk in
                    let x = CGFloat(mk.0 - c.T0) / CGFloat(total) * geo.size.width
                    Rectangle().fill(Color.primary.opacity(0.5))
                        .frame(width: 1, height: 32)
                        .offset(x: x)
                    Text(mk.1)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .offset(x: max(0, min(geo.size.width - 30, x - 12)), y: 36)
                }
            }
        }
        .frame(height: 60)
    }

    private func block(start: Int, end: Int, color: Color, width: CGFloat, total: Int) -> some View {
        let x = CGFloat(start - c.T0) / CGFloat(total) * width
        let w = CGFloat(end - start) / CGFloat(total) * width
        return Rectangle()
            .fill(color)
            .frame(width: max(2, w), height: 32)
            .offset(x: x)
    }
}

// MARK: - Timeline Legend

private struct TimelineLegend: View {
    var body: some View {
        HStack(spacing: 14) {
            legendItem(color: CRTheme.settle, label: "Settling")
            legendItem(color: CRTheme.service, label: "Service")
            legendItem(color: CRTheme.rest, label: "Rest break")
        }
        .font(.system(size: 11))
        .foregroundStyle(.secondary)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
        }
    }
}

// MARK: - First Class Card

private struct FCCard: View {
    let c: CalculationResult
    let fc: FCResult

    var body: some View {
        Card(title: "First class \u{00B7} \(fc.breaks.count) break\(fc.breaks.count == 1 ? "" : "s") (dine on demand)", fcStyle: true) {
            VStack(spacing: 8) {
                LabeledRow(label: "Window", trailing: {
                    Text("\(TimeFormatter.clock(fc.fcStart)) \u{2014} \(TimeFormatter.clock(fc.windowEnd))")
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundStyle(.secondary)
                }, hasTopBorder: false)

                LabeledRow(label: "Break length", trailing: {
                    Text(TimeFormatter.dur(fc.breakDur))
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundStyle(.secondary)
                })

                if !fc.breaks.isEmpty {
                    Divider().padding(.vertical, 4)

                    TimelineTableHeader()
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                    ForEach(Array(fc.breaks.enumerated()), id: \.offset) { idx, b in
                        TimelineRow(
                            label: b.label,
                            start: TimeFormatter.clock(b.start),
                            end: TimeFormatter.clock(b.end),
                            dur: TimeFormatter.dur(b.durationMin),
                            color: CRTheme.rest,
                            isFirst: idx == 0
                        )
                    }
                }

                if fc.dropped > 0 {
                    let fits = 3 - fc.dropped
                    let msg = fits == 0
                        ? "No FC breaks fit in the configured window."
                        : "Only \(fits) of 3 FC breaks fit in the configured window."
                    Text(msg).font(.system(size: 11)).foregroundStyle(.secondary)
                        .padding(.top, 4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if fc.allowOverlap && fc.overlap > 0 {
                    Text("\(fc.overlap) min overlap between 2nd and 3rd breaks to keep the last break before LDG minus \(TimeFormatter.dur(fc.endBuffer)).")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                        .padding(.top, 4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

// MARK: - Break Summary Card

private struct BreakSummaryCard: View {
    let breakGroups: [BreakGroupEntry]

    private var hasFG1: Bool {
        breakGroups.contains { !$0.fg1.isEmpty }
    }

    var body: some View {
        Card(title: "Crew break summary") {
            VStack(spacing: 0) {
                summaryHeader
                ForEach(Array(breakGroups.enumerated()), id: \.offset) { idx, group in
                    summaryRow(group: group, isEven: idx % 2 == 0)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(Color(uiColor: .separator), lineWidth: 0.5)
            )
        }
    }

    private var summaryHeader: some View {
        HStack(spacing: 0) {
            Text("BREAK")
                .frame(width: 70, alignment: .leading)
                .padding(.leading, 8)
            divider
            Text("CREW")
                .frame(width: 40, alignment: .center)
            divider
            Text("SENIORS")
                .frame(maxWidth: .infinity, alignment: .center)
            divider
            if hasFG1 {
                Text("FG1")
                    .frame(maxWidth: .infinity, alignment: .center)
                divider
            }
            Text("GR1")
                .frame(maxWidth: .infinity, alignment: .center)
            divider
            Text("GR2")
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.trailing, 8)
        }
        .font(.system(size: 9.5, weight: .bold))
        .tracking(0.3)
        .foregroundStyle(.tertiary)
        .padding(.vertical, 6)
        .background(Color(uiColor: .secondarySystemBackground))
    }

    private func summaryRow(group: BreakGroupEntry, isEven: Bool) -> some View {
        let ordinal: String = switch group.breakNumber {
        case 1: "1st Break"
        case 2: "2nd Break"
        case 3: "3rd Break"
        default: "\(group.breakNumber)th Break"
        }

        return HStack(spacing: 0) {
            ordinalText(ordinal, baseFontSize: 11)
                .font(.system(size: 11, weight: .medium))
                .frame(width: 70, alignment: .leading)
                .padding(.leading, 8)
            divider
            Text("\(group.count)")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .frame(width: 40, alignment: .center)
            divider
            Text(group.seniors)
                .font(.system(size: 10))
                .padding(.leading, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
            divider
            if hasFG1 {
                Text(group.fg1)
                    .font(.system(size: 10))
                    .padding(.leading, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                divider
            }
            Text(group.gr1)
                .font(.system(size: 10))
                .padding(.leading, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
            divider
            Text(group.gr2)
                .font(.system(size: 10))
                .padding(.leading, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 8)
        }
        .padding(.vertical, 6)
        .background(isEven ? CRTheme.rest.opacity(0.06) : Color(uiColor: .systemBackground))
        .overlay(alignment: .top) {
            Rectangle().fill(Color(uiColor: .separator).opacity(0.5))
                .frame(height: 0.5)
        }
    }

    private var divider: some View {
        Rectangle().fill(Color(uiColor: .separator).opacity(0.5)).frame(width: 0.5)
    }
}
