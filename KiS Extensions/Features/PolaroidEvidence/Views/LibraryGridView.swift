import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - LibraryGridView

struct LibraryGridView: View {

    // MARK: Inputs

    let store: PolaroidEvidenceStore
    let multiSelect: Bool
    @Binding var selectedPolaroidIDs: Set<UUID>
    @Binding var selectedStackIDs: Set<UUID>
    let onPolaroidOpen: (UUID) -> Void
    let onStackOpen: (UUID) -> Void
    var zoomLevel: Double = 0.5

    // MARK: Environment

    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.verticalSizeClass) private var vSizeClass

    // MARK: Layout

    private func columnsForSize(_ size: CGSize) -> [GridItem] {
        let wide = size.width > size.height
        // Slider 0 → max columns (smallest thumbs), Slider 1 → min columns (largest).
        let minCount: Int
        let maxCount: Int
        if hSizeClass == .regular {
            minCount = 2
            maxCount = wide ? 7 : 6
        } else {
            minCount = 1
            maxCount = (vSizeClass == .compact) ? 5 : 3
        }
        let clamped = max(0.0, min(1.0, zoomLevel))
        let range = Double(maxCount - minCount)
        let count = max(minCount, min(maxCount, maxCount - Int((clamped * range).rounded())))
        return Array(repeating: GridItem(.flexible(), spacing: 20), count: count)
    }

    private static let thumbCorner: CGFloat = 12

    // MARK: Date formatter

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd MMM yy"
        return f
    }()

    // MARK: Item model

    private enum LibraryItem: Identifiable {
        case polaroid(PolaroidEvidence)
        case stack(PolaroidStack)

        var id: UUID {
            switch self {
            case .polaroid(let p): return p.id
            case .stack(let s):    return s.id
            }
        }

        var sortKey: Date {
            switch self {
            case .polaroid(let p): return p.capturedAt
            case .stack(let s):    return s.createdAt
            }
        }
    }

    private var items: [LibraryItem] {
        let stackIDs = Set(store.stacks.map(\.id))
        let freePolaroids = store.polaroids
            .filter { $0.stack == nil || !stackIDs.contains($0.stack!.id) }
            .map(LibraryItem.polaroid)
        let stacks = store.stacks.map(LibraryItem.stack)
        let merged = (freePolaroids + stacks)

        switch store.sortOrder {
        case .newestFirst:
            return merged.sorted { $0.sortKey > $1.sortKey }
        case .oldestFirst:
            return merged.sorted { $0.sortKey < $1.sortKey }
        case .byCategory:
            return merged.sorted { lhs, rhs in
                let lk = categoryKey(for: lhs)
                let rk = categoryKey(for: rhs)
                if lk == rk { return lhs.sortKey > rhs.sortKey }
                return lk < rk
            }
        case .byName:
            return merged.sorted { lhs, rhs in
                let ln = nameKey(for: lhs)
                let rn = nameKey(for: rhs)
                if ln == rn { return lhs.sortKey > rhs.sortKey }
                return ln < rn
            }
        }
    }

    private func categoryKey(for item: LibraryItem) -> String {
        switch item {
        case .polaroid(let p): return p.categoryRaw
        case .stack(let s):    return s.categoryRaw ?? "zzz"
        }
    }

    private func nameKey(for item: LibraryItem) -> String {
        switch item {
        case .polaroid(let p):
            let c = p.caption.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return c.isEmpty ? "zzz_untitled" : c
        case .stack(let s):
            let label = (s.label ?? s.category?.displayName ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return label.isEmpty ? "zzz_untitled" : label
        }
    }

    // MARK: Body

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                if items.isEmpty {
                    emptyState
                        .frame(maxWidth: .infinity)
                        .padding(.top, 80)
                } else {
                    LazyVGrid(columns: columnsForSize(geo.size), spacing: 28) {
                        ForEach(items) { item in
                            cell(for: item)
                                .frame(maxHeight: .infinity, alignment: .top)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 24)
                }
            }
        }
        .background(EvidenceTheme.libraryBackground.ignoresSafeArea())
    }

    // MARK: Empty state

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.stack")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.gray)
            Text("No polaroids yet")
                .font(.headline)
                .foregroundStyle(.gray)
            Text("Tap the plus to capture your first.")
                .font(.subheadline)
                .foregroundStyle(Color.gray.opacity(0.7))
        }
    }

    // MARK: Cell dispatch

    @ViewBuilder
    private func cell(for item: LibraryItem) -> some View {
        switch item {
        case .polaroid(let polaroid):
            polaroidCell(polaroid)
        case .stack(let stack):
            stackCell(stack)
        }
    }

    // MARK: Polaroid cell

    @ViewBuilder
    private func polaroidCell(_ polaroid: PolaroidEvidence) -> some View {
        let isSelected = selectedPolaroidIDs.contains(polaroid.id)
        ZStack(alignment: .topTrailing) {
            PolaroidCardView(model: PolaroidCardView.Model(polaroid: polaroid))

            if multiSelect {
                selectionBadge(isSelected: isSelected)
                    .padding(8)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.white.opacity(isSelected ? 0.8 : 0), lineWidth: 3)
        )
        .scaleEffect(isSelected && multiSelect ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.12), value: isSelected)
        .onTapGesture {
            if multiSelect {
                if isSelected { selectedPolaroidIDs.remove(polaroid.id) }
                else { selectedPolaroidIDs.insert(polaroid.id) }
            } else {
                onPolaroidOpen(polaroid.id)
            }
        }
    }

    // MARK: Thumbnail

    @ViewBuilder
    private func thumbnail(for polaroid: PolaroidEvidence) -> some View {
        #if canImport(UIKit)
        if let uiImage = UIImage(data: polaroid.imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(minWidth: 0, maxWidth: .infinity)
                .aspectRatio(1.0, contentMode: .fill)
                .clipped()
        } else {
            placeholderThumb
        }
        #else
        placeholderThumb
        #endif
    }

    private var placeholderThumb: some View {
        Color(white: 0.22)
            .aspectRatio(1.0, contentMode: .fill)
            .overlay {
                Image(systemName: "photo")
                    .font(.title2)
                    .foregroundStyle(.gray)
            }
    }

    // MARK: Helpers

    private func captionPreview(_ caption: String) -> String {
        let trimmed = caption.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Untitled" : trimmed
    }

    private func subtitle(for polaroid: PolaroidEvidence) -> String {
        let cat = polaroid.category.displayName
        let date = Self.dateFormatter.string(from: polaroid.capturedAt)
        return "\(cat) · \(date)"
    }

    // MARK: Stack cell

    @ViewBuilder
    private func stackCell(_ stack: PolaroidStack) -> some View {
        let isSelected = selectedStackIDs.contains(stack.id)
        let stackMembers = store.polaroids
            .filter { $0.stack?.id == stack.id }
            .sorted(by: { $0.stackOrder < $1.stackOrder })
        let top3 = Array(stackMembers.prefix(3))

        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                stackedThumbnails(top3)

                if multiSelect {
                    selectionBadge(isSelected: isSelected)
                        .padding(8)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: Self.thumbCorner, style: .continuous)
                    .stroke(Color.white.opacity(isSelected ? 0.8 : 0), lineWidth: 3)
            )
            .scaleEffect(isSelected && multiSelect ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: isSelected)
            .onTapGesture {
                if multiSelect {
                    if isSelected { selectedStackIDs.remove(stack.id) }
                    else { selectedStackIDs.insert(stack.id) }
                } else {
                    onStackOpen(stack.id)
                }
            }

            VStack(spacing: 2) {
                Text(stack.category?.displayName ?? "Auto stack")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)

                let count = stack.polaroids.count
                Text(count == 1 ? "1 polaroid" : "\(count) polaroids")
                    .font(.caption2)
                    .foregroundStyle(Color.gray)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: Stacked thumbnails

    @ViewBuilder
    private func stackedThumbnails(_ polaroids: [PolaroidEvidence]) -> some View {
        ZStack {
            if polaroids.count >= 3 {
                stackThumb(for: polaroids[2])
                    .rotationEffect(.degrees(-4))
                    .offset(x: -6, y: -4)
            }
            if polaroids.count >= 2 {
                stackThumb(for: polaroids[1])
                    .rotationEffect(.degrees(3))
                    .offset(x: 5, y: -2)
            }
            if let top = polaroids.first {
                stackThumb(for: top)
            } else {
                placeholderThumb
                    .clipShape(RoundedRectangle(cornerRadius: Self.thumbCorner, style: .continuous))
                    .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
            }
        }
        .padding(6)
    }

    @ViewBuilder
    private func stackThumb(for polaroid: PolaroidEvidence) -> some View {
        PolaroidCardView(model: PolaroidCardView.Model(polaroid: polaroid))
    }

    // MARK: Selection badge

    @ViewBuilder
    private func selectionBadge(isSelected: Bool) -> some View {
        ZStack {
            Circle()
                .fill(isSelected ? Color.white : Color.black.opacity(0.5))
                .frame(width: 26, height: 26)
                .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.black)
            } else {
                Circle()
                    .stroke(Color.white.opacity(0.7), lineWidth: 1.5)
                    .frame(width: 22, height: 22)
            }
        }
    }
}
