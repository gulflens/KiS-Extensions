import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - StackBrowserView

/// Procreate-style stack browser. Same dark background and square thumbnails
/// as the library grid. Manual stacks expose label editing and dissolve;
/// auto stacks are read-only. Uses NavigationStack for smooth push transitions
/// into detail and edit views.
struct StackBrowserView: View {

    // MARK: Inputs

    let stack: PolaroidStack
    let store: PolaroidEvidenceStore
    let onDismiss: (UUID?) -> Void

    // MARK: Local state

    @State private var navigationPath = NavigationPath()
    @State private var isSelecting = false
    @State private var selectedIDs: Set<UUID> = []
    @State private var showDeleteConfirm = false
    @State private var showListView = false
    @State private var gridScale: CGFloat = 1.0
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.verticalSizeClass) private var vSizeClass

    // MARK: Layout

    private func columnsForSize(_ size: CGSize) -> [GridItem] {
        let wide = size.width > size.height
        let baseCount: Int
        if hSizeClass == .regular {
            baseCount = wide ? 4 : 3
        } else {
            baseCount = (vSizeClass == .compact) ? 4 : 2
        }
        let scaledCount = max(1, Int(round(Double(baseCount) / gridScale)))
        return Array(repeating: GridItem(.flexible(), spacing: 20), count: scaledCount)
    }

    private static let thumbCorner: CGFloat = 12

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd MMM yy"
        return f
    }()

    // MARK: Body

    var body: some View {
        NavigationStack(path: $navigationPath) {
            GeometryReader { geo in
                VStack(spacing: 0) {
                    topBar
                    contentBody(size: geo.size)
                }
            }
            .background(EvidenceTheme.libraryBackground.ignoresSafeArea())
            .navigationBarHidden(true)
            .confirmationDialog(
                "Delete \(selectedIDs.count) polaroid\(selectedIDs.count == 1 ? "" : "s")?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    for id in selectedIDs {
                        if let polaroid = store.polaroids.first(where: { $0.id == id }) {
                            store.delete(polaroid)
                        }
                    }
                    selectedIDs.removeAll()
                    isSelecting = false
                    if sortedPolaroids.isEmpty {
                        onDismiss(nil)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This evidence cannot be recovered after deletion.")
            }
            #if canImport(UIKit)
            .navigationDestination(for: PolaroidNavItem.self) { item in
                if let polaroid = store.polaroids.first(where: { $0.id == item.id }) {
                    EditPolaroidView(polaroid: polaroid, store: store)
                }
            }
            #endif
        }
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack(spacing: 12) {
            Button {
                onDismiss(nil)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                    Text("Polaroids")
                        .font(.body)
                }
                .foregroundStyle(.white)
            }
            .buttonStyle(.plain)

            Spacer()

            titleView

            Spacer()

            trailingMenu
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(EvidenceTheme.libraryBackground)
        .overlay(alignment: .bottom) {
            Divider().opacity(0.2)
        }
    }

    @ViewBuilder
    private var titleView: some View {
        Text(stack.category?.displayName ?? "Auto stack")
            .font(.title2.weight(.bold))
            .foregroundStyle(.white)
    }

    @ViewBuilder
    private var trailingMenu: some View {
        HStack(spacing: 16) {
            if isSelecting {
                Button {
                    guard !selectedIDs.isEmpty else { return }
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(selectedIDs.isEmpty ? .gray : .red)
                }
                .disabled(selectedIDs.isEmpty)

                Button {
                    isSelecting = false
                    selectedIDs.removeAll()
                } label: {
                    Text("Done")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                }
            } else {
                Button {
                    isSelecting = true
                } label: {
                    Text("Select")
                        .font(.body)
                        .foregroundStyle(.white)
                }

                Button {
                    showListView.toggle()
                } label: {
                    Image(systemName: showListView ? "square.grid.2x2" : "list.bullet")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                }
            }
        }
    }

    // MARK: Grid

    private var sortedPolaroids: [PolaroidEvidence] {
        store.polaroids
            .filter { $0.stack?.id == stack.id }
            .sorted { $0.stackOrder < $1.stackOrder }
    }

    @ViewBuilder
    private func contentBody(size: CGSize) -> some View {
        if showListView {
            listBody
        } else {
            gridBody(size: size)
        }
    }

    // MARK: Grid

    private func gridBody(size: CGSize) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVGrid(columns: columnsForSize(size), spacing: 28) {
                    ForEach(sortedPolaroids, id: \.id) { polaroid in
                        cellView(for: polaroid)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
            }

            gridSizeSlider
        }
    }

    private var gridSizeSlider: some View {
        HStack(spacing: 10) {
            Image(systemName: "photo")
                .font(.caption)
                .foregroundStyle(.gray)
            Slider(value: $gridScale, in: 0.5...2.0, step: 0.25)
                .tint(.gray)
            Image(systemName: "photo")
                .font(.title3)
                .foregroundStyle(.gray)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
        .background(EvidenceTheme.libraryBackground)
    }

    // MARK: List

    private var listBody: some View {
        List {
            ForEach(sortedPolaroids, id: \.id) { polaroid in
                listRow(for: polaroid)
                    .listRowBackground(Color.clear)
                    .listRowSeparatorTint(.gray.opacity(0.3))
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    @ViewBuilder
    private func listRow(for polaroid: PolaroidEvidence) -> some View {
        Button {
            if isSelecting {
                toggleSelection(polaroid.id)
            } else {
                navigationPath.append(PolaroidNavItem(id: polaroid.id))
            }
        } label: {
            HStack(spacing: 12) {
                if isSelecting {
                    Image(systemName: selectedIDs.contains(polaroid.id) ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(selectedIDs.contains(polaroid.id) ? .red : .gray)
                }

                #if canImport(UIKit)
                if let uiImage = UIImage(data: polaroid.imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                #endif

                VStack(alignment: .leading, spacing: 4) {
                    Text(polaroid.caption.isEmpty ? "No caption" : polaroid.caption)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Circle()
                            .fill(polaroid.category.tintColor)
                            .frame(width: 6, height: 6)
                        Text(polaroid.category.displayName)
                            .font(.caption)
                            .foregroundStyle(.gray)

                        if let flight = polaroid.flightNumber, !flight.isEmpty {
                            Text(flight)
                                .font(.caption.monospaced())
                                .foregroundStyle(.gray)
                        }
                    }

                    Text(polaroid.capturedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.gray.opacity(0.7))
                }

                Spacer()

                if !isSelecting {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.gray)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Cell

    @ViewBuilder
    private func cellView(for polaroid: PolaroidEvidence) -> some View {
        if isSelecting {
            Button {
                toggleSelection(polaroid.id)
            } label: {
                ZStack(alignment: .topLeading) {
                    PolaroidCardView(model: PolaroidCardView.Model(polaroid: polaroid))

                    Image(systemName: selectedIDs.contains(polaroid.id) ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(selectedIDs.contains(polaroid.id) ? .red : .white.opacity(0.7))
                        .shadow(radius: 2)
                        .padding(8)
                }
            }
            .buttonStyle(.plain)
        } else {
            NavigationLink(value: PolaroidNavItem(id: polaroid.id)) {
                PolaroidCardView(model: PolaroidCardView.Model(polaroid: polaroid))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Selection helpers

    private func toggleSelection(_ id: UUID) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }
}

// MARK: - Navigation item

struct PolaroidNavItem: Hashable {
    let id: UUID
}
