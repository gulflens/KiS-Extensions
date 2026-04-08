import SwiftUI

/// Displays the AI-classified category path as tappable chips with Menu overrides.
/// Each chip is a Menu that lets the user override that level; overriding clears children.
/// Includes a "Write report" button at the bottom.
struct CategorySection: View {
    @Bindable var model: ComposerModel

    var body: some View {
        if let path = model.classifiedPath {
            AssistantBubble {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Category")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    ChipFlowLayout(spacing: 8) {
                        // Cat1 — always present
                        categoryChip(
                            label: path.cat1,
                            level: 1,
                            choices: KiSCategory1.allRawValues
                        )

                        // Cat2
                        if let cat2 = path.cat2 {
                            categoryChip(
                                label: cat2,
                                level: 2,
                                choices: cat2Choices
                            )
                        }

                        // Cat3
                        if let cat3 = path.cat3 {
                            categoryChip(
                                label: cat3,
                                level: 3,
                                choices: cat3Choices
                            )
                        }

                        // Cat4
                        if let cat4 = path.cat4 {
                            categoryChip(
                                label: cat4,
                                level: 4,
                                choices: cat4Choices
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Chip view

    @ViewBuilder
    private func categoryChip(label: String, level: Int, choices: [String]) -> some View {
        Menu {
            ForEach(choices, id: \.self) { choice in
                Button(choice) {
                    model.overrideCategory(level: level, value: choice)
                }
            }
        } label: {
            Text(label)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.tint.opacity(0.12), in: Capsule())
                .foregroundStyle(.tint)
        }
    }

    // MARK: - Choice lists

    private var cat2Choices: [String] {
        guard let cat1 = KiSCategory1(rawValue: model.classifiedPath?.cat1 ?? "") else { return [] }
        return CategoryTree.cat2List(under: cat1)
    }

    private var cat3Choices: [String] {
        guard let cat1 = KiSCategory1(rawValue: model.classifiedPath?.cat1 ?? ""),
              let cat2 = model.classifiedPath?.cat2 else { return [] }
        return CategoryTree.cat3List(under: cat1, cat2: cat2)
    }

    private var cat4Choices: [String] {
        guard let cat1 = KiSCategory1(rawValue: model.classifiedPath?.cat1 ?? ""),
              let cat2 = model.classifiedPath?.cat2,
              let cat3 = model.classifiedPath?.cat3 else { return [] }
        return CategoryTree.cat4List(under: cat1, cat2: cat2, cat3: cat3)
    }
}

// MARK: - ChipFlowLayout

/// A simple flow layout that wraps chips to the next line.
private struct ChipFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, origin) in result.origins.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, origins: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var origins: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            origins.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), origins)
    }
}
