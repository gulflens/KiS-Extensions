import SwiftUI
import SwiftData

// MARK: - Saved Positions Tab View

/// Shows crew positions for a single sector inside the Flight Planner.
/// On first load, matches the PlannedSector's route against the SavedTrip's
/// flight legs to find the correct sector index, extracts per-crew positions
/// and breaks for that index, and caches the snapshot in the PlannedSector.
struct SavedPositionsTabView: View {
    let sector: PlannedSector
    let flightNumber: String
    let flightDate: Date

    @Environment(\.modelContext) private var modelContext
    @State private var positions: [SectorCrewPosition] = []
    @State private var loaded = false
    @State private var zoomScale: CGFloat = 1.0
    @State private var availableSize: CGSize = .zero

    var body: some View {
        Group {
            if !positions.isEmpty {
                positionsTable
            } else if loaded {
                emptyState
            } else {
                ProgressView()
            }
        }
        .onAppear {
            loadPositions()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "person.2.slash")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No saved positions")
                .font(.title3.bold())

            Text("Import this flight in Allocate Positions to see crew positions here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)

            Spacer()
        }
    }

    // MARK: - Positions Table

    private static let titleDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd MMM yyyy"
        return f
    }()

    private var fitZoomScale: CGFloat {
        guard availableSize.width > 0, availableSize.height > 0 else { return 1.0 }
        let contentW = tableWidth + 24
        guard contentW > 0 else { return 1.0 }
        return min(availableSize.width / contentW, 1.5)
    }

    private var positionsTable: some View {
        VStack(spacing: 0) {
            toolbar

            GeometryReader { geo in
                ZoomableTableView(zoomScale: $zoomScale, fitScale: fitZoomScale) {
                    tableContentView
                        .fixedSize()
                }
                .background(Color(.systemGray5))
                .onAppear {
                    availableSize = geo.size
                    DispatchQueue.main.async {
                        zoomScale = fitZoomScale
                    }
                }
                .onChange(of: geo.size) { _, newSize in
                    availableSize = newSize
                    DispatchQueue.main.async {
                        zoomScale = fitZoomScale
                    }
                }
            }
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: 0) {
            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    zoomScale = max(zoomScale - 0.25, 0.15)
                }
            } label: {
                Image(systemName: "minus.magnifyingglass")
                    .font(.system(size: 20))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.plain)

            Button {
                zoomScale = min(zoomScale + 0.25, 4.0)
            } label: {
                Image(systemName: "plus.magnifyingglass")
                    .font(.system(size: 20))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.plain)

            Button {
                zoomScale = fitZoomScale
            } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 20))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
        .overlay(alignment: .bottom) { Divider() }
    }

    // MARK: - Table Content

    private var tableContentView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text("EK \(flightNumber)")
                    .font(.subheadline.bold())
                Text("|")
                    .font(.subheadline.bold())
                    .foregroundStyle(.red)
                Text("\(sector.departureStation) \u{2013} \(sector.arrivalStation)")
                    .font(.subheadline.bold().monospaced())
                Text("|")
                    .font(.subheadline.bold())
                    .foregroundStyle(.red)
                Text(Self.titleDateFormatter.string(from: flightDate))
                    .font(.subheadline.bold())
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.bottom, 4)

            VStack(alignment: .leading, spacing: 0) {
                headerRow
                crewRows
            }
            .background(CrewTableStyle.cardBG)
            .border(CrewTableStyle.cardBorder, width: CrewTableStyle.cellBorderWidth)

            if !breakGroups.isEmpty {
                BreakSummaryTable(
                    groups: breakGroups,
                    totalWidth: tableWidth,
                    sectorLabel: "\(sector.departureStation) - \(sector.arrivalStation)"
                )
            }
        }
        .padding(12)
    }

    // MARK: - Table Width

    private var tableWidth: CGFloat {
        let w = colWidths
        var total = w.rowNum + w.fullName + w.staff + w.position + w.docs + w.notes
        if hasBreaks { total += w.breakCol }
        return total
    }

    // MARK: - Break Groups

    private var breakGroups: [BreakGroupEntry] {
        struct MemberInfo {
            let nickname: String
            let grade: String
        }
        var grouped: [Int: [MemberInfo]] = [:]
        for crew in positions {
            guard crew.breakGroup > 0 else { continue }
            grouped[crew.breakGroup, default: []].append(MemberInfo(nickname: crew.nickname, grade: crew.grade))
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

    // MARK: - Column Widths

    private var colWidths: ReadOnlyColumnWidths {
        ReadOnlyColumnWidths.compute(from: positions)
    }

    // MARK: - Header Row

    private let hasBreaks: Bool = true

    private var headerRow: some View {
        HStack(spacing: 0) {
            readOnlyHeaderCell("N.", width: colWidths.rowNum)
            readOnlyHeaderCell("Full name", width: colWidths.fullName)
            readOnlyHeaderCell("Staff number", width: colWidths.staff)
            readOnlyHeaderCell("Position", width: colWidths.position)
            if hasBreaks {
                readOnlyHeaderCell("Break", width: colWidths.breakCol)
            }
            readOnlyHeaderCell("Docs", width: colWidths.docs)
            readOnlyHeaderCell("Notes / observations", width: colWidths.notes)
        }
        .background(CrewTableStyle.headerBG)
    }

    @ViewBuilder
    private func readOnlyHeaderCell(_ title: String, width: CGFloat) -> some View {
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
                    .frame(width: CrewTableStyle.cellBorderWidth)
            }
            .overlay(alignment: .bottom) {
                Rectangle().fill(CrewTableStyle.cellBorder)
                    .frame(height: CrewTableStyle.cellBorderWidth)
            }
    }

    // MARK: - Crew Rows

    private var gradeGroups: [(String, [IndexedPosition])] {
        let order = ["PUR", "CSV", "FG1", "GR1", "W", "GR2", "CSA"]
        var grouped: [String: [IndexedPosition]] = [:]
        for (i, crew) in positions.enumerated() {
            grouped[crew.grade, default: []].append(IndexedPosition(index: i, crew: crew))
        }
        return order.compactMap { grade in
            guard let items = grouped[grade], !items.isEmpty else { return nil }
            return (grade, items)
        }
    }

    private var crewRows: some View {
        let groups = gradeGroups

        return ForEach(Array(groups.enumerated()), id: \.offset) { _, group in
            let (grade, items) = group

            sectionHeader(grade: grade, count: items.count)

            ForEach(Array(items.enumerated()), id: \.element.index) { sectionIdx, item in
                crewRow(
                    positionIndex: item.index,
                    crew: item.crew,
                    rowNumber: item.index + 1,
                    sectionRowIndex: sectionIdx
                )
            }
        }
    }

    // MARK: - Section Header

    @ViewBuilder
    private func sectionHeader(grade: String, count: Int) -> some View {
        let accent = gradeAccent(grade)
        HStack(spacing: 10) {
            Text(gradeSectionName(grade).uppercased())
                .font(.system(size: 11, weight: .heavy))
                .tracking(1.4)
                .foregroundColor(accent.text)

            Text(grade)
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

            Text("\(count) crew")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(accent.text.opacity(0.75))
        }
        .padding(.horizontal, 14)
        .frame(height: CrewTableStyle.sectionHeaderHeight)
        .background(accent.bg)
        .overlay(alignment: .bottom) {
            Rectangle().fill(CrewTableStyle.cellBorder)
                .frame(height: CrewTableStyle.cellBorderWidth)
        }
    }

    // MARK: - Crew Row

    @ViewBuilder
    private func crewRow(positionIndex: Int, crew: SectorCrewPosition, rowNumber: Int, sectionRowIndex: Int) -> some View {
        HStack(spacing: 0) {
            readOnlyCell(width: colWidths.rowNum, alignment: .center) {
                Text("\(rowNumber)")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
            }

            readOnlyCell(width: colWidths.fullName) {
                Text(crew.fullname)
                    .font(.caption)
                    .lineLimit(1)
            }

            readOnlyCell(width: colWidths.staff, alignment: .center) {
                Text(crew.staffNumber)
                    .font(.caption.monospaced())
            }

            readOnlyCell(width: colWidths.position, alignment: .center) {
                HStack(spacing: 1) {
                    Text(crew.position)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .lineLimit(1)

                    ForEach(crew.allocatedBadges, id: \.self) { code in
                        AllocatedBadgeIcon(code: code)
                            .fixedSize()
                    }
                }
            }

            if hasBreaks {
                readOnlyCell(width: colWidths.breakCol, alignment: .center) {
                    Text(crew.breakGroup > 0 ? "\(crew.breakGroup)" : "")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                }
            }

            readOnlyCell(width: colWidths.docs, alignment: .center) {
                Button {
                    positions[positionIndex].documentsChecked.toggle()
                    savePositions()
                } label: {
                    Image(systemName: positions[positionIndex].documentsChecked ? "checkmark.square.fill" : "square")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(positions[positionIndex].documentsChecked ? Color.green : Color(.systemGray3))
                }
                .buttonStyle(.plain)
            }

            readOnlyCell(width: colWidths.notes) {
                NotesField(
                    text: crew.notes,
                    onCommit: { newValue in
                        positions[positionIndex].notes = newValue
                        savePositions()
                    }
                )
            }
        }
        .frame(height: CrewTableStyle.rowHeight)
        .background(sectionRowIndex.isMultiple(of: 2) ? CrewTableStyle.cardBG : CrewTableStyle.altRowBG)
        .overlay(alignment: .bottom) {
            Rectangle().fill(CrewTableStyle.cellBorder)
                .frame(height: CrewTableStyle.cellBorderWidth)
        }
    }

    @ViewBuilder
    private func readOnlyCell<C: View>(
        width: CGFloat,
        alignment: Alignment = .leading,
        @ViewBuilder content: () -> C
    ) -> some View {
        content()
            .padding(.horizontal, CrewTableStyle.cellPadH)
            .frame(width: width, height: CrewTableStyle.rowHeight, alignment: alignment)
            .overlay(alignment: .trailing) {
                Rectangle().fill(CrewTableStyle.cellBorder)
                    .frame(width: CrewTableStyle.cellBorderWidth)
            }
    }

    // MARK: - Grade Helpers

    private func gradeAccent(_ grade: String) -> (bg: Color, text: Color) {
        switch grade {
        case "PUR", "CSV":
            return (Color(red: 246/255, green: 220/255, blue: 111/255), .black)
        case "FG1":
            return (Color(red: 236/255, green: 113/255, blue: 100/255), .black)
        case "GR1":
            return (Color(red: 92/255, green: 173/255, blue: 225/255), .black)
        case "W":
            return (Color(red: 160/255, green: 120/255, blue: 210/255), .black)
        case "GR2":
            return (Color(red: 81/255, green: 189/255, blue: 129/255), .black)
        case "CSA":
            return (Color(red: 180/255, green: 180/255, blue: 185/255), .black)
        default:
            return (Color(.systemGray4), .black)
        }
    }

    private func gradeSectionName(_ grade: String) -> String {
        switch grade {
        case "PUR": "Purser"
        case "CSV": "Cabin Supervisor"
        case "FG1": "First Class"
        case "GR1": "Business Class"
        case "W": "Premium Economy"
        case "GR2": "Economy"
        case "CSA": "Cabin Service Attendant"
        default: grade
        }
    }

    private func flagEmoji(_ code: String) -> String {
        let upper = code.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard upper.count == 2, upper.allSatisfy({ $0.isASCII && $0.isLetter }) else {
            return upper
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

    // MARK: - Save Positions

    private func savePositions() {
        sector.crewPositionsJSON = try? JSONEncoder().encode(positions)
        try? modelContext.save()
    }


    // MARK: - Load Positions

    private func loadPositions() {
        if let data = sector.crewPositionsJSON,
           let cached = try? JSONDecoder().decode([SectorCrewPosition].self, from: data) {
            positions = cached
            loaded = true
            return
        }

        guard let trip = fetchMatchingTrip() else {
            loaded = true
            return
        }

        let sectorIndex = matchSectorIndex(in: trip)
        let extracted = extractPositions(from: trip, sectorIndex: sectorIndex)

        if !extracted.isEmpty {
            positions = extracted
            sector.crewPositionsJSON = try? JSONEncoder().encode(extracted)
            try? modelContext.save()
        }

        loaded = true
    }

    // MARK: - Trip Matching

    private func fetchMatchingTrip() -> SavedTrip? {
        let number = flightNumber
            .replacingOccurrences(of: "EK", with: "")
            .replacingOccurrences(of: "ek", with: "")
            .trimmingCharacters(in: .whitespaces)

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: flightDate)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return nil
        }

        var descriptor = FetchDescriptor<SavedTrip>(
            predicate: #Predicate<SavedTrip> { trip in
                trip.flightNumber == number &&
                trip.flightDate >= startOfDay &&
                trip.flightDate < endOfDay
            }
        )
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }

    // MARK: - Sector Index Matching

    private func matchSectorIndex(in trip: SavedTrip) -> Int {
        var legs = trip.flightLegs
        let dep = sector.departureStation
        let arr = sector.arrivalStation

        // Portal scraper omits the final DXB — append it if needed
        if legs.last != "DXB" {
            legs.append("DXB")
        }

        for i in 0 ..< (legs.count - 1) {
            if legs[i] == dep && legs[i + 1] == arr {
                return i
            }
        }

        return sector.sectorIndex
    }

    // MARK: - Extract Positions

    private func extractPositions(from trip: SavedTrip, sectorIndex: Int) -> [SectorCrewPosition] {
        let decoder = JSONDecoder()

        return trip.crewAllocations
            .sorted { $0.index < $1.index }
            .compactMap { alloc -> SectorCrewPosition? in
                let positionsDict = (try? decoder.decode([Int: String].self, from: alloc.positionsJSON)) ?? [:]
                let breaksDict = (try? decoder.decode([Int: Int].self, from: alloc.breaksJSON)) ?? [:]
                let badgesDict = (try? decoder.decode([Int: [Int]].self, from: alloc.allocatedBadgesJSON)) ?? [:]

                let position = positionsDict[sectorIndex] ?? ""
                let breakGroup = breaksDict[sectorIndex] ?? 0
                let badges = badgesDict[sectorIndex] ?? []

                return SectorCrewPosition(
                    staffNumber: alloc.staffNumber,
                    nickname: alloc.nickname,
                    fullname: alloc.fullname,
                    grade: alloc.gradeRaw,
                    flag: alloc.flag,
                    nationality: alloc.nationality,
                    position: position,
                    breakGroup: breakGroup,
                    allocatedBadges: badges
                )
            }
    }
}

// MARK: - Indexed Position Helper

private struct IndexedPosition {
    let index: Int
    let crew: SectorCrewPosition
}

// MARK: - Notes Field

private struct NotesField: View {
    let text: String
    let onCommit: (String) -> Void

    @State private var localText: String = ""
    @State private var showFullText = false
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 4) {
            TextField("", text: $localText)
                .font(.system(size: 11))
                .textFieldStyle(.plain)
                .lineLimit(1)
                .truncationMode(.tail)
                .focused($isFocused)
                .onAppear { localText = text }
                .onChange(of: isFocused) { _, focused in
                    if !focused && localText != text {
                        onCommit(localText)
                    }
                }
                .onSubmit {
                    if localText != text {
                        onCommit(localText)
                    }
                }

            if !localText.isEmpty {
                Button {
                    showFullText = true
                } label: {
                    Image(systemName: "text.bubble")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showFullText) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(localText)
                            .font(.system(size: 13))
                            .frame(maxWidth: 320, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)

                        Button {
                            UIPasteboard.general.string = localText
                            showFullText = false
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .buttonStyle(.bordered)
                        .tint(.accentColor)
                    }
                    .padding(12)
                    .presentationCompactAdaptation(.popover)
                }
            }
        }
    }
}

// MARK: - Read-Only Column Widths

private struct ReadOnlyColumnWidths {
    var rowNum: CGFloat
    var grade: CGFloat
    var name: CGFloat
    var position: CGFloat
    var breakCol: CGFloat
    var docs: CGFloat
    var fullName: CGFloat
    var staff: CGFloat
    var flag: CGFloat
    var nationality: CGFloat
    var notes: CGFloat

    private static let pad: CGFloat = CrewTableStyle.cellPadH * 2

    private static func measure(_ text: String, font: UIFont) -> CGFloat {
        let size = (text as NSString).size(withAttributes: [.font: font])
        return ceil(size.width) + pad
    }

    static func compute(from crew: [SectorCrewPosition]) -> ReadOnlyColumnWidths {
        let caption = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize)
        let captionBold = UIFont.boldSystemFont(ofSize: UIFont.smallSystemFontSize - 1)
        let mono = UIFont.monospacedSystemFont(ofSize: 12, weight: .semibold)
        let monoSmall = UIFont.monospacedSystemFont(ofSize: 11, weight: .semibold)
        let hFont = UIFont.systemFont(ofSize: 10, weight: .bold)
        let badgeFont = UIFont.systemFont(ofSize: 9, weight: .heavy)

        let rowNum = max(measure("N.", font: hFont), measure("\(crew.count)", font: caption)) + 8
        var grade = measure("Grade", font: hFont)
        var name = measure("Nickname", font: hFont) + 22
        var position = measure("Position", font: hFont)
        var breakCol = measure("Break", font: hFont)
        let docs: CGFloat = 44
        var fullName = measure("Full name", font: hFont)
        var staff = measure("Staff number", font: hFont)
        let flag: CGFloat = 22
        var nationality = measure("Nationality", font: hFont)
        let notes: CGFloat = 400

        for m in crew {
            grade = max(grade, measure(m.grade, font: captionBold))
            name = max(name, measure(m.nickname, font: caption) + 22)
            fullName = max(fullName, measure(m.fullname, font: caption))
            staff = max(staff, measure(m.staffNumber, font: UIFont.monospacedSystemFont(ofSize: UIFont.smallSystemFontSize, weight: .regular)))
            nationality = max(nationality, measure(m.nationality, font: caption))

            let posW = m.position.isEmpty ? 0 : measure(m.position, font: mono)
            var badgesW: CGFloat = 0
            for code in m.allocatedBadges {
                let label: String
                switch code {
                case AllocatedBadgeCodes.MFP: label = "MFP"
                case AllocatedBadgeCodes.W: label = "W"
                case AllocatedBadgeCodes.UD: label = "UD"
                case AllocatedBadgeCodes.IR: label = "IR"
                case AllocatedBadgeCodes.PA: label = "PA"
                default: label = "?"
                }
                badgesW += measure(label, font: badgeFont) + 4
            }
            position = max(position, posW + badgesW)

            if m.breakGroup > 0 {
                breakCol = max(breakCol, measure("\(m.breakGroup)", font: monoSmall))
            }
        }

        position += 8

        return ReadOnlyColumnWidths(
            rowNum: rowNum, grade: grade, name: name, position: position,
            breakCol: breakCol, docs: docs, fullName: fullName, staff: staff,
            flag: flag, nationality: nationality, notes: notes
        )
    }
}
