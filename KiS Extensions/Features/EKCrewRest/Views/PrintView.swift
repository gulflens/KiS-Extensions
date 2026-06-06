import SwiftUI
import UIKit

// MARK: - Print Schedule

enum SchedulePrinter {

    enum Layout {
        case onePerSheet
        case twoPerSheet
    }

    @MainActor
    static func print(c: CalculationResult, breakGroups: [BreakGroupEntry] = [], sectorLabel: String = "", layout: Layout = .onePerSheet) {
        let view = PrintableSchedule(c: c, breakGroups: breakGroups, sectorLabel: sectorLabel)
            .frame(width: 595, height: 842)

        let renderer = ImageRenderer(content: view)
        renderer.scale = 3

        guard let pageImage = renderer.uiImage else { return }

        let printImage: UIImage
        switch layout {
        case .onePerSheet:
            printImage = pageImage
        case .twoPerSheet:
            printImage = composeTwoUp(pageImage)
        }

        let info = UIPrintInfo(dictionary: nil)
        info.jobName = "Crew Rest Schedule"
        info.outputType = .grayscale
        if layout == .twoPerSheet {
            info.orientation = .landscape
        }

        let controller = UIPrintInteractionController.shared
        controller.printInfo = info
        controller.printingItem = printImage
        controller.present(animated: true)
    }

    // MARK: Two-up compositing

    private static func composeTwoUp(_ page: UIImage) -> UIImage {
        let sheetW: CGFloat = 842 * 3
        let sheetH: CGFloat = 595 * 3
        let halfW = sheetW / 2
        let pageAspect = page.size.height / page.size.width
        let fitH = halfW * pageAspect
        let yOffset = (sheetH - fitH) / 2

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let compositeRenderer = UIGraphicsImageRenderer(
            size: CGSize(width: sheetW, height: sheetH),
            format: format
        )
        return compositeRenderer.image { _ in
            UIColor.white.setFill()
            UIRectFill(CGRect(x: 0, y: 0, width: sheetW, height: sheetH))
            page.draw(in: CGRect(x: 0, y: yOffset, width: halfW, height: fitH))
            page.draw(in: CGRect(x: halfW, y: yOffset, width: halfW, height: fitH))
        }
    }
}

// MARK: - Printable Schedule

private struct PrintableSchedule: View {
    let c: CalculationResult
    var breakGroups: [BreakGroupEntry] = []
    var sectorLabel: String = ""

    private var hasFG1: Bool {
        breakGroups.contains { !$0.fg1.isEmpty }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Spacer().frame(height: 28)
            keyTimes
            Spacer().frame(height: 32)
            flightTimeline
            if c.fcApplies, let fc = c.fc, !fc.breaks.isEmpty {
                Spacer().frame(height: 32)
                fcSection(fc)
            }
            if !breakGroups.isEmpty {
                Spacer().frame(height: 32)
                breakSummarySection
            }
            Spacer()
            footer
        }
        .padding(36)
        .frame(width: 595, height: 842)
        .background(Color.white)
        .foregroundStyle(.black)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Crew Rest Schedule")
                    .font(.system(size: 20, weight: .bold))
                Spacer()
                Text(dateString)
                    .font(.system(size: 11))
                    .foregroundStyle(.gray)
            }

            Rectangle().fill(.black).frame(height: 1.5)

            HStack(spacing: 16) {
                headerTag("Aircraft", c.aircraft)
                if !c.registration.isEmpty {
                    headerTag("Registration", "A6-\(c.registration)")
                }
                if let fleet = c.matchedFleet {
                    headerTag("Type", fleet.model)
                }
                headerTag("Facility", c.facility.label)
                headerTag("Flight time", TimeFormatter.dur(c.flightMin))
                Spacer()
            }
            .padding(.top, 2)
        }
    }

    private func headerTag(_ label: String, _ value: String) -> some View {
        HStack(spacing: 4) {
            Text("\(label):")
                .font(.system(size: 10))
                .foregroundStyle(.gray)
            Text(value)
                .font(.system(size: 10, weight: .semibold))
        }
        .lineLimit(1)
        .fixedSize()
    }

    private var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "dd MMM yyyy  HH:mm"
        return f.string(from: Date())
    }

    // MARK: - Key Times

    private var keyTimes: some View {
        VStack(spacing: 0) {
            sectionTitle("Key times")

            HStack(spacing: 0) {
                keyTimeCell("Take off", TimeFormatter.clock(c.T0))
                keyTimeCell("20 to top", TimeFormatter.clock(c.TWENTY))
                keyTimeCell("TOD", TimeFormatter.clock(c.TOD))
                keyTimeCell("Landing", TimeFormatter.clock(c.LAND))
                keyTimeCell("Total rest", TimeFormatter.dur(c.totalRest))
            }
            .overlay(Rectangle().stroke(.black, lineWidth: 1))
        }
    }

    private func keyTimeCell(_ label: String, _ value: String) -> some View {
        VStack(spacing: 3) {
            Text(label.uppercased())
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(.gray)
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .overlay(Rectangle().stroke(.black, lineWidth: 1))
    }

    // MARK: - Flight Timeline

    private var flightTimeline: some View {
        VStack(spacing: 0) {
            sectionTitle("Flight timeline")

            tableHeader

            let events = buildPrintTimeline(c)
            ForEach(Array(events.enumerated()), id: \.offset) { idx, event in
                tableRow(
                    label: event.label,
                    start: TimeFormatter.clock(event.start),
                    end: TimeFormatter.clock(event.end),
                    duration: TimeFormatter.dur(event.end - event.start),
                    kind: event.kind,
                    isEven: idx % 2 == 0
                )
            }

            if c.svc1Extension > 0 {
                Text("\(c.services[0].label) extended by \(c.svc1Extension) min so all crew rest breaks are equal.")
                    .font(.system(size: 9))
                    .foregroundStyle(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
            }
        }
    }

    private var tableHeader: some View {
        HStack(spacing: 0) {
            Text("DURATION")
                .frame(width: 70, alignment: .center)
                .overlay(alignment: .trailing) { cellBorder }
            Text("PHASE")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 6)
                .overlay(alignment: .trailing) { cellBorder }
            Text("START")
                .frame(width: 70, alignment: .center)
                .overlay(alignment: .trailing) { cellBorder }
            Text("END")
                .frame(width: 70, alignment: .center)
        }
        .font(.system(size: 8, weight: .bold))
        .foregroundStyle(.gray)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.black.opacity(0.08))
        .overlay(Rectangle().stroke(.black, lineWidth: 1))
    }

    private func tableRow(label: String, start: String, end: String, duration: String, kind: PrintEventKind, isEven: Bool) -> some View {
        let bg: Color = switch kind {
        case .service: Color(red: 0, green: 0.48, blue: 1.0).opacity(0.06)
        case .rest: Color(red: 0.20, green: 0.78, blue: 0.35).opacity(0.06)
        case .settling: Color(red: 1.0, green: 0.58, blue: 0).opacity(0.06)
        }

        return HStack(spacing: 0) {
            Text(duration)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .frame(width: 70, alignment: .center)
                .overlay(alignment: .trailing) { cellBorder }
            ordinalText(label, baseFontSize: 10)
                .font(.system(size: 10, weight: .medium))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 6)
                .overlay(alignment: .trailing) { cellBorder }
            Text(start)
                .font(.system(size: 10, design: .monospaced))
                .frame(width: 70, alignment: .center)
                .overlay(alignment: .trailing) { cellBorder }
            Text(end)
                .font(.system(size: 10, design: .monospaced))
                .frame(width: 70, alignment: .center)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(bg)
        .overlay(Rectangle().stroke(.black, lineWidth: 1))
    }

    private var cellBorder: some View {
        Rectangle().fill(.black).frame(width: 1)
    }

    // MARK: - First Class

    private func fcSection(_ fc: FCResult) -> some View {
        VStack(spacing: 0) {
            sectionTitle("First class (dine on demand)")

            tableHeader

            ForEach(Array(fc.breaks.enumerated()), id: \.offset) { idx, b in
                tableRow(
                    label: b.label,
                    start: TimeFormatter.clock(b.start),
                    end: TimeFormatter.clock(b.end),
                    duration: TimeFormatter.dur(b.durationMin),
                    kind: .rest,
                    isEven: idx % 2 == 0
                )
            }
        }
    }

    // MARK: - Break Summary

    private var breakSummarySection: some View {
        VStack(spacing: 0) {
            let title = sectorLabel.isEmpty ? "Break summary" : "Break summary: \(sectorLabel)"
            sectionTitle(title)

            breakSummaryHeader

            ForEach(Array(breakGroups.enumerated()), id: \.offset) { idx, group in
                breakSummaryRow(group: group, isEven: idx % 2 == 0)
            }
        }
    }

    private var breakSummaryHeader: some View {
        HStack(spacing: 0) {
            Text("BREAK")
                .frame(width: 80, alignment: .leading)
                .overlay(alignment: .trailing) { cellBorder }
            Text("CREW")
                .frame(width: 40, alignment: .center)
                .overlay(alignment: .trailing) { cellBorder }
            Text("SENIORS")
                .frame(maxWidth: .infinity, alignment: .center)
                .overlay(alignment: .trailing) { cellBorder }
            if hasFG1 {
                Text("FG1")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .overlay(alignment: .trailing) { cellBorder }
            }
            Text("GR1")
                .frame(maxWidth: .infinity, alignment: .center)
                .overlay(alignment: .trailing) { cellBorder }
            Text("GR2")
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .font(.system(size: 8, weight: .bold))
        .foregroundStyle(.gray)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.black.opacity(0.08))
        .overlay(Rectangle().stroke(.black, lineWidth: 1))
    }

    private func breakSummaryRow(group: BreakGroupEntry, isEven: Bool) -> some View {
        let ordinal: String = switch group.breakNumber {
        case 1: "1st Break"
        case 2: "2nd Break"
        case 3: "3rd Break"
        default: "\(group.breakNumber)th Break"
        }

        return HStack(spacing: 0) {
            Text(ordinal)
                .font(.system(size: 10, weight: .medium))
                .frame(width: 80, alignment: .leading)
                .overlay(alignment: .trailing) { cellBorder }
            Text("\(group.count)")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .frame(width: 40, alignment: .center)
                .overlay(alignment: .trailing) { cellBorder }
            Text(group.seniors)
                .font(.system(size: 9))
                .padding(.leading, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .trailing) { cellBorder }
            if hasFG1 {
                Text(group.fg1)
                    .font(.system(size: 9))
                    .padding(.leading, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(alignment: .trailing) { cellBorder }
            }
            Text(group.gr1)
                .font(.system(size: 9))
                .padding(.leading, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .trailing) { cellBorder }
            Text(group.gr2)
                .font(.system(size: 9))
                .padding(.leading, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isEven ? Color.black.opacity(0.03) : Color.white)
        .overlay(Rectangle().stroke(.black, lineWidth: 1))
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 4) {
            Rectangle().fill(.black).frame(height: 1)
            HStack {
                Text("Generated by KiS Extensions")
                    .font(.system(size: 8))
                    .foregroundStyle(.gray)
                Spacer()
                Text("Verify with official EK documentation")
                    .font(.system(size: 8))
                    .foregroundStyle(.gray)
            }
        }
    }

    // MARK: - Helpers

    private func sectionTitle(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .bold))
            .tracking(0.8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 6)
    }
}

// MARK: - Print Timeline Builder

private enum PrintEventKind {
    case settling, service, rest
}

private struct PrintTimelineEvent {
    let label: String
    let start: Int
    let end: Int
    let kind: PrintEventKind
}

private func buildPrintTimeline(_ c: CalculationResult) -> [PrintTimelineEvent] {
    var events: [PrintTimelineEvent] = []

    if c.isLong, let ss = c.settlingStart, let se = c.settlingEnd {
        events.append(PrintTimelineEvent(label: "Settling-in duties", start: ss, end: se, kind: .settling))
    }

    for s in c.services {
        events.append(PrintTimelineEvent(label: s.label, start: s.start, end: s.end, kind: .service))
    }

    for b in c.breaks {
        events.append(PrintTimelineEvent(label: b.label, start: b.start, end: b.end, kind: .rest))
    }

    events.sort { $0.start < $1.start }
    return events
}
