import SwiftUI
import SwiftData
import UIKit

// MARK: - Briefing Mode Environment

/// When true, the table is rendered as a finished briefing document:
/// no editable affordances, no `+` badge button, no input chrome on
/// position/break cells. Used for the on-screen briefing toggle and
/// always forced on for image/PDF exports.
private struct BriefingModeKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

private struct ExportBorderWidthKey: EnvironmentKey {
    static let defaultValue: CGFloat = CrewTableStyle.cellBorderWidth
}

extension EnvironmentValues {
    var briefingMode: Bool {
        get { self[BriefingModeKey.self] }
        set { self[BriefingModeKey.self] = newValue }
    }
    var exportBorderWidth: CGFloat {
        get { self[ExportBorderWidthKey.self] }
        set { self[ExportBorderWidthKey.self] = newValue }
    }
}

// MARK: - Visual Style

/// Centralized colors / metrics for the crew positions output table.
/// Tuned to look good on screen, in screenshots and when printed for crew briefings.
enum CrewTableStyle {
    // Surfaces
    static let pageBG       = Color(.systemBackground)
    static let cardBG       = Color.white
    static let altRowBG     = Color.white

    // Borders — thin single black lines on screen, heavy for export
    static let cellBorder   = Color.black
    static let cardBorder   = Color.black
    static let cellBorderWidth: CGFloat = 0.5
    static let exportBorderWidth: CGFloat = 1.0

    // Header row — dark Emirates red with bold white text
    static let headerBG     = Color(red: 200/255, green: 16/255, blue: 46/255)
    static let headerText   = Color.white
    static let headerDivider = Color.black

    // Position / break input cells
    static let inputBG      = Color(.systemGray6)

    // Card chrome — flat, no rounding
    static let cardCorner: CGFloat = 0
    static let cardShadow   = Color.clear

    // Cell metrics
    static let cellPadH: CGFloat = 4
    static let rowPadV: CGFloat  = 0
    static let rowHeight: CGFloat = 24
    static let sectionHeaderHeight: CGFloat = 24
}

/// Wraps table content and applies the correct border width from environment.
private struct ExportBorderAwareTable<Content: View>: View {
    @Environment(\.exportBorderWidth) private var borderWidth
    @ViewBuilder let content: Content

    var body: some View {
        content
            .border(CrewTableStyle.cardBorder, width: borderWidth)
    }
}

// MARK: - Column Width Computation

/// Measures actual text content to produce tight-fit column widths.
struct ColumnWidths {
    var rowNum: CGFloat
    var grade: CGFloat
    var name: CGFloat
    var positionWidths: [CGFloat]  // one width per sector
    var breakCol: CGFloat
    var fullName: CGFloat
    var staff: CGFloat
    var flag: CGFloat
    var nationality: CGFloat
    var languages: CGFloat
    var tig: CGFloat
    var badges: CGFloat
    var flown: CGFloat
    var comment: CGFloat

    /// Total width of all columns (excluding hidden ones).
    func totalWidth(sectors: Int, hasBreaks: [Bool], hiddenColumns: Set<String>) -> CGFloat {
        var w: CGFloat = rowNum
        if !hiddenColumns.contains("grade") { w += grade }
        if !hiddenColumns.contains("name") { w += name }
        for i in 0..<sectors {
            if !hiddenColumns.contains("pos\(i)") { w += positionWidth(for: i) }
            if !hiddenColumns.contains("brk\(i)") && hasBreaks.indices.contains(i) && hasBreaks[i] { w += breakCol }
        }
        if !hiddenColumns.contains("fullName") { w += fullName }
        if !hiddenColumns.contains("staff") { w += staff }
        if !hiddenColumns.contains("nationality") { w += flag + nationality }
        if !hiddenColumns.contains("languages") { w += languages }
        if !hiddenColumns.contains("tig") { w += tig }
        if !hiddenColumns.contains("badges") { w += badges }
        if !hiddenColumns.contains("flown") { w += flown }
        if !hiddenColumns.contains("comment") { w += comment }
        return w + 24 // 12pt padding on each side
    }

    /// Safe accessor for per-sector position width; falls back to a reasonable minimum.
    func positionWidth(for sector: Int) -> CGFloat {
        positionWidths.indices.contains(sector) ? positionWidths[sector] : 80
    }

    private static let pad: CGFloat = CrewTableStyle.cellPadH * 2

    /// Measure a string at caption size and return width + cell padding.
    private static func measure(_ text: String, font: UIFont) -> CGFloat {
        let size = (text as NSString).size(withAttributes: [.font: font])
        return ceil(size.width) + pad
    }

    /// Measure the widest single word in a header label (since headers wrap).
    private static func measureWidestWord(_ text: String, font: UIFont) -> CGFloat {
        text.split(separator: " ")
            .map { measure(String($0), font: font) }
            .max() ?? measure(text, font: font)
    }

    /// Build widths from crew data, using the widest header word as minimums (headers wrap).
    static func compute(from crew: [CrewMember], sectors: Int, hasBreaks: [Bool]) -> ColumnWidths {
        let caption = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize)
        let captionBold = UIFont.boldSystemFont(ofSize: UIFont.smallSystemFontSize - 1)
        let mono = UIFont.monospacedSystemFont(ofSize: 12, weight: .semibold)
        let monoSmall = UIFont.monospacedSystemFont(ofSize: 11, weight: .semibold)
        let headerFont = UIFont.systemFont(ofSize: 10, weight: .bold)

        // Header minimum widths (full label, single-line headers)
        let hFont = headerFont
        let rowNum = max(measure("N.", font: hFont), measure("\(crew.count)", font: caption)) + 8
        var grade = measure("Grade", font: hFont)
        var name = measure("Nickname", font: hFont)
        let positionMin = measure("Position", font: hFont)
        var perSectorPosition = [CGFloat](repeating: positionMin, count: sectors)
        var breakCol = measure("Break", font: hFont)
        var fullName = measure("Full name", font: hFont)
        var staff = measure("Staff number", font: hFont)
        let flag: CGFloat = 22
        var nationality = measure("Nationality", font: hFont)
        var languages = measure("Languages", font: hFont)
        var tig = measure("Time in grade", font: hFont)
        var badges = measure("BADGES", font: headerFont)
        var flown = measure("FLOWN", font: headerFont)
        var comment = measure("COMMENT", font: headerFont)

        for m in crew {
            grade = max(grade, measure(m.grade.rawValue, font: captionBold))
            name = max(name, measure(m.nickname, font: caption))
            fullName = max(fullName, measure(m.fullname, font: caption))
            staff = max(staff, measure(m.staffNumber, font: UIFont.monospacedSystemFont(ofSize: UIFont.smallSystemFontSize, weight: .regular)))
            nationality = max(nationality, measure(m.nationality, font: caption))
            languages = max(languages, measure(m.languages.joined(separator: ", "), font: caption))
            tig = max(tig, measure(m.timeInGrade, font: caption))
            comment = max(comment, measure(CommentFormatter.singleLine(m.comment), font: caption))

            let totalFlown = m.destinationExperience.values.reduce(0, +)
            if totalFlown > 0 {
                flown = max(flown, measure("\(totalFlown)", font: caption))
            }

            // Badge width: rough estimate per badge pill + IR number
            let hasIR = m.ratingIR <= 20
            let portalBadgeCount = m.badges.filter { !AllocatedBadgeCodes.all.contains($0) }.count
            let badgeCount = portalBadgeCount
            let irWidth: CGFloat = hasIR ? 24 : 0
            if badgeCount > 0 || hasIR {
                badges = max(badges, CGFloat(badgeCount) * 30 + irWidth + pad)
            }

            for i in 0..<sectors {
                // Measure position text + allocated badges width
                let posText = m.positions[i] ?? ""
                let posW = posText.isEmpty ? 0 : measure(posText, font: mono)

                let sectorBadges = m.allocatedBadges[i] ?? []
                let badgeFont = UIFont.systemFont(ofSize: 9, weight: .heavy)
                var badgesW: CGFloat = 0
                for code in sectorBadges {
                    let label: String
                    switch code {
                    case 32022: label = "MFP"
                    case 170920: label = "W"
                    case -2: label = "UD"
                    case -3: label = "IR"
                    case -4: label = "PA"
                    default: label = "?"
                    }
                    badgesW += measure(label, font: badgeFont) + 4 // badge padding + spacing
                }

                let totalPosW = posW + badgesW
                perSectorPosition[i] = max(perSectorPosition[i], totalPosW)

                if hasBreaks.indices.contains(i) && hasBreaks[i], let brk = m.breaks[i] {
                    breakCol = max(breakCol, measure("\(brk)", font: monoSmall))
                }
            }
        }

        // Cap comment so it doesn't blow out — full text is shown via tap/hover popover
        comment = min(comment, 300)
        // Cap languages
        languages = min(languages, 200)

        // Add minimal space for comfortable editing per sector
        for i in 0..<sectors {
            perSectorPosition[i] += 8
        }

        return ColumnWidths(
            rowNum: rowNum, grade: grade, name: name, positionWidths: perSectorPosition, breakCol: breakCol,
            fullName: fullName, staff: staff, flag: flag,
            nationality: nationality, languages: languages, tig: tig,
            badges: badges, flown: flown, comment: comment
        )
    }
}

struct CrewTableView: View {
    let trip: ParsedTrip
    let doPositions: Bool

    @Environment(\.modelContext) private var modelContext
    @Query private var settingsArray: [AppSettings]

    @State private var crewMembers: [CrewMember] = []
    @State private var allocationErrors: [AllocationEngine.AllocationError] = []
    @State private var showPositionEditor = false
    @State private var showFlightInfo = false
    @State private var showControls = true
    @State private var hiddenColumns: Set<String> = []
    @State private var hasBreaks: [Bool] = []
    @State private var copiedFeedback = false
    // Active position cell for badge allocation from toolbar
    @State private var activeCrewIndex: Int? = nil
    @State private var activeSector: Int? = nil
    @State private var zoomScale: CGFloat = 1.0
    @State private var availableSize: CGSize = .zero
    @State private var colWidths = ColumnWidths(
        rowNum: 28, grade: 38, name: 120, positionWidths: [80], breakCol: 45,
        fullName: 160, staff: 58, flag: 22, nationality: 100,
        languages: 160, tig: 90, badges: 120, flown: 60, comment: 260
    )

    // Briefing mode + share/export state
    @State private var briefingMode: Bool = false
    @State private var shareURL: ShareableURL? = nil

    // Save state
    @State private var isSaved = false
    @State private var showSavedFeedback = false
    @State private var autoSaveTask: Task<Void, Never>?

    // Notes state
    @State private var tripNotes: String = ""
    @State private var showNotesPopover = false

    // Override state
    @State private var overrideMode = false
    @State private var overrideSheetMode: CrewOverrideMode? = nil

    private var settings: AppSettings? { settingsArray.first }

    /// Scale factor that fits the full table into the available display area.
    private var fitZoomScale: CGFloat {
        guard availableSize.width > 0, availableSize.height > 0 else { return 1.0 }
        let tableW = colWidths.totalWidth(
            sectors: trip.flightInfo.sectors,
            hasBreaks: hasBreaks,
            hiddenColumns: hiddenColumns
        )
        guard tableW > 0 else { return 1.0 }
        let widthScale = availableSize.width / tableW
        let breakRows = breakSectorIndices.isEmpty ? 0 : (breakSectorIndices.map { breakGroups(for: $0).count }.max() ?? 0) + 3
        let totalRows = CGFloat(crewMembers.count + 10 + breakRows)
        let tableH = totalRows * CrewTableStyle.rowHeight
        guard tableH > 0 else { return widthScale }
        let heightScale = availableSize.height / tableH
        return min(widthScale, heightScale)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Error banner
            if !allocationErrors.isEmpty {
                errorBanner
            }

            // Action bar
            actionBar

            // Main content
            HStack(spacing: 0) {
                GeometryReader { geo in
                    ZoomableTableView(zoomScale: $zoomScale, fitScale: fitZoomScale) {
                        tableContent
                            .environment(\.briefingMode, briefingMode)
                    }
                    .background(CrewTableStyle.pageBG)
                    .onAppear {
                        availableSize = geo.size
                        DispatchQueue.main.async {
                            zoomScale = fitZoomScale
                        }
                    }
                    .onChange(of: geo.size) { _, newSize in
                        availableSize = newSize
                        if zoomScale < fitZoomScale {
                            zoomScale = fitZoomScale
                        }
                    }
                }

                // Side panels
                if showPositionEditor {
                    Divider()
                    PositionEditorView(
                        trip: trip,
                        onApply: { newPositions in
                            applyCustomPositions(newPositions)
                        },
                        onClose: { showPositionEditor = false }
                    )
                    .frame(width: 440)
                }

                if showFlightInfo && (settings?.additionalInfo ?? true) {
                    Divider()
                    FlightInfoSidebar(trip: trip, crewMembers: crewMembers)
                }
            }
        }
        .navigationTitle("EK \(trip.flightInfo.flightNumber)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .onAppear {
            runAllocation()
            checkIfSaved()
            saveTrip()
        }
        .onChange(of: crewMembers) { _, newMembers in
            // Recalculate column widths when crew data changes (e.g. badges added)
            colWidths = ColumnWidths.compute(
                from: newMembers,
                sectors: trip.flightInfo.sectors,
                hasBreaks: hasBreaks
            )

            autoSaveTask?.cancel()
            autoSaveTask = Task {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                saveTrip()
            }
        }
        .onChange(of: tripNotes) { _, _ in
            guard isSaved else { return }
            autoSaveTask?.cancel()
            autoSaveTask = Task {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                saveTrip()
            }
        }
        .sheet(item: $shareURL) { item in
            ActivityView(items: [item.url])
        }
        .sheet(item: $overrideSheetMode) { mode in
            NavigationStack {
                CrewOverrideSheet(
                    mode: mode,
                    sectors: trip.flightInfo.sectors,
                    onSave: { member in
                        handleOverrideSave(mode: mode, member: member)
                    },
                    onDelete: {
                        if case .edit(_, let index) = mode {
                            removeCrew(at: index)
                        }
                    }
                )
            }
        }

    }

    // MARK: - Table Content (shared between live view and export)

    /// The chromed crew positions card. Reused for on-screen rendering and
    /// for ImageRenderer-based image / PDF export.
    private var tableWidth: CGFloat {
        colWidths.totalWidth(
            sectors: trip.flightInfo.sectors,
            hasBreaks: hasBreaks,
            hiddenColumns: hiddenColumns
        ) - 24 // subtract the outer padding already accounted for in totalWidth
    }

    private static let titleDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd MMM yyyy"
        return f
    }()

    @ViewBuilder
    private func makeTableContent(includeLink: Bool, isExport: Bool = false, showOverrideControls: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            // Centered flight title
            HStack(spacing: 6) {
                Text("EK \(trip.flightInfo.flightNumber)")
                    .font(.subheadline.bold())
                Text("|")
                    .font(.subheadline.bold())
                    .foregroundStyle(.red)
                Text(trip.flightInfo.flightLegs.joined(separator: " – "))
                    .font(.subheadline.bold().monospaced())
                Text("|")
                    .font(.subheadline.bold())
                    .foregroundStyle(.red)
                Text(Self.titleDateFormatter.string(from: trip.flightInfo.flightDate))
                    .font(.subheadline.bold())
            }
            .frame(width: tableWidth, alignment: .center)
            .padding(.bottom, 4)

            HStack(alignment: .top, spacing: 4) {
                if showOverrideControls {
                    overrideColumn
                }

                ExportBorderAwareTable {
                    VStack(alignment: .leading, spacing: 0) {
                        headerRow
                        crewRows
                    }
                    .frame(width: tableWidth)
                    .clipped()
                    .background(CrewTableStyle.cardBG)
                }
            }

            breakSummaries()

            Text("* Positions may be adjusted to accommodate MFP2.0 or other operational requirements")
                .font(.caption)
                .foregroundStyle(.primary.opacity(0.7))

            if includeLink {
                HStack(spacing: 0) {
                    Text("* To change your comment, visit ")
                        .font(.caption)
                        .foregroundStyle(.primary.opacity(0.7))
                    Link("apps-crewportal.emirates.group/my.policy", destination: URL(string: "https://apps-crewportal.emirates.group/my.policy")!)
                        .font(.caption)
                    Text(" and then press \"Edit\"")
                        .font(.caption)
                        .foregroundStyle(.primary.opacity(0.7))
                }
            }
        }
        .padding(12)
    }

    private var tableContent: some View {
        makeTableContent(includeLink: true, showOverrideControls: overrideMode)
    }

    // MARK: - Error Banner

    private var errorBanner: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(allocationErrors.enumerated()), id: \.offset) { _, error in
                    HStack(spacing: 4) {
                        Image(systemName: error.severity == .error ? "exclamationmark.triangle.fill" :
                                error.severity == .warning ? "exclamationmark.circle.fill" : "info.circle.fill")
                            .font(.caption2)
                        Text(error.message)
                            .font(.caption)
                    }
    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(errorColor(error.severity).opacity(0.15))
                    .foregroundStyle(errorColor(error.severity))
                    .cornerRadius(6)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
    }

    private func errorColor(_ severity: AllocationEngine.AllocationError.Severity) -> Color {
        switch severity {
        case .error: return .red
        case .warning: return .orange
        case .info: return .green
        }
    }

    // MARK: - Header Row

    private var headerRow: some View {
        HStack(spacing: 0) {
            headerCell("N.", width: colWidths.rowNum)
            if !hiddenColumns.contains("grade") {
                headerCell("Grade", width: colWidths.grade, id: "grade")
            }
            if !hiddenColumns.contains("name") {
                headerCell("Nickname", width: colWidths.name, id: "name")
            }
            ForEach(0..<trip.flightInfo.sectors, id: \.self) { i in
                if !hiddenColumns.contains("pos\(i)") {
                    headerCell("Position", width: colWidths.positionWidth(for: i), id: "pos\(i)")
                }
                if !hiddenColumns.contains("brk\(i)") && hasBreaks.indices.contains(i) && hasBreaks[i] {
                    headerCell("Break", width: colWidths.breakCol, id: "brk\(i)")
                }
            }
            if !hiddenColumns.contains("fullName") {
                headerCell("Full name", width: colWidths.fullName, id: "fullName")
            }
            if !hiddenColumns.contains("staff") {
                headerCell("Staff number", width: colWidths.staff, id: "staff")
            }
            if !hiddenColumns.contains("nationality") {
                headerCell("Nationality", width: colWidths.flag + colWidths.nationality, id: "nationality")
            }
            if !hiddenColumns.contains("languages") {
                headerCell("Languages", width: colWidths.languages, id: "languages")
            }
            if !hiddenColumns.contains("tig") {
                headerCell("Time in grade", width: colWidths.tig, id: "tig")
            }
            if !hiddenColumns.contains("badges") {
                headerCell("Badges", width: colWidths.badges, id: "badges")
            }
            if !hiddenColumns.contains("flown") {
                headerCell("Flown", width: colWidths.flown, id: "flown")
            }
            if !hiddenColumns.contains("comment") {
                headerCell("Comment", width: colWidths.comment, id: "comment")
            }
        }
        .background(CrewTableStyle.headerBG)
    }

    @ViewBuilder
    private func headerCell(_ title: String, width: CGFloat, id: String? = nil) -> some View {
        HeaderCellView(title: title, width: width, id: id) { colId in
            if settings?.clickableHeaders ?? true {
                withAnimation { _ = hiddenColumns.insert(colId) }
            }
        }
    }
}

private struct HeaderCellView: View {
    let title: String
    let width: CGFloat
    let id: String?
    let onTap: (String) -> Void
    @Environment(\.exportBorderWidth) private var borderW

    var body: some View {
        Text(title)
            .font(.system(size: 10, weight: .heavy))
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .foregroundStyle(CrewTableStyle.headerText)
            .padding(.horizontal, CrewTableStyle.cellPadH)
            .padding(.vertical, 6)
            .frame(width: width, alignment: .center)
            .overlay(alignment: .trailing) {
                Rectangle().fill(CrewTableStyle.headerDivider)
                    .frame(width: borderW)
            }
            .overlay(alignment: .bottom) {
                Rectangle().fill(CrewTableStyle.cellBorder)
                    .frame(height: borderW)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if let id { onTap(id) }
            }
    }
}

extension CrewTableView {
    // MARK: - Crew Rows

    private var crewRows: some View {
        let positions = displayPositions
        return ForEach(gradeGroups, id: \.0) { grade, indices in
            GradeSectionHeader(
                grade: grade,
                count: indices.count,
                onAddCrew: overrideMode ? {
                    overrideSheetMode = .add(grade: grade)
                } : nil
            )

            ForEach(Array(indices.enumerated()), id: \.element) { sectionIdx, idx in
                CrewRowView(
                    member: $crewMembers[idx],
                    crewIndex: idx,
                    rowIndex: positions[idx] ?? 0,
                    sectionRowIndex: sectionIdx,
                    sectors: trip.flightInfo.sectors,
                    hasBreaks: hasBreaks,
                    hiddenColumns: hiddenColumns,
                    settings: settings,
                    allBreaks: currentBreaks,
                    colWidths: colWidths,
                    duplicatePositions: duplicatePositions,
                    onPositionFocus: { crewIdx, sector, focused in
                        if focused {
                            activeCrewIndex = crewIdx
                            activeSector = sector
                        }
                    },
                    isManualOverride: crewMembers[idx].isManualOverride
                )
            }
        }
    }

    // MARK: - Override Column (outside the table border)

    /// A column of edit buttons that aligns with each crew row, shown to the
    /// left of the bordered table when override mode is active.
    private var overrideColumn: some View {
        VStack(alignment: .center, spacing: 0) {
            // Spacer matching header row height
            Color.clear.frame(width: 28, height: CrewTableStyle.rowHeight)

            ForEach(gradeGroups, id: \.0) { grade, indices in
                // Spacer matching section header height
                Color.clear.frame(width: 28, height: CrewTableStyle.sectionHeaderHeight)

                ForEach(indices, id: \.self) { idx in
                    Button {
                        overrideSheetMode = .edit(member: crewMembers[idx], index: idx)
                    } label: {
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.orange)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 28, height: CrewTableStyle.rowHeight)
                }
            }
        }
    }

    private var displayPositions: [Int: Int] {
        var result: [Int: Int] = [:]
        var pos = 0
        for (_, indices) in gradeGroups {
            for idx in indices {
                result[idx] = pos
                pos += 1
            }
        }
        return result
    }

    /// For each sector, the set of position strings that appear more than once.
    private var duplicatePositions: [Int: Set<String>] {
        var result: [Int: Set<String>] = [:]
        for sector in 0..<trip.flightInfo.sectors {
            var seen: [String: Int] = [:]
            for member in crewMembers {
                let pos = (member.positions[sector] ?? "")
                    .trimmingCharacters(in: .whitespaces).uppercased()
                guard !pos.isEmpty else { continue }
                seen[pos, default: 0] += 1
            }
            let dupes = Set(seen.filter { $0.value > 1 }.map { $0.key })
            if !dupes.isEmpty { result[sector] = dupes }
        }
        return result
    }

    private var gradeGroups: [(CrewGrade, [Int])] {
        let order: [CrewGrade] = [.PUR, .CSV, .FG1, .GR1, .W, .GR2, .CSA]
        return order.compactMap { grade in
            let indices = crewMembers.indices
                .filter { crewMembers[$0].grade == grade }
                .sorted {
                    let numA = Int(crewMembers[$0].staffNumber.filter(\.isNumber)) ?? 0
                    let numB = Int(crewMembers[$1].staffNumber.filter(\.isNumber)) ?? 0
                    return numA < numB
                }
            return indices.isEmpty ? nil : (grade, indices)
        }
    }

    private var currentBreaks: [String: Int] {
        guard let reg = trip.registration,
              let typeCode = FleetRegistry.fleet[reg] else { return [:] }

        if trip.flightInfo.selectedFacility == Facility.crewSeats.rawValue,
           let entry = FleetLoader.shared.entry(forSuffix: String(reg.suffix(3))),
           let crewSeatsBreaks = BreaksData.crewSeatsBreaks(for: entry.type, classes: entry.classes) {
            return crewSeatsBreaks
        }

        let opType = OperationTypeResolver.resolve(
            registration: reg, isULR: trip.flightInfo.isULR, crewData: crewMembers
        ) ?? typeCode
        return BreaksData.clonedBreaks(for: opType) ?? [:]
    }

    private var currentBreakCapacity: Int? {
        guard let reg = trip.registration,
              let typeCode = FleetRegistry.fleet[reg] else { return nil }

        if trip.flightInfo.selectedFacility == Facility.crewSeats.rawValue {
            guard let entry = FleetLoader.shared.entry(forSuffix: String(reg.suffix(3))) else { return nil }
            return BreaksData.crewSeatsCapacity(for: entry.type)
        }

        let opType = OperationTypeResolver.resolve(
            registration: reg, isULR: trip.flightInfo.isULR, crewData: crewMembers
        ) ?? typeCode
        return BreaksData.crcCapacity(for: opType)
    }

    // MARK: - Break Summary

    private var breakSectorIndices: [Int] {
        (0..<trip.flightInfo.sectors).filter { sector in
            hasBreaks.indices.contains(sector) && hasBreaks[sector] && !breakGroups(for: sector).isEmpty
        }
    }

    @ViewBuilder
    private func breakSummaries() -> some View {
        let indices = breakSectorIndices
        if !indices.isEmpty {
            let spacing: CGFloat = 16
            let totalSpacing = spacing * CGFloat(max(indices.count - 1, 0))
            let perTableWidth = (tableWidth - totalSpacing) / CGFloat(indices.count)
            HStack(alignment: .top, spacing: spacing) {
                ForEach(indices, id: \.self) { sector in
                    BreakSummaryTable(
                        groups: breakGroups(for: sector),
                        totalWidth: perTableWidth,
                        sectorLabel: sectorLabel(for: sector),
                        capacity: currentBreakCapacity
                    )
                }
            }
        }
    }

    private func breakGroups(for sector: Int) -> [BreakGroupEntry] {
        struct MemberInfo {
            let nickname: String
            let grade: String
        }
        var grouped: [Int: [MemberInfo]] = [:]
        for member in crewMembers {
            guard !member.isSupy else { continue }
            if let brk = member.breaks[sector] {
                grouped[brk, default: []].append(MemberInfo(nickname: member.nickname, grade: member.grade.rawValue))
            }
        }
        return grouped
            .sorted { $0.key < $1.key }
            .map { entry in
                let members = entry.value
                let seniors = members.filter { ["PUR", "CSV"].contains($0.grade) }.map(\.nickname).joined(separator: ", ")
                let fg1 = members.filter { $0.grade == "FG1" }.map(\.nickname).joined(separator: ", ")
                let gr1 = members.filter { ["GR1", "W"].contains($0.grade) }.map(\.nickname).joined(separator: ", ")
                let gr2 = members.filter { ["GR2", "CSA"].contains($0.grade) }.map(\.nickname).joined(separator: ", ")
                return BreakGroupEntry(breakNumber: entry.key, count: members.count, seniors: seniors, fg1: fg1, gr1: gr1, gr2: gr2)
            }
    }

    private func sectorLabel(for sector: Int) -> String {
        let legs = trip.flightInfo.flightLegs
        let totalSectors = trip.flightInfo.sectors

        if legs.count == totalSectors + 1 {
            return "\(legs[sector]) - \(legs[sector + 1])"
        }

        // Portal scraper omits the final DXB: ["DXB", "TPE"] for a 2-sector round trip
        if legs.count == totalSectors, legs.indices.contains(sector) {
            let dep = legs[sector]
            let arr = (sector + 1 < legs.count) ? legs[sector + 1] : "DXB"
            return "\(dep) - \(arr)"
        }

        return "Sector \(sector + 1)"
    }

    // MARK: - Column Registry

    /// Fixed (non sector/break) columns that can be toggled from the visibility menu.
    /// IDs are the same strings used in `hiddenColumns`.
    static let toggleableColumns: [(id: String, title: String)] = [
        ("grade",       "Grade"),
        ("name",        "Nickname"),
        ("fullName",    "Full Name"),
        ("staff",       "Staff Number"),
        ("flag",        "Flag"),
        ("nationality", "Nationality"),
        ("languages",   "Languages"),
        ("tig",         "Time In Grade"),
        ("badges",      "Badges"),
        ("flown",       "Flown"),
        ("comment",     "Comment"),
    ]

    private func columnVisibilityBinding(for id: String) -> Binding<Bool> {
        Binding(
            get: { !hiddenColumns.contains(id) },
            set: { isVisible in
                if isVisible { hiddenColumns.remove(id) }
                else { hiddenColumns.insert(id) }
            }
        )
    }

    // MARK: - Image / PDF Export

    /// Build the export view: same chromed table, but always in briefing
    /// mode and forced to light color scheme so screenshots/PDFs look
    /// consistent regardless of the device's appearance.
    private var exportView: some View {
        makeTableContent(includeLink: true, isExport: true)
            .environment(\.briefingMode, true)
            .environment(\.exportBorderWidth, CrewTableStyle.exportBorderWidth)
            .environment(\.colorScheme, .light)
    }

    private var imageExportView: some View {
        makeTableContent(includeLink: false)
            .environment(\.briefingMode, true)
            .environment(\.exportBorderWidth, CrewTableStyle.exportBorderWidth)
            .environment(\.colorScheme, .light)
    }

    @MainActor
    private func shareAsImage() {
        let renderer = ImageRenderer(content: imageExportView)
        renderer.scale = 3.0 // retina+ for crisp screenshots
        guard let uiImage = renderer.uiImage,
              let data = uiImage.pngData() else { return }
        let filename = "Positions EK\(trip.flightInfo.flightNumber).png"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? data.write(to: url)
        shareURL = ShareableURL(url: url)
    }

    @MainActor
    private func shareAsPDF() {
        let renderer = ImageRenderer(content: exportView)
        let filename = "Positions EK\(trip.flightInfo.flightNumber).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        renderer.render { size, renderToContext in
            var box = CGRect(origin: .zero, size: size)
            guard let pdf = CGContext(url as CFURL, mediaBox: &box, nil) else { return }
            pdf.beginPDFPage(nil)
            renderToContext(pdf)
            pdf.endPDFPage()
            pdf.closePDF()
        }

        shareURL = ShareableURL(url: url)
    }

    // MARK: - Toolbar

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack(spacing: 0) {
            // Tools (scrollable)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 1) {
                    // Columns toggle
                    Menu {
                        Button {
                            withAnimation { hiddenColumns.removeAll() }
                        } label: {
                            Label("Show All", systemImage: "eye")
                        }
                        .disabled(hiddenColumns.isEmpty)

                        Divider()

                        ForEach(Self.toggleableColumns, id: \.id) { col in
                            Toggle(col.title, isOn: columnVisibilityBinding(for: col.id))
                        }
                    } label: {
                        actionBarItem(
                            icon: hiddenColumns.isEmpty ? "rectangle.3.group" : "rectangle.3.group.fill",
                            label: "Columns"
                        )
                    }

                    // Notes
                    actionBarButton(
                        icon: tripNotes.isEmpty ? "note.text" : "note.text.badge.plus",
                        label: "Notes",
                        isActive: !tripNotes.isEmpty
                    ) {
                        showNotesPopover.toggle()
                    }
                    .popover(isPresented: $showNotesPopover) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Trip Notes")
                                .font(.headline)
                            TextEditor(text: $tripNotes)
                                .frame(width: 300, height: 200)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                            Text("Notes are saved automatically with the trip.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                    }

                    if doPositions {
                        Divider()
                            .frame(height: 30)
                            .padding(.horizontal, 4)

                        // Position Editor
                        actionBarButton(
                            icon: "square.grid.3x3",
                            label: "Positions",
                            isActive: showPositionEditor
                        ) {
                            showPositionEditor.toggle()
                        }
                    }

                    Divider()
                        .frame(height: 30)
                        .padding(.horizontal, 4)

                    // SUPY toggle (works when any position cell of a crew member is focused)
                    supyToolbarButton

                    Divider()
                        .frame(height: 30)
                        .padding(.horizontal, 4)

                    // Allocated badge buttons (active only when a position cell is focused)
                    badgeToolbarButtons
                }
            }

            Spacer()

            // Right-aligned: Send Email, Override, Info and Briefing
            HStack(spacing: 1) {
                actionBarButton(
                    icon: "envelope",
                    label: "Send Email"
                ) {
                    sendCrewEmail()
                }

                Divider()
                    .frame(height: 30)
                    .padding(.horizontal, 4)

                // Override mode
                actionBarButton(
                    icon: overrideMode ? "pencil.circle.fill" : "pencil.circle",
                    label: "Override",
                    isActive: overrideMode
                ) {
                    withAnimation { overrideMode.toggle() }
                }

                Divider()
                    .frame(height: 30)
                    .padding(.horizontal, 4)

                actionBarButton(
                    icon: showFlightInfo ? "info.circle.fill" : "info.circle",
                    label: "Info",
                    isActive: showFlightInfo
                ) {
                    showFlightInfo.toggle()
                }

                actionBarButton(
                    icon: briefingMode ? "doc.text.fill" : "doc.text",
                    label: "Briefing",
                    isActive: briefingMode
                ) {
                    briefingMode.toggle()
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
        .overlay(alignment: .bottom) { Divider() }
    }

    /// Whether a position cell is currently focused for badge allocation.
    private var hasBadgeTarget: Bool {
        activeCrewIndex != nil && activeSector != nil
    }

    /// SUPY toggle button — works when any crew member's position cell is focused.
    private var supyToolbarButton: some View {
        let hasTarget = activeCrewIndex != nil
        let isActive: Bool = {
            guard let ci = activeCrewIndex else { return false }
            return crewMembers[ci].isSupy
        }()

        return Button {
            guard let ci = activeCrewIndex else { return }
            crewMembers[ci].isSupy.toggle()
            if crewMembers[ci].isSupy {
                crewMembers[ci].positions = [:]
                crewMembers[ci].breaks = [:]
                crewMembers[ci].allocatedBadges = [:]
            }
        } label: {
            Text("SUPY")
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(AllocatedBadgeIcon.color(for: AllocatedBadgeCodes.SUPY))
                        .opacity(hasTarget ? (isActive ? 0.35 : 1.0) : 0.15)
                )
        }
        .buttonStyle(.plain)
        .disabled(!hasTarget)
    }

    /// The badge toggle buttons shown in the action bar.
    private var badgeToolbarButtons: some View {
        let badges: [(String, Int)] = [
            ("W", AllocatedBadgeCodes.W),
            ("IR", AllocatedBadgeCodes.IR),
            ("MFP", AllocatedBadgeCodes.MFP),
            ("PA", AllocatedBadgeCodes.PA),
            ("UD", AllocatedBadgeCodes.UD),
        ]
        return HStack(spacing: 10) {
            ForEach(badges, id: \.1) { name, code in
                let isActive: Bool = {
                    guard let ci = activeCrewIndex, let s = activeSector else { return false }
                    return crewMembers[ci].allocatedBadges[s]?.contains(code) == true
                }()

                Button {
                    toggleAllocatedBadge(code)
                } label: {
                    Text(name)
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(AllocatedBadgeIcon.color(for: code))
                                .opacity(hasBadgeTarget ? (isActive ? 0.35 : 1.0) : 0.15)
                        )
                }
                .buttonStyle(.plain)
                .disabled(!hasBadgeTarget)
            }
        }
    }

    /// Toggle an allocated badge on the currently active position cell.
    private func toggleAllocatedBadge(_ code: Int) {
        guard let ci = activeCrewIndex, let s = activeSector else { return }
        var current = crewMembers[ci].allocatedBadges[s] ?? []
        if current.contains(code) {
            current.removeAll { $0 == code }
        } else {
            current.append(code)
        }
        crewMembers[ci].allocatedBadges[s] = current.isEmpty ? nil : current
    }

    private func actionBarButton(
        icon: String,
        label: String,
        isActive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            actionBarItem(icon: icon, label: label, isActive: isActive)
        }
        .buttonStyle(.plain)
    }

    private func actionBarItem(icon: String, label: String, isActive: Bool = false) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .lineLimit(1)
        }
        .foregroundStyle(isActive ? Color.accentColor : .primary)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarLeading) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    zoomScale = max(zoomScale - 0.25, 0.15)
                }
            } label: {
                Image(systemName: "minus.magnifyingglass")
                    .font(.system(size: 20))
            }

            Button {
                zoomScale = min(zoomScale + 0.25, 4.0)
            } label: {
                Image(systemName: "plus.magnifyingglass")
                    .font(.system(size: 20))
            }

            Button {
                zoomScale = fitZoomScale
            } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 20))
            }
        }

        ToolbarItemGroup(placement: .topBarTrailing) {
            if doPositions {
                Button {
                    regenerate()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                        Text("Regenerate")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .buttonBorderShape(.roundedRectangle)
            }

            Button {
                saveTrip()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: showSavedFeedback ? "checkmark" : (isSaved ? "checkmark.circle.fill" : "square.and.arrow.down"))
                    Text(showSavedFeedback ? "Saved" : (isSaved ? "Saved" : "Save"))
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(isSaved ? Color.blue.opacity(0.7) : .blue)
            .buttonBorderShape(.roundedRectangle)

            Menu {
                Button {
                    shareAsPDF()
                } label: {
                    Label("Share as PDF", systemImage: "doc.richtext")
                }

                Button {
                    shareAsImage()
                } label: {
                    Label("Share as Image", systemImage: "photo")
                }

            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 20))
            }
        }
    }

    // MARK: - Actions

    private func runAllocation() {
        hasBreaks = trip.flightInfo.hasBreaks

        // Preserve SUPY staff numbers so the flag survives regeneration
        let supyStaffNumbers = Set(crewMembers.filter(\.isSupy).map(\.staffNumber))

        var members = trip.crewMembers
        CrewLoader.checkBirthdays(&members, flightDate: trip.flightInfo.flightDate, durations: trip.flightInfo.durations)

        // Restore SUPY flags from previous state
        for i in members.indices where supyStaffNumbers.contains(members[i].staffNumber) {
            members[i].isSupy = true
        }

        // Separate SUPY crew — they observe only, no positions
        let supyCrew = members.filter(\.isSupy)
        let activeCrew = members.filter { !$0.isSupy }

        if doPositions, let registration = trip.registration {
            let result = AllocationEngine.allocate(
                crewData: activeCrew,
                registration: registration,
                isULR: trip.flightInfo.isULR,
                numberOfDuties: trip.flightInfo.sectors,
                hasBreaks: hasBreaks,
                selectedFacility: trip.flightInfo.selectedFacility
            )
            var allocated = result.crewMembers

            // Auto-add IR badge to position cells for crew doing DF
            for i in allocated.indices where allocated[i].doingDF {
                for sector in 0..<trip.flightInfo.sectors {
                    var badges = allocated[i].allocatedBadges[sector] ?? []
                    if !badges.contains(AllocatedBadgeCodes.IR) {
                        badges.append(AllocatedBadgeCodes.IR)
                    }
                    allocated[i].allocatedBadges[sector] = badges
                }
            }

            // Merge SUPY crew back and sort by original index
            allocated.append(contentsOf: supyCrew)
            crewMembers = allocated.sorted { $0.index < $1.index }
            allocationErrors = result.errors
        } else {
            crewMembers = members.sorted { $0.index < $1.index }
            allocationErrors = []
        }

        colWidths = ColumnWidths.compute(
            from: crewMembers,
            sectors: trip.flightInfo.sectors,
            hasBreaks: hasBreaks
        )
    }

    private func regenerate() {
        let manualCrew = crewMembers.filter { $0.isManualOverride }
        runAllocation()
        crewMembers.append(contentsOf: manualCrew)
    }

    private func checkIfSaved() {
        let key = trip.key
        var descriptor = FetchDescriptor<SavedTrip>(
            predicate: #Predicate { $0.tripKey == key }
        )
        descriptor.fetchLimit = 1
        if let existing = try? modelContext.fetch(descriptor).first {
            isSaved = true
            tripNotes = existing.notes
        }
    }

    private func saveTrip() {
        // Build an updated ParsedTrip with current crew state
        var updatedTrip = trip
        updatedTrip.crewMembers = crewMembers

        let storage = TripStorageService(modelContext: modelContext)
        do {
            let saved = try storage.save(updatedTrip)
            saved.notes = tripNotes
            try modelContext.save()
            isSaved = true
            showSavedFeedback = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showSavedFeedback = false
            }
        } catch {
            print("Failed to save trip: \(error)")
        }
    }

    // MARK: - Override Helpers

    private func handleOverrideSave(mode: CrewOverrideMode, member: CrewMember) {
        switch mode {
        case .add:
            addManualCrew(member)
        case .edit(_, let index):
            applyCrewOverride(member, at: index)
        }
    }

    private func addManualCrew(_ member: CrewMember) {
        var newMember = member
        newMember.isManualOverride = true

        // Find all indices of crew in the same grade section
        let sectionIndices = crewMembers.indices.filter { crewMembers[$0].grade == member.grade }

        if sectionIndices.isEmpty {
            // No existing crew of this grade — append
            newMember.index = member.grade.indexModifier + 99
            crewMembers.append(newMember)
        } else {
            // Assign index that keeps staff number ordering within the section
            // Find insertion point: after the last member whose staffNumber sorts before this one
            let insertAfter = sectionIndices.last { crewMembers[$0].staffNumber < newMember.staffNumber }
            let insertAt: Int
            if let after = insertAfter {
                newMember.index = crewMembers[after].index + 1
                insertAt = after + 1
            } else {
                // New member sorts before all existing — insert at section start
                newMember.index = crewMembers[sectionIndices.first!].index
                insertAt = sectionIndices.first!
            }
            crewMembers.insert(newMember, at: insertAt)
        }
    }

    private func applyCrewOverride(_ updated: CrewMember, at index: Int) {
        guard crewMembers.indices.contains(index) else { return }
        var member = updated
        member.isManualOverride = true
        crewMembers[index] = member
    }

    private func removeCrew(at index: Int) {
        guard crewMembers.indices.contains(index) else { return }
        crewMembers.remove(at: index)
    }

    private func applyCustomPositions(_ newPositions: PositionMap) {
        // Re-run allocation with custom positions — future enhancement
        showPositionEditor = false
        regenerate()
    }

    private func sendCrewEmail() {
        let emails = crewMembers.map { "s\($0.staffNumber)@emirates.com" }
        let joined = emails.joined(separator: ",")
        UIPasteboard.general.string = emails.joined(separator: "\n")
        if let url = URL(string: "mailto:\(joined)") {
            UIApplication.shared.open(url)
        }
    }

    private func copyTable() {
        var text = ""
        for member in crewMembers {
            text += "\(member.grade.rawValue)\t\(member.nickname)\t"
            for i in 0..<trip.flightInfo.sectors {
                text += "\(member.positions[i] ?? "")\t"
                if hasBreaks.indices.contains(i) && hasBreaks[i] {
                    text += "\(member.breaks[i].map(String.init) ?? "")\t"
                }
            }
            text += "\(member.fullname)\t\(member.staffNumber)\t\(member.nationality)\t"
            text += "\(member.languages.joined(separator: ", "))\t\(member.timeInGrade)\n"
        }
        UIPasteboard.general.string = text
        copiedFeedback = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            copiedFeedback = false
        }
    }
}

// MARK: - Grade Section Header

struct GradeSectionHeader: View {
    let grade: CrewGrade
    let count: Int
    var onAddCrew: (() -> Void)? = nil
    @Environment(\.exportBorderWidth) private var borderW

    var body: some View {
        HStack(spacing: 10) {
            Text(grade.sectionName.uppercased())
                .font(.system(size: 11, weight: .heavy))
                .tracking(1.4)
                .foregroundColor(accent.text)

            Text(grade.rawValue)
                .font(.system(size: 9, weight: .bold))
                .tracking(0.8)
                .foregroundColor(accent.text)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule(style: .continuous)
                        .fill(accent.text.opacity(0.15))
                )

            Spacer()

            Text("\(count) \(count == 1 ? "crew" : "crew")")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(accent.text.opacity(0.75))

            if let onAddCrew {
                Button(action: onAddCrew) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(accent.text.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: CrewTableStyle.sectionHeaderHeight)
        .background(accent.bg)
        .overlay(alignment: .bottom) {
            Rectangle().fill(CrewTableStyle.cellBorder)
                .frame(height: borderW)
        }
    }

    private var accent: (bg: Color, text: Color) {
        switch grade {
        case .PUR, .CSV: // Seniors – Yellow
            return (Color(red: 246/255, green: 220/255, blue: 111/255),
                    Color.black)
        case .FG1: // First Class – Red
            return (Color(red: 236/255, green: 113/255, blue: 100/255),
                    Color.black)
        case .GR1: // Business Class – Blue
            return (Color(red: 92/255, green: 173/255, blue: 225/255),
                    Color.black)
        case .W: // Premium Economy – Purple
            return (Color(red: 160/255, green: 120/255, blue: 210/255),
                    Color.black)
        case .GR2: // Economy – Green
            return (Color(red: 81/255, green: 189/255, blue: 129/255),
                    Color.black)
        case .CSA: // CSA – Grey
            return (Color(red: 180/255, green: 180/255, blue: 185/255),
                    Color.black)
        }
    }
}

// MARK: - Break Summary Table

struct BreakGroupEntry {
    let breakNumber: Int
    let count: Int
    let seniors: String
    let fg1: String
    let gr1: String
    let gr2: String
}

struct BreakSummaryTable: View {
    let groups: [BreakGroupEntry]
    let totalWidth: CGFloat
    let sectorLabel: String
    var capacity: Int? = nil

    @Environment(\.exportBorderWidth) private var borderW

    private let breakColWidth: CGFloat = 90
    private let countColWidth: CGFloat = 50
    private var effectiveWidth: CGFloat { totalWidth }
    private var hasFG1: Bool { groups.contains { !$0.fg1.isEmpty } }
    private var gradeColumnCount: CGFloat { hasFG1 ? 4 : 3 }
    private var gradeColWidth: CGFloat { max((effectiveWidth - breakColWidth - countColWidth) / gradeColumnCount, 60) }

    private static let ordinalLabels = ["1st Break", "2nd Break", "3rd Break", "4th Break", "5th Break", "6th Break"]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text("Break Summary: \(sectorLabel)")
                    .font(.subheadline.bold())
                if let cap = capacity {
                    Text("Capacity: \(cap)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    summaryHeaderCell("Break", width: breakColWidth)
                    summaryHeaderCell("Crew", width: countColWidth)
                    summaryHeaderCell("Seniors", width: gradeColWidth)
                    if hasFG1 { summaryHeaderCell("FG1", width: gradeColWidth) }
                    summaryHeaderCell("GR1", width: gradeColWidth)
                    summaryHeaderCell("GR2", width: gradeColWidth)
                }
                .background(CrewTableStyle.headerBG)

                ForEach(0..<groups.count, id: \.self) { index in
                    let group = groups[index]
                    let label = group.breakNumber <= Self.ordinalLabels.count
                        ? Self.ordinalLabels[group.breakNumber - 1]
                        : "\(group.breakNumber)th Break"

                    HStack(alignment: .top, spacing: 0) {
                        Text(label)
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, CrewTableStyle.cellPadH)
                            .frame(width: breakColWidth, alignment: .center)
                            .frame(minHeight: CrewTableStyle.rowHeight)
                            .overlay(alignment: .trailing) {
                                Rectangle().fill(CrewTableStyle.cellBorder).frame(width: borderW)
                            }

                        crewCountCell(count: group.count)
                            .frame(width: countColWidth, alignment: .center)
                            .frame(minHeight: CrewTableStyle.rowHeight)
                            .overlay(alignment: .trailing) {
                                Rectangle().fill(CrewTableStyle.cellBorder).frame(width: borderW)
                            }

                        gradeCell(group.seniors)
                        if hasFG1 { gradeCell(group.fg1) }
                        gradeCell(group.gr1)
                        gradeCell(group.gr2)
                    }
                    .background(index.isMultiple(of: 2) ? CrewTableStyle.cardBG : CrewTableStyle.altRowBG)
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(CrewTableStyle.cellBorder).frame(height: borderW)
                    }
                }
            }
            .frame(width: effectiveWidth)
            .background(CrewTableStyle.cardBG)
            .border(CrewTableStyle.cardBorder, width: borderW)
        }
        .padding(.top, 12)
    }

    @ViewBuilder
    private func gradeCell(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, CrewTableStyle.cellPadH)
            .padding(.vertical, 4)
            .frame(width: gradeColWidth, alignment: .leading)
            .frame(minHeight: CrewTableStyle.rowHeight)
            .overlay(alignment: .trailing) {
                Rectangle().fill(CrewTableStyle.cellBorder).frame(width: borderW)
            }
    }

    @ViewBuilder
    private func crewCountCell(count: Int) -> some View {
        let overCapacity = capacity.map { count > $0 } ?? false
        if let cap = capacity {
            Text("\(count) / \(cap)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(overCapacity ? .red : .primary)
                .padding(.horizontal, CrewTableStyle.cellPadH)
        } else {
            Text("\(count)")
                .font(.system(size: 12, weight: .semibold))
                .padding(.horizontal, CrewTableStyle.cellPadH)
        }
    }

    @ViewBuilder
    private func summaryHeaderCell(_ title: String, width: CGFloat) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .heavy))
            .foregroundStyle(CrewTableStyle.headerText)
            .padding(.horizontal, CrewTableStyle.cellPadH)
            .padding(.vertical, 6)
            .frame(width: width, alignment: .center)
            .overlay(alignment: .trailing) {
                Rectangle().fill(CrewTableStyle.headerDivider).frame(width: borderW)
            }
            .overlay(alignment: .bottom) {
                Rectangle().fill(CrewTableStyle.cellBorder).frame(height: borderW)
            }
    }
}

// MARK: - Crew Row

struct CrewRowView: View {
    @Binding var member: CrewMember
    let crewIndex: Int
    let rowIndex: Int
    let sectionRowIndex: Int
    let sectors: Int
    let hasBreaks: [Bool]
    let hiddenColumns: Set<String>
    let settings: AppSettings?
    let allBreaks: [String: Int]
    let colWidths: ColumnWidths
    let duplicatePositions: [Int: Set<String>]
    let onPositionFocus: (Int, Int, Bool) -> Void // (crewIndex, sector, focused)
    var isManualOverride: Bool = false

    @Environment(\.exportBorderWidth) private var borderW
    @Environment(\.briefingMode) private var briefingMode
    private static let cellBorder = CrewTableStyle.cellBorder
    private static let rH = CrewTableStyle.rowHeight

    var body: some View {
        HStack(spacing: 0) {
            // Row number
            gridCell(width: colWidths.rowNum, alignment: .center) {
                Text("\(rowIndex + 1)")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.primary)
            }

            // Grade
            if !hiddenColumns.contains("grade") {
                gridCell(width: colWidths.grade, alignment: .center) {
                    Text(member.grade.rawValue)
                        .font(.caption2.bold())
                        .foregroundStyle(gradeTextColor)
                }
            }

            // Nickname
            if !hiddenColumns.contains("name") {
                gridCell(width: colWidths.name) {
                    Text(member.nickname)
                        .font(.caption)
                        .lineLimit(1)
                }
            }

            // Position and Break cells per sector
            ForEach(0..<sectors, id: \.self) { i in
                if !hiddenColumns.contains("pos\(i)") {
                    PositionCell(
                        position: positionBinding(for: i),
                        allocatedBadges: member.allocatedBadges[i] ?? [],
                        width: colWidths.positionWidth(for: i),
                        isDuplicate: {
                            let pos = (member.positions[i] ?? "")
                                .trimmingCharacters(in: .whitespaces).uppercased()
                            guard !pos.isEmpty else { return false }
                            return duplicatePositions[i]?.contains(pos) == true
                        }(),
                        onPositionChanged: {
                            autoCorrectBreak(sector: i)
                            checkRepeats(sector: i)
                        },
                        onFocusChanged: { focused in
                            onPositionFocus(crewIndex, i, focused)
                        }
                    )
                }
                if !hiddenColumns.contains("brk\(i)") && hasBreaks.indices.contains(i) && hasBreaks[i] {
                    BreakCell(breakValue: breakBinding(for: i), width: colWidths.breakCol)
                }
            }

            // Full name
            if !hiddenColumns.contains("fullName") {
                gridCell(width: colWidths.fullName) {
                    Text(member.fullname)
                        .font(.caption)
                        .lineLimit(1)
                }
            }

            // Staff number
            if !hiddenColumns.contains("staff") {
                gridCell(width: colWidths.staff, alignment: .center) {
                    Text(member.staffNumber)
                        .font(.caption.monospaced())
                }
            }

            // Flag (no right divider — merges visually with nationality)
            if !hiddenColumns.contains("flag") {
                Text(flagEmoji(member.flag))
                    .frame(width: colWidths.flag, height: Self.rH, alignment: .trailing)
            }

            // Nationality
            if !hiddenColumns.contains("nationality") {
                gridCell(width: colWidths.nationality) {
                    Text(member.nationality)
                        .font(.caption)
                        .lineLimit(1)
                }
            }

            // Languages
            if !hiddenColumns.contains("languages") {
                gridCell(width: colWidths.languages) {
                    Text(member.languages.joined(separator: ", "))
                        .font(.caption)
                        .lineLimit(1)
                }
            }

            // Time in grade
            if !hiddenColumns.contains("tig") {
                gridCell(width: colWidths.tig, alignment: .center) {
                    Text(member.timeInGrade)
                        .font(.caption)
                        .lineLimit(1)
                }
            }

            // Badges + IR rating (portal badges only — allocated badges show in position cells)
            if !hiddenColumns.contains("badges") {
                let portalBadges = member.badges.filter { !AllocatedBadgeCodes.all.contains($0) }
                gridCell(width: colWidths.badges, alignment: .center, padH: 4) {
                    HStack(spacing: 3) {
                        if member.isSupy {
                            AllocatedBadgeIcon(code: AllocatedBadgeCodes.SUPY)
                        }

                        // Inflight Retail rating (1–20; 21 = no rating)
                        if member.ratingIR <= 20 {
                            IRBadgeView(rank: member.ratingIR)
                        }

                        ForEach(portalBadges, id: \.self) { badge in
                            BadgeView(badgeCode: badge)
                        }
                    }
                }
            }

            // Destination experience
            if !hiddenColumns.contains("flown") {
                let totalFlown = member.destinationExperience.values.reduce(0, +)
                gridCell(width: colWidths.flown, alignment: .center) {
                    Text(totalFlown > 0 ? "\(totalFlown)" : "")
                        .font(.caption)
                }
            }

            // Comment
            if !hiddenColumns.contains("comment") {
                CommentCell(comment: member.comment, width: colWidths.comment)
            }
        }
        .frame(height: Self.rH)
        .background(rowBackground)
        .overlay(alignment: .leading) {
            if isManualOverride && !briefingMode {
                Rectangle()
                    .fill(Color.orange)
                    .frame(width: 3)
            }
        }
        .overlay(alignment: .bottom) {
            Rectangle().fill(Self.cellBorder)
                .frame(height: borderW)
        }
    }

    /// A single grid cell with a right-edge divider only.
    @ViewBuilder
    private func gridCell<C: View>(
        width: CGFloat,
        alignment: Alignment = .leading,
        padH: CGFloat = CrewTableStyle.cellPadH,
        @ViewBuilder content: () -> C
    ) -> some View {
        content()
            .padding(.horizontal, padH)
            .frame(width: width, height: Self.rH, alignment: alignment)
            .overlay(alignment: .trailing) {
                Rectangle().fill(Self.cellBorder)
                    .frame(width: borderW)
            }
    }

    private var rowBackground: Color {
        if isManualOverride && !briefingMode {
            return Color.orange.opacity(0.08)
        }
        return sectionRowIndex.isMultiple(of: 2)
            ? CrewTableStyle.cardBG
            : CrewTableStyle.altRowBG
    }

    private func positionBinding(for sector: Int) -> Binding<String> {
        Binding(
            get: { member.positions[sector] ?? "" },
            set: { member.positions[sector] = $0.isEmpty ? nil : $0 }
        )
    }

    private func breakBinding(for sector: Int) -> Binding<String> {
        Binding(
            get: { member.breaks[sector].map(String.init) ?? "" },
            set: { member.breaks[sector] = Int($0) }
        )
    }

    private func autoCorrectBreak(sector: Int) {
        guard settings?.breakAutoCorrection ?? true,
              let position = member.positions[sector],
              let breakGroup = allBreaks[position] else { return }
        member.breaks[sector] = breakGroup
    }

    private func checkRepeats(sector: Int) {
        // Repeat highlighting is handled at the table level
    }

    private var gradeTextColor: Color {
        .black
    }

    private func flagEmoji(_ code: String) -> String {
        let upper = code.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        // Only valid 2-letter ISO codes produce correct flag emoji
        guard upper.count == 2,
              upper.allSatisfy({ $0.isASCII && $0.isLetter }) else {
            return upper // fallback: show the code as text
        }
        let base: UInt32 = 127397
        var emoji = ""
        for scalar in upper.unicodeScalars {
            if let flag = Unicode.Scalar(base + scalar.value) {
                emoji.append(String(flag))
            }
        }
        return emoji
    }
}

// MARK: - Position Cell

struct PositionCell: View {
    @Binding var position: String
    let allocatedBadges: [Int]
    var width: CGFloat = 80
    var isDuplicate: Bool = false
    let onPositionChanged: () -> Void
    let onFocusChanged: (Bool) -> Void

    @Environment(\.briefingMode) private var briefingMode
    @Environment(\.exportBorderWidth) private var borderW
    @FocusState private var focused: Bool

    private var hasBadges: Bool { !allocatedBadges.isEmpty }
    private static let alertColor = Color(red: 255/255, green: 133/255, blue: 133/255)
    private var isAlert: Bool {
        isDuplicate || position.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        Color.clear
            .frame(width: width, height: CrewTableStyle.rowHeight)
            .overlay {
                HStack(spacing: 1) {
                    if briefingMode {
                        Text(position)
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .lineLimit(1)
                    } else {
                        TextField("", text: $position)
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: true, vertical: false)
                            .focused($focused)
                            .onChange(of: position) { _, newValue in
                                let upper = newValue.uppercased()
                                if upper != newValue { position = upper }
                            }
                            .onChange(of: focused) { _, newValue in
                                onFocusChanged(newValue)
                                if !newValue { onPositionChanged() }
                            }
                    }

                    ForEach(allocatedBadges, id: \.self) { code in
                        AllocatedBadgeIcon(code: code)
                            .fixedSize()
                    }
                }
            }
            .clipped()
            .contentShape(Rectangle())
            .simultaneousGesture(TapGesture().onEnded {
                if !briefingMode { onFocusChanged(true) }
            })
            .background(
                isAlert
                    ? Self.alertColor
                    : (briefingMode ? Color.clear : CrewTableStyle.inputBG)
            )
            .overlay(alignment: .trailing) {
                Rectangle().fill(CrewTableStyle.cellBorder)
                    .frame(width: borderW)
            }
    }
}

// MARK: - Break Cell

struct BreakCell: View {
    @Binding var breakValue: String
    var width: CGFloat = 45
    @Environment(\.briefingMode) private var briefingMode
    @Environment(\.exportBorderWidth) private var borderW

    var body: some View {
        Group {
            if briefingMode {
                Text(breakValue)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .frame(width: width, height: CrewTableStyle.rowHeight)
            } else {
                TextField("", text: $breakValue)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .frame(width: width, height: CrewTableStyle.rowHeight)
                    .background(CrewTableStyle.inputBG.opacity(0.55))
            }
        }
        .overlay(alignment: .trailing) {
            Rectangle().fill(CrewTableStyle.cellBorder)
                .frame(width: borderW)
        }
    }
}

// MARK: - Comment Cell

/// Collapses multi-line comments into a single line for inline display.
enum CommentFormatter {
    static func singleLine(_ text: String) -> String {
        text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " - ")
    }
}

/// Comment cell with tap-to-popover and hover tooltip for the full text.
/// Multi-line comments are flattened to one line (separated by " - ") in the cell;
/// the popover preserves the original multi-line formatting.
struct CommentCell: View {
    let comment: String
    let width: CGFloat
    @State private var showPopover = false
    @Environment(\.exportBorderWidth) private var borderW

    private var flattened: String { CommentFormatter.singleLine(comment) }

    var body: some View {
        Text(flattened)
            .font(.caption)
            .lineLimit(1)
            .truncationMode(.tail)
            .padding(.horizontal, CrewTableStyle.cellPadH)
            .frame(width: width, height: CrewTableStyle.rowHeight, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                guard !flattened.isEmpty else { return }
                showPopover = true
            }
            .popover(isPresented: $showPopover) {
                Text(comment)
                    .font(.callout)
                    .padding(12)
                    .frame(maxWidth: 360)
                    .presentationCompactAdaptation(.popover)
            }
            .help(comment)
            .overlay(alignment: .trailing) {
                Rectangle().fill(CrewTableStyle.cellBorder)
                    .frame(width: borderW)
            }
    }
}

// MARK: - Badge View

struct BadgeView: View {
    let badgeCode: Int

    var body: some View {
        Image(systemName: badgeIcon)
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 20, height: 20)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(badgeColor)
            )
    }

    private var badgeIcon: String {
        switch badgeCode {
        case 1: return "gift.fill"                              // Birthday
        case 170920: return "w.square.fill"                     // Premium economy (W class)
        case 24, 25: return "arrow.up.square.fill"              // PUR/CSV pool
        case 102: return "heart.fill"                           // Peer support
        case 20, 21: return "camera.fill"                       // Business promotion
        case 24514: return "arrow.counterclockwise"             // Relocated staff number
        case 12, 14, 16, 17, 18, 23, 27, 30: return "graduationcap.fill" // Part-time trainer
        default: return "star.fill"
        }
    }

    private var badgeColor: Color {
        switch badgeCode {
        case 1: return .blue                                    // Birthday – blue
        case 170920: return .purple                             // Premium economy – purple
        case 24, 25: return .black                              // PUR/CSV pool – black
        case 102: return .cyan                                  // Peer support – cyan
        case 20, 21: return .orange                             // Business promotion – orange
        case 24514: return .teal                                // Relocated – teal
        case 12, 14, 16, 17, 18, 23, 27, 30: return .init(red: 0, green: 0.5, blue: 0) // PTT – green
        default: return .gray
        }
    }
}

/// Inflight retail sales rank badge — white number in red rounded square.
struct IRBadgeView: View {
    let rank: Int

    var body: some View {
        Text("\(rank)")
            .font(.system(size: 11, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: 20, height: 20)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color(red: 0.86, green: 0.08, blue: 0.24))
            )
    }
}

// MARK: - Allocated Badge Codes & Icons

/// Badge codes that are allocatable per sector (not portal-captured).
enum AllocatedBadgeCodes {
    static let MFP = 32022
    static let W = 170920
    static let UD = -2
    static let IR = -3
    static let PA = -4

    static let SUPY = -5

    /// All allocatable badge codes.
    static let all: Set<Int> = [MFP, W, UD, IR, PA, SUPY]
}

/// Small icon for allocated badges displayed in the position cell.
struct AllocatedBadgeIcon: View {
    let code: Int

    var body: some View {
        Text(label)
            .font(.system(size: 9, weight: .heavy))
            .foregroundStyle(.white)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(badgeColor)
            )
    }

    private var label: String {
        switch code {
        case AllocatedBadgeCodes.MFP: return "MFP"
        case AllocatedBadgeCodes.W: return "W"
        case AllocatedBadgeCodes.UD: return "UD"
        case AllocatedBadgeCodes.IR: return "IR"
        case AllocatedBadgeCodes.PA: return "PA"
        case AllocatedBadgeCodes.SUPY: return "SUPY"
        default: return "?"
        }
    }

    private var badgeColor: Color {
        Self.color(for: code)
    }

    static func color(for code: Int) -> Color {
        switch code {
        case AllocatedBadgeCodes.W, AllocatedBadgeCodes.UD:
            return Color(red: 105/255, green: 26/255, blue: 171/255)
        case AllocatedBadgeCodes.PA:
            return Color(red: 0/255, green: 126/255, blue: 130/255)
        case AllocatedBadgeCodes.MFP:
            return Color(red: 41/255, green: 41/255, blue: 170/255)
        case AllocatedBadgeCodes.IR:
            return Color(red: 0.86, green: 0.08, blue: 0.24)
        case AllocatedBadgeCodes.SUPY:
            return Color(red: 0.4, green: 0.78, blue: 0.4)
        default: return .gray
        }
    }
}

// MARK: - Shareable URL wrapper

struct ShareableURL: Identifiable {
    let id = UUID()
    let url: URL
}

// MARK: - UIActivityViewController wrapper

struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Zoomable Table Viewport

struct ZoomableTableView<Content: View>: UIViewRepresentable {
    @Binding var zoomScale: CGFloat
    var fitScale: CGFloat
    @ViewBuilder var content: Content

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIView(context: Context) -> UIScrollView {
        let sv = UIScrollView()
        sv.delegate = context.coordinator
        sv.minimumZoomScale = max(0.1, fitScale)
        sv.maximumZoomScale = 4.0
        sv.bouncesZoom = false
        sv.showsHorizontalScrollIndicator = true
        sv.showsVerticalScrollIndicator = true
        sv.backgroundColor = .clear

        let host = UIHostingController(rootView: content)
        host.view.backgroundColor = .clear
        sv.addSubview(host.view)
        context.coordinator.hostedView = host.view
        context.coordinator.hostController = host

        let size = host.sizeThatFits(in: CGSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        ))
        host.view.frame = CGRect(origin: .zero, size: size)
        sv.contentSize = size
        context.coordinator.naturalContentSize = size

        let doubleTap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleDoubleTap(_:))
        )
        doubleTap.numberOfTapsRequired = 2
        sv.addGestureRecognizer(doubleTap)

        return sv
    }

    func updateUIView(_ sv: UIScrollView, context: Context) {
        context.coordinator.parent = self

        var contentSizeChanged = false
        if let host = context.coordinator.hostController {
            host.rootView = content

            let size = host.sizeThatFits(in: CGSize(
                width: CGFloat.greatestFiniteMagnitude,
                height: CGFloat.greatestFiniteMagnitude
            ))
            let old = context.coordinator.naturalContentSize
            if abs(old.width - size.width) > 1 || abs(old.height - size.height) > 1 {
                contentSizeChanged = true
                context.coordinator.naturalContentSize = size
                host.view.transform = .identity
                host.view.frame = CGRect(origin: .zero, size: size)
                sv.contentSize = size
            }
        }

        sv.minimumZoomScale = max(0.1, fitScale)

        guard !context.coordinator.isUserInteracting else { return }

        let target = max(sv.minimumZoomScale, min(zoomScale, sv.maximumZoomScale))
        if contentSizeChanged {
            sv.setZoomScale(target, animated: false)
        } else if abs(sv.zoomScale - target) > 0.01 {
            sv.setZoomScale(target, animated: true)
        }
        context.coordinator.centerContent(in: sv)
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: ZoomableTableView
        var hostedView: UIView?
        var hostController: UIHostingController<Content>?
        var isUserInteracting = false
        var naturalContentSize: CGSize = .zero

        init(parent: ZoomableTableView) { self.parent = parent }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? { hostedView }

        func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
            isUserInteracting = true
        }

        func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
            isUserInteracting = true
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            centerContent(in: scrollView)
        }

        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            if !decelerate { endInteraction(scrollView) }
        }

        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            endInteraction(scrollView)
        }

        func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
            endInteraction(scrollView)
        }

        private func endInteraction(_ scrollView: UIScrollView) {
            isUserInteracting = false
            parent.zoomScale = scrollView.zoomScale
        }

        func centerContent(in scrollView: UIScrollView) {
            guard hostedView != nil else { return }
            let boundsSize = scrollView.bounds.size
            let scaledSize = CGSize(
                width: naturalContentSize.width * scrollView.zoomScale,
                height: naturalContentSize.height * scrollView.zoomScale
            )
            let xOffset = max(0, (boundsSize.width - scaledSize.width) / 2)
            let yOffset = max(0, (boundsSize.height - scaledSize.height) / 2)
            scrollView.contentInset = UIEdgeInsets(
                top: yOffset, left: xOffset, bottom: yOffset, right: xOffset
            )
        }

        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            guard let sv = gesture.view as? UIScrollView else { return }
            let target = parent.fitScale
            sv.setZoomScale(target, animated: true)
            parent.zoomScale = target
        }
    }
}

