import SwiftUI

struct PositionEditorView: View {
    let trip: ParsedTrip
    let onApply: (PositionMap) -> Void
    let onClose: () -> Void

    @State private var positionMap: PositionMap = [:]
    @State private var draggedPosition: DragItem?

    struct DragItem: Equatable {
        let grade: String
        let slot: String // "galley", "df", "remain", "only"
        let position: String
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Positions")
                    .font(.headline)
                Spacer()
                Button("Apply") {
                    onApply(positionMap)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                Button("Close") {
                    onClose()
                }
                .controlSize(.small)
            }
            .padding()
            .background(Color(.systemGray6))

            Text("Drag positions between slots to rearrange")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                .padding(.top, 4)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(gradeOrder, id: \.self) { grade in
                        if let gp = positionMap[grade], !gp.allPositions.isEmpty {
                            gradeSection(grade: grade, positions: gp)
                        }
                    }
                }
                .padding()
            }
        }
        .onAppear { loadPositions() }
    }

    private let gradeOrder = ["PUR", "CSV", "FG1", "GR1", "W", "GR2", "CSA", "EXTRA"]

    @ViewBuilder
    private func gradeSection(grade: String, positions: GradePositions) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(grade)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(gradeColor(grade))
                .cornerRadius(4)

            if ["PUR", "CSV", "CSA", "EXTRA"].contains(grade) {
                slotRow(grade: grade, slotName: "only", label: "Positions", positions: positions.only)
            } else {
                slotRow(grade: grade, slotName: "galley", label: "Galley", positions: positions.galley)
                slotRow(grade: grade, slotName: "df", label: "Retail", positions: positions.df)
                slotRow(grade: grade, slotName: "remain", label: "Other", positions: positions.remain)
            }
        }
    }

    @ViewBuilder
    private func slotRow(grade: String, slotName: String, label: String, positions: [String]) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)

            FlowLayout(spacing: 4) {
                ForEach(positions, id: \.self) { position in
                    positionChip(position, grade: grade, slot: slotName)
                }
            }
            .padding(6)
            .frame(minHeight: 30)
            .background(Color(.systemGray6).opacity(0.5))
            .cornerRadius(6)
            .dropDestination(for: String.self) { items, _ in
                guard let pos = items.first, let drag = draggedPosition else { return false }
                movePosition(from: drag, toGrade: grade, toSlot: slotName, position: pos)
                return true
            }
        }
    }

    private func positionChip(_ position: String, grade: String, slot: String) -> some View {
        Text(position)
            .font(.caption.monospaced())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(gradeColor(grade).opacity(0.2))
            .cornerRadius(4)
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(gradeColor(grade), lineWidth: 1))
            .draggable(position) {
                Text(position)
                    .font(.caption.monospaced())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(gradeColor(grade))
                    .foregroundStyle(.white)
                    .cornerRadius(4)
                    .onAppear {
                        draggedPosition = DragItem(grade: grade, slot: slot, position: position)
                    }
            }
    }

    private func movePosition(from source: DragItem, toGrade: String, toSlot: String, position: String) {
        // Remove from source
        removeFromSlot(grade: source.grade, slot: source.slot, position: source.position)
        // Add to destination
        addToSlot(grade: toGrade, slot: toSlot, position: position)
        draggedPosition = nil
    }

    private func removeFromSlot(grade: String, slot: String, position: String) {
        guard var gp = positionMap[grade] else { return }
        switch slot {
        case "galley": gp.galley.removeAll { $0 == position }
        case "df":     gp.df.removeAll { $0 == position }
        case "remain": gp.remain.removeAll { $0 == position }
        case "only":   gp.only.removeAll { $0 == position }
        default: break
        }
        positionMap[grade] = gp
    }

    private func addToSlot(grade: String, slot: String, position: String) {
        guard var gp = positionMap[grade] else { return }
        switch slot {
        case "galley": gp.galley.append(position)
        case "df":     gp.df.append(position)
        case "remain": gp.remain.append(position)
        case "only":   gp.only.append(position)
        default: break
        }
        positionMap[grade] = gp
    }

    private func loadPositions() {
        guard let reg = trip.registration else { return }
        if let loaded = OperationTypeResolver.loadPositions(
            crewData: trip.crewMembers,
            registration: reg,
            isULR: trip.flightInfo.isULR,
            forTripsTableOnly: true
        ) {
            positionMap = loaded.positions
        }
    }

    private func gradeColor(_ grade: String) -> Color {
        switch grade {
        case "PUR", "CSV": return .orange
        case "FG1": return .red
        case "GR1": return .blue
        case "W": return .purple
        case "GR2": return .green
        case "CSA": return .gray
        case "EXTRA": return .secondary
        default: return .gray
        }
    }
}

// MARK: - Flow Layout for wrapping position chips

struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, offset) in result.offsets.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + offset.x, y: bounds.minY + offset.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, offsets: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var offsets: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            offsets.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x)
        }

        return (CGSize(width: maxX, height: y + rowHeight), offsets)
    }
}
