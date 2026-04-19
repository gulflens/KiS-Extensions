import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - DesktopView

/// Root container for the polaroid evidence feature. Hosts:
///   - the Procreate-style library grid,
///   - a top bar (title, Select, sort, +),
///   - a multi-select bulk action bar (Stack / Duplicate / Share / Delete),
///   - all modal presentations (composer, detail, edit, stack browser).
struct DesktopView: View {

    // MARK: Stores

    let evidenceStore: PolaroidEvidenceStore

    // MARK: Selection state

    @State private var multiSelect = false
    @State private var selectedPolaroidIDs: Set<UUID> = []
    @State private var selectedStackIDs: Set<UUID> = []

    // MARK: Modal presentation state

    @State private var presentedStackID: UUID?
    @State private var detailPolaroidID: UUID?
    @State private var editPolaroidID: UUID?
    @State private var showingComposer = false
    #if canImport(UIKit)
    @State private var composerInitialSource: CameraCaptureView.Source = .camera
    #endif

    // MARK: Confirmations

    @State private var showBulkDeleteConfirm = false

    // MARK: Share

    @State private var shareItems: [Any] = []
    @State private var showingShareSheet = false

    // MARK: Body

    var body: some View {
        VStack(spacing: 0) {
            topBar
            libraryContent
        }
        .ignoresSafeArea(.container, edges: .horizontal)
        .overlay(alignment: .bottom) { floatingActionStack }
        .animation(.easeInOut(duration: 0.2), value: multiSelect)
        .animation(.easeInOut(duration: 0.2), value: selectedPolaroidIDs)
        .animation(.easeInOut(duration: 0.2), value: selectedStackIDs)
        .onAppear { evidenceStore.loadAll() }
        .fullScreenCover(item: presentedStackBinding) { wrapper in
            if let stack = evidenceStore.stacks.first(where: { $0.id == wrapper.id }) {
                StackBrowserView(stack: stack, store: evidenceStore) { _ in
                    presentedStackID = nil
                }
                .transition(.opacity.combined(with: .scale(scale: 0.92)))
            } else {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onAppear { presentedStackID = nil }
            }
        }
        #if canImport(UIKit)
        .fullScreenCover(item: detailPolaroidBinding) { wrapper in
            if let polaroid = evidenceStore.polaroids.first(where: { $0.id == wrapper.id }) {
                PolaroidDetailView(polaroid: polaroid, store: evidenceStore) {
                    detailPolaroidID = nil
                }
            } else {
                Color.clear.onAppear { detailPolaroidID = nil }
            }
        }
        .fullScreenCover(isPresented: $showingComposer) {
            PolaroidComposerView(
                initialSource: composerInitialSource,
                onSave: { metadata, image in
                    handleCaptureSave(metadata: metadata, image: image)
                },
                onCancel: {
                    showingComposer = false
                }
            )
        }
        .fullScreenCover(item: editPolaroidBinding) { wrapper in
            if let polaroid = evidenceStore.polaroids.first(where: { $0.id == wrapper.id }) {
                NavigationStack {
                    EditPolaroidView(polaroid: polaroid, store: evidenceStore)
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: shareItems) {
                showingShareSheet = false
                shareItems = []
            }
        }
        .confirmationDialog(
            "Delete selected items?",
            isPresented: $showBulkDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                performBulkDelete()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Selected polaroids will be removed. Selected stacks will be removed along with all polaroids inside them.")
        }
        #endif
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack(spacing: 12) {
            topBarLeft
            Spacer()
            topBarRight
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(EvidenceTheme.libraryBackground)
        .overlay(alignment: .bottom) {
            Divider().opacity(0.2)
        }
    }

    @ViewBuilder
    private var topBarLeft: some View {
        if multiSelect {
            let count = selectedPolaroidIDs.count + selectedStackIDs.count
            Text(count == 1 ? "1 selected" : "\(count) selected")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
                .monospacedDigit()
        } else {
            Text("Polaroids")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
        }
    }

    @ViewBuilder
    private var topBarRight: some View {
        HStack(spacing: 16) {
            selectButton
            sortMenu
        }
    }

    private var selectButton: some View {
        Button(multiSelect ? "Done" : "Select") {
            if multiSelect { exitMultiSelect() } else { enterMultiSelect() }
        }
        .fontWeight(.semibold)
        .foregroundStyle(.white)
    }

    private var sortMenu: some View {
        Menu {
            Picker("Sort", selection: sortBinding) {
                Text("Date (newest)").tag(PolaroidEvidenceStore.SortOrder.newestFirst)
                Text("Date (oldest)").tag(PolaroidEvidenceStore.SortOrder.oldestFirst)
                Text("Name").tag(PolaroidEvidenceStore.SortOrder.byName)
                Text("Category").tag(PolaroidEvidenceStore.SortOrder.byCategory)
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down.circle")
                .font(.title3)
                .foregroundStyle(.white)
        }
    }

    private var sortBinding: Binding<PolaroidEvidenceStore.SortOrder> {
        Binding(
            get: { evidenceStore.sortOrder },
            set: { evidenceStore.sortOrder = $0 }
        )
    }

    // MARK: Floating capture buttons

    @ViewBuilder
    private var floatingCaptureButtons: some View {
        #if canImport(UIKit)
        HStack(spacing: 16) {
            Button {
                composerInitialSource = .library
                showingComposer = true
            } label: {
                Image(systemName: "photo.on.rectangle")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.2), in: Circle())
            }

            Button {
                composerInitialSource = .camera
                showingComposer = true
            } label: {
                Image(systemName: "camera.fill")
                    .font(.largeTitle)
                    .foregroundStyle(EvidenceTheme.brandNavy)
                    .frame(width: 90, height: 90)
                    .background(Color.gray, in: Circle())
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)
            }
        }
        .padding(.bottom, 24)
        #endif
    }

    // MARK: Content

    private var libraryContent: some View {
        LibraryGridView(
            store: evidenceStore,
            multiSelect: multiSelect,
            selectedPolaroidIDs: $selectedPolaroidIDs,
            selectedStackIDs: $selectedStackIDs,
            onPolaroidOpen: { id in editPolaroidID = id },
            onStackOpen: { id in presentedStackID = id }
        )
    }

    // MARK: Floating action stack

    @ViewBuilder
    private var floatingActionStack: some View {
        if multiSelect, !selectedPolaroidIDs.isEmpty || !selectedStackIDs.isEmpty {
            bulkActionBar
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
        } else if !multiSelect {
            floatingCaptureButtons
        }
    }

    // MARK: Bulk action bar

    private var bulkActionBar: some View {
        let polaroidCount = selectedPolaroidIDs.count
        let stackCount = selectedStackIDs.count
        let totalCount = polaroidCount + stackCount
        let canDuplicate = polaroidCount >= 1
        let canShare = polaroidCount >= 1

        return HStack(spacing: 0) {
            actionBarLabel("\(totalCount) selected", icon: "checkmark.circle")
            Spacer()
            actionBarButton(
                "Duplicate", icon: "plus.square.on.square",
                color: canDuplicate ? EvidenceTheme.brandNavy : .gray,
                enabled: canDuplicate
            ) { performBulkDuplicate() }
            actionBarDivider
            actionBarButton(
                "Share", icon: "square.and.arrow.up",
                color: canShare ? EvidenceTheme.brandNavy : .gray,
                enabled: canShare
            ) { performBulkShare() }
            actionBarDivider
            actionBarButton(
                "Delete", icon: "trash",
                color: .red, enabled: totalCount > 0
            ) { showBulkDeleteConfirm = true }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThickMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
    }

    // MARK: Action bar primitives

    private func actionBarLabel(_ text: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
            Text(text)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(EvidenceTheme.brandNavy)
    }

    private func actionBarButton(
        _ label: String,
        icon: String,
        color: Color,
        enabled: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.body.weight(.semibold))
                Text(label)
                    .font(.caption2.weight(.medium))
            }
            .foregroundStyle(color)
            .frame(width: 64)
            .opacity(enabled ? 1.0 : 0.5)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    private var actionBarDivider: some View {
        Divider()
            .frame(height: 30)
            .padding(.horizontal, 4)
    }

    // MARK: Modal binding wrappers

    private struct IDWrapper: Identifiable {
        let id: UUID
    }

    private var presentedStackBinding: Binding<IDWrapper?> {
        Binding(
            get: { presentedStackID.map(IDWrapper.init(id:)) },
            set: { presentedStackID = $0?.id }
        )
    }

    private var detailPolaroidBinding: Binding<IDWrapper?> {
        Binding(
            get: { detailPolaroidID.map(IDWrapper.init(id:)) },
            set: { detailPolaroidID = $0?.id }
        )
    }

    private var editPolaroidBinding: Binding<IDWrapper?> {
        Binding(
            get: { editPolaroidID.map(IDWrapper.init(id:)) },
            set: { editPolaroidID = $0?.id }
        )
    }

    // MARK: Multi-select transitions

    private func enterMultiSelect() {
        multiSelect = true
    }

    private func exitMultiSelect() {
        multiSelect = false
        selectedPolaroidIDs = []
        selectedStackIDs = []
    }

    // MARK: Bulk action handlers

    private func performBulkDuplicate() {
        let polaroids = selectedPolaroidIDs.compactMap { id in
            evidenceStore.polaroids.first(where: { $0.id == id })
        }
        guard !polaroids.isEmpty else { return }
        evidenceStore.bulkDuplicate(polaroids)
        exitMultiSelect()
    }

    private func performBulkShare() {
        #if canImport(UIKit)
        let polaroids = selectedPolaroidIDs.compactMap { id in
            evidenceStore.polaroids.first(where: { $0.id == id })
        }
        let flattenedImages: [UIImage] = polaroids.compactMap { polaroid in
            let model = PolaroidCardView.Model(polaroid: polaroid)
            return PolaroidCardView.renderToImage(model: model)
        }
        guard !flattenedImages.isEmpty else { return }
        shareItems = flattenedImages
        showingShareSheet = true
        #endif
    }

    private func performBulkDelete() {
        let polaroids = selectedPolaroidIDs.compactMap { id in
            evidenceStore.polaroids.first(where: { $0.id == id })
        }
        let stacks = selectedStackIDs.compactMap { id in
            evidenceStore.stacks.first(where: { $0.id == id })
        }
        evidenceStore.bulkDelete(polaroids: polaroids, stacks: stacks)
        exitMultiSelect()
    }

    // MARK: Capture commit

    #if canImport(UIKit)
    private func handleCaptureSave(metadata: PolaroidMetadata, image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.85) else {
            showingComposer = false
            return
        }
        evidenceStore.captureNewPolaroid(
            metadata: metadata,
            imageData: imageData,
            viewportCenter: .zero
        )
        showingComposer = false
    }
    #endif
}
