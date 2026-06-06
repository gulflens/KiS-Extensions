import SwiftUI
import UIKit

// MARK: - Flight Crew Checklist Printer

enum FlightCrewChecklistPrinter {

    struct ScheduleRow {
        let time: Date
        let note: String
    }

    struct CrewRow {
        let role: String
        let name: String
        let assignment: String
    }

    @MainActor
    static func print(
        takeoff: Date,
        landing: Date,
        topOfDescent: Date,
        twentyToTop: Date,
        durationMinutes: Int,
        crew: [CrewRow],
        schedule: [ScheduleRow],
        sectorLabel: String = ""
    ) {
        let page1 = PrintableChecklist(
            takeoff: takeoff,
            landing: landing,
            topOfDescent: topOfDescent,
            twentyToTop: twentyToTop,
            durationMinutes: durationMinutes,
            crew: crew,
            schedule: schedule,
            sectorLabel: sectorLabel
        )
        .frame(width: 595, height: 842)

        let page2 = PrintableGuidelines()
            .frame(width: 595, height: 842)

        let r1 = ImageRenderer(content: page1)
        r1.scale = 3
        let r2 = ImageRenderer(content: page2)
        r2.scale = 3
        guard let img1 = r1.uiImage, let img2 = r2.uiImage else { return }

        let info = UIPrintInfo(dictionary: nil)
        info.jobName = "Flight Crew Checklist"
        info.outputType = .grayscale

        let controller = UIPrintInteractionController.shared
        controller.printInfo = info
        controller.printingItems = [img1, img2]
        controller.present(animated: true)
    }
}

// MARK: - Printable Checklist

private struct PrintableChecklist: View {
    let takeoff: Date
    let landing: Date
    let topOfDescent: Date
    let twentyToTop: Date
    let durationMinutes: Int
    let crew: [FlightCrewChecklistPrinter.CrewRow]
    let schedule: [FlightCrewChecklistPrinter.ScheduleRow]
    let sectorLabel: String

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    private static let stampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd MMM yyyy  HH:mm"
        return f
    }()

    var body: some View {
        VStack(spacing: 0) {
            header
            Spacer().frame(height: 24)
            keyTimes
            Spacer().frame(height: 28)
            crewSection
            Spacer().frame(height: 28)
            scheduleSection
            Spacer()
            footer
        }
        .padding(36)
        .frame(width: 595, height: 842)
        .background(Color.white)
        .foregroundStyle(.black)
    }

    // MARK: Header

    private var header: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Flight Crew Checklist")
                    .font(.system(size: 20, weight: .bold))
                Spacer()
                Text(Self.stampFormatter.string(from: Date()))
                    .font(.system(size: 11))
                    .foregroundStyle(.gray)
            }
            Rectangle().fill(.black).frame(height: 1.5)
            if !sectorLabel.isEmpty {
                HStack {
                    Text("Sector: \(sectorLabel)")
                        .font(.system(size: 11, weight: .semibold))
                    Spacer()
                }
                .padding(.top, 2)
            }
        }
    }

    // MARK: Key Times

    private var keyTimes: some View {
        VStack(spacing: 0) {
            sectionTitle("Key times")
            HStack(spacing: 0) {
                cell("Take off", Self.timeFormatter.string(from: takeoff))
                cell("Duration", formatDuration(durationMinutes))
                cell("20 to top", Self.timeFormatter.string(from: twentyToTop))
                cell("TOD", Self.timeFormatter.string(from: topOfDescent))
                cell("Landing", Self.timeFormatter.string(from: landing))
            }
            .overlay(Rectangle().stroke(.black, lineWidth: 1))
        }
    }

    private func cell(_ label: String, _ value: String) -> some View {
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

    // MARK: Crew

    private var crewSection: some View {
        VStack(spacing: 0) {
            sectionTitle("Flight crew")
            crewHeader
            if crew.isEmpty {
                Text("No crew entered")
                    .font(.system(size: 10))
                    .foregroundStyle(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .overlay(Rectangle().stroke(.black, lineWidth: 1))
            } else {
                ForEach(Array(crew.enumerated()), id: \.offset) { idx, row in
                    crewRow(row, isEven: idx % 2 == 0)
                }
            }
        }
    }

    private var crewHeader: some View {
        HStack(spacing: 0) {
            Text("ROLE")
                .frame(width: 90, alignment: .leading)
                .overlay(alignment: .trailing) { cellBorder }
            Text("NAME")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 6)
                .overlay(alignment: .trailing) { cellBorder }
            Text("ASSIGNMENT")
                .frame(width: 80, alignment: .leading)
                .padding(.leading, 6)
        }
        .font(.system(size: 8, weight: .bold))
        .foregroundStyle(.gray)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.black.opacity(0.08))
        .overlay(Rectangle().stroke(.black, lineWidth: 1))
    }

    private func crewRow(_ row: FlightCrewChecklistPrinter.CrewRow, isEven: Bool) -> some View {
        HStack(spacing: 0) {
            Text(row.role)
                .font(.system(size: 10, weight: .medium))
                .frame(width: 90, alignment: .leading)
                .overlay(alignment: .trailing) { cellBorder }
            Text(row.name.isEmpty ? "—" : row.name)
                .font(.system(size: 10))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 6)
                .overlay(alignment: .trailing) { cellBorder }
            Text(row.assignment)
                .font(.system(size: 10))
                .frame(width: 80, alignment: .leading)
                .padding(.leading, 6)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(isEven ? Color.black.opacity(0.03) : Color.white)
        .overlay(Rectangle().stroke(.black, lineWidth: 1))
    }

    // MARK: Schedule

    private static let singleColumnThreshold = 16

    private var scheduleSection: some View {
        VStack(spacing: 0) {
            sectionTitle("Call schedule")
            if schedule.isEmpty {
                scheduleHeader
                Text("No calls scheduled")
                    .font(.system(size: 10))
                    .foregroundStyle(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .overlay(Rectangle().stroke(.black, lineWidth: 1))
            } else if schedule.count > Self.singleColumnThreshold {
                twoColumnSchedule
            } else {
                singleColumnSchedule
            }
        }
    }

    private var singleColumnSchedule: some View {
        VStack(spacing: 0) {
            scheduleHeader
            ForEach(Array(schedule.enumerated()), id: \.offset) { idx, row in
                scheduleRow(row, isEven: idx % 2 == 0)
            }
        }
    }

    private var twoColumnSchedule: some View {
        let mid = (schedule.count + 1) / 2
        let left = Array(schedule.prefix(mid))
        let right = Array(schedule.suffix(schedule.count - mid))
        return HStack(alignment: .top, spacing: 12) {
            scheduleColumn(rows: left)
            scheduleColumn(rows: right)
        }
    }

    private func scheduleColumn(rows: [FlightCrewChecklistPrinter.ScheduleRow]) -> some View {
        VStack(spacing: 0) {
            narrowScheduleHeader
            ForEach(Array(rows.enumerated()), id: \.offset) { idx, row in
                narrowScheduleRow(row, isEven: idx % 2 == 0)
            }
        }
    }

    private var narrowScheduleHeader: some View {
        HStack(spacing: 0) {
            Text("TIME")
                .frame(width: 60, alignment: .leading)
                .overlay(alignment: .trailing) { cellBorder }
            Text("NOTES")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 6)
                .overlay(alignment: .trailing) { cellBorder }
            Text("DONE")
                .frame(width: 50, alignment: .center)
        }
        .font(.system(size: 8, weight: .bold))
        .foregroundStyle(.gray)
        .padding(.horizontal, 6)
        .padding(.vertical, 5)
        .background(Color.black.opacity(0.08))
        .overlay(Rectangle().stroke(.black, lineWidth: 1))
    }

    private func narrowScheduleRow(_ row: FlightCrewChecklistPrinter.ScheduleRow, isEven: Bool) -> some View {
        HStack(spacing: 0) {
            Text(Self.timeFormatter.string(from: row.time))
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .frame(width: 60, alignment: .leading)
                .overlay(alignment: .trailing) { cellBorder }
            Text(row.note.isEmpty ? "Call" : row.note)
                .font(.system(size: 9))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 4)
                .overlay(alignment: .trailing) { cellBorder }
            Rectangle()
                .stroke(.black, lineWidth: 1)
                .frame(width: 12, height: 12)
                .frame(width: 50, alignment: .center)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(isEven ? Color.black.opacity(0.03) : Color.white)
        .overlay(Rectangle().stroke(.black, lineWidth: 1))
    }

    private var scheduleHeader: some View {
        HStack(spacing: 0) {
            Text("TIME")
                .frame(width: 90, alignment: .leading)
                .overlay(alignment: .trailing) { cellBorder }
            Text("NOTES")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 6)
                .overlay(alignment: .trailing) { cellBorder }
            Text("DONE")
                .frame(width: 80, alignment: .center)
        }
        .font(.system(size: 8, weight: .bold))
        .foregroundStyle(.gray)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.black.opacity(0.08))
        .overlay(Rectangle().stroke(.black, lineWidth: 1))
    }

    private func scheduleRow(_ row: FlightCrewChecklistPrinter.ScheduleRow, isEven: Bool) -> some View {
        HStack(spacing: 0) {
            Text(Self.timeFormatter.string(from: row.time))
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .frame(width: 90, alignment: .leading)
                .overlay(alignment: .trailing) { cellBorder }
            Text(row.note.isEmpty ? "Call" : row.note)
                .font(.system(size: 10))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 6)
                .overlay(alignment: .trailing) { cellBorder }
            // Empty checkbox for pencil ticking
            Rectangle()
                .stroke(.black, lineWidth: 1)
                .frame(width: 14, height: 14)
                .frame(width: 80, alignment: .center)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(isEven ? Color.black.opacity(0.03) : Color.white)
        .overlay(Rectangle().stroke(.black, lineWidth: 1))
    }

    // MARK: Footer

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

    // MARK: Helpers

    private var cellBorder: some View {
        Rectangle().fill(.black).frame(width: 1)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .bold))
            .tracking(0.8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 6)
    }

    private func formatDuration(_ minutes: Int) -> String {
        let h = max(0, minutes) / 60
        let m = max(0, minutes) % 60
        return String(format: "%02d:%02d", h, m)
    }
}

// MARK: - Printable Guidelines (page 2)

private struct PrintableGuidelines: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Spacer().frame(height: 10)
            responsibleCrewTable
            ml2Note
            Spacer().frame(height: 10)
            twoColumn
            Spacer()
            footer
        }
        .padding(28)
        .frame(width: 595, height: 842)
        .background(Color.white)
        .foregroundStyle(.black)
    }

    private var ml2Note: some View {
        Text("On A380 2/3 Class, ML2 is responsible for flight-crew service; remaining crew support as needed.")
            .font(.system(size: 8, weight: .medium))
            .foregroundStyle(.secondary)
            .padding(.top, 4)
    }

    private var header: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Flight Crew Service Guidelines")
                    .font(.system(size: 18, weight: .bold))
                Spacer()
                Text("Reference")
                    .font(.system(size: 10))
                    .foregroundStyle(.gray)
            }
            Rectangle().fill(.black).frame(height: 1.5)
        }
    }

    private var responsibleCrewTable: some View {
        VStack(spacing: 0) {
            sectionTitle("Responsible crew for flight crew service")
            crewTableHeader
            crewTableRow("A380 4 Class", "MR3A", "ML5", isEven: true)
            crewTableRow("A380 3 Class", "ML2", "ML5", isEven: false)
            crewTableRow("A380 2 Class", "ML2", "ML5", isEven: true)
            crewTableRow("B777 3 Class", "L1", "R1", isEven: false)
            crewTableRow("B777 2 Class", "L1A", "R1", isEven: true)
        }
    }

    private var crewTableHeader: some View {
        HStack(spacing: 0) {
            Text("AIRCRAFT")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 6)
            Text("RESPONSIBLE CREW")
                .frame(width: 160, alignment: .center)
            Text("IF ON REST")
                .frame(width: 100, alignment: .center)
        }
        .font(.system(size: 8, weight: .bold))
        .foregroundStyle(.gray)
        .padding(.vertical, 5)
        .background(Color.black.opacity(0.08))
        .overlay(Rectangle().stroke(.black, lineWidth: 1))
    }

    private func crewTableRow(_ aircraft: String, _ primary: String, _ onRest: String, isEven: Bool) -> some View {
        HStack(spacing: 0) {
            Text(aircraft)
                .font(.system(size: 11))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 6)
            Text(primary)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .frame(width: 160, alignment: .center)
            Text(onRest)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .frame(width: 100, alignment: .center)
        }
        .padding(.vertical, 6)
        .background(isEven ? Color.black.opacity(0.03) : Color.white)
        .overlay(Rectangle().stroke(.black, lineWidth: 1))
    }

    private var twoColumn: some View {
        HStack(alignment: .top, spacing: 18) {
            // Left column — rules
            VStack(alignment: .leading, spacing: 10) {
                bulletSection("Communication", bullets: [
                    "Note from briefing how each pilot wishes to be called.",
                    "Speak to captain first; wait before talking on the flight deck.",
                    "Hand-up signal means hold — they're receiving comms.",
                    "Answer interphone calls from the flight crew immediately."
                ])
                bulletSection("Do not serve", bullets: [
                    "Shellfish, molluscs or crustaceans.",
                    "Same appetiser / main / dessert for both pilots (food-poisoning risk).",
                    "First Class galley food, including caviar.",
                    "No alcohol in the flight deck (serve, consume, or bring — prohibited)."
                ])
                bulletSection("Must do", bullets: [
                    "Prevent contamination of flight-crew food.",
                    "Serve heated meals promptly — avoid serving them cold."
                ])
                bulletSection("Equipment", bullets: [
                    "Paper cups + lids only; no glassware/mugs in the flight deck.",
                    "If no FD cups, use other cabin (JCL/WCL) paper cups with lids."
                ])
                bulletSection("Catering — Food", bullets: [
                    "Crew Products container loaded on all flights (FD drawer).",
                    "Snacks tray + bread box/bag = 'Pilot' sticker.",
                    "Hot meals labelled TCR, loaded in foils — plating not required.",
                    "Meal items bulk-loaded; assemble per requested items."
                ])
                mealCountTable
                bulletSection("Drinks", bullets: [
                    "Cat 1: ask pilot for small/large water; Cat 2-8: large bottle.",
                    "Hand water bottle directly to the flight crew.",
                    "Don't pass prepared drinks over the centre console."
                ])
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)

            // Right column — workflow
            VStack(alignment: .leading, spacing: 10) {
                Text("CABIN CREW DUTIES — FLIGHT CREW")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.8)
                bulletSection("Before departure", bullets: [
                    "Introduce yourself and take a drink order.",
                    "Deliver drinks, water bottles, wrapped snacks, tissue box.",
                    "Place bar waste bag(s) in the flight deck.",
                    "Do not bag flight-deck food foils.",
                    "Check available food.",
                    "Before last cabin door close: remove food/drinks (keep water bottles).",
                    "Turnarounds: flight crew may eat on the ground."
                ])
                bulletSection("After take-off", bullets: [
                    "Ask the purser when and how often to contact the flight crew.",
                    "Return collected food/drinks to the flight deck.",
                    "Flight crew may need lavatory priority — delay customers if needed."
                ])
                bulletSection("Inflight — cruise", bullets: [
                    "B777 2 Class: close curtains when FD exits; open on return.",
                    "Tell flight crew what food is available.",
                    "Tell flight crew when you will take part in a meal service.",
                    "Arrange a suitable time to prepare a flight-crew meal.",
                    "Captain decides who eats first.",
                    "Meal must not be ready before the arranged time.",
                    "Offer a drink with the meal.",
                    "Give a table linen when delivering the meal tray."
                ])
                bulletSection("Before landing", bullets: [
                    "Remove food and drinks (except water bottles) from the flight deck."
                ])
                bulletSection("After landing", bullets: [
                    "Collect Emirates plastic bag / waste collection bag and used water bottles.",
                    "Place by the waste bin in the galley nearest the flight deck."
                ])
                bulletSection("Aircraft-specific waste", bullets: [
                    "A380 / A350: 2 bar waste bags in pilot's individual waste bins (outboard).",
                    "B777: reusable hook + bar waste bag at the centre console."
                ])
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    private var mealCountTable: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Hot meals per crew member per sector")
                .font(.system(size: 9, weight: .bold))
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Text("FLT CAT").frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 4)
                    Text("EX-DUBAI").frame(width: 70, alignment: .center)
                    Text("RETURN").frame(width: 60, alignment: .center)
                }
                .font(.system(size: 7, weight: .bold))
                .foregroundStyle(.gray)
                .padding(.vertical, 3)
                .background(Color.black.opacity(0.08))
                .overlay(Rectangle().stroke(.black, lineWidth: 0.5))
                mealCountRow("Cat 1-2", "1", "—")
                mealCountRow("Cat 3-8", "2", "—")
            }
        }
    }

    private func mealCountRow(_ cat: String, _ exDxb: String, _ ret: String) -> some View {
        HStack(spacing: 0) {
            Text(cat).font(.system(size: 8)).frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 4)
            Text(exDxb).font(.system(size: 9, design: .monospaced)).frame(width: 70, alignment: .center)
            Text(ret).font(.system(size: 9, design: .monospaced)).frame(width: 60, alignment: .center)
        }
        .padding(.vertical, 3)
        .overlay(Rectangle().stroke(.black, lineWidth: 0.5))
    }

    private func bulletSection(_ title: String, bullets: [String]) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 9, weight: .bold))
            ForEach(bullets, id: \.self) { item in
                HStack(alignment: .top, spacing: 4) {
                    Text("•")
                        .font(.system(size: 8))
                    Text(item)
                        .font(.system(size: 8))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

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

    private func sectionTitle(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .bold))
            .tracking(0.8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 6)
    }
}
