import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

// MARK: - SectorEvidenceView

struct SectorEvidenceView: View {

    // MARK: Inputs

    let sector: PlannedSector

    // MARK: Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: State

    @State private var store: PolaroidEvidenceStore?
    @State private var presentedStackID: UUID?
    @State private var detailPolaroidID: UUID?
    @State private var editPolaroidID: UUID?
    @State private var multiSelect = false
    @State private var selectedPolaroidIDs: Set<UUID> = []
    @State private var selectedStackIDs: Set<UUID> = []
    @State private var showBulkDeleteConfirm = false
    @State private var shareItems: [Any] = []
    @State private var showingShareSheet = false

    #if canImport(UIKit)
    @State private var showingCamera = false
    @State private var showingLibrary = false
    @State private var capturedImage: UIImage?
    @State private var captionText = ""
    @State private var seatLocationText = ""
    @State private var selectedCategory: EvidenceCategory = .cabinDefect
    @FocusState private var captionFocused: Bool

    @State private var photoScale: CGFloat = 1.0
    @State private var lastPhotoScale: CGFloat = 1.0
    @State private var photoOffset: CGSize = .zero
    @State private var lastPhotoOffset: CGSize = .zero

    @State private var imageScale: CGFloat = 1.0
    @State private var lastImageScale: CGFloat = 1.0
    @State private var imageOffset: CGSize = .zero
    @State private var lastImageOffset: CGSize = .zero
    @State private var imageRotation: Angle = .zero
    @State private var lastImageRotation: Angle = .zero
    #endif

    // MARK: Body

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                topBar
                gridContent
            }
            .overlay(alignment: .bottom) { floatingActionStack }

            #if canImport(UIKit)
            if capturedImage != nil {
                captionEditorView
                    .transition(.opacity)
            }
            #endif
        }
        .background(EvidenceTheme.libraryBackground.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.25), value: capturedImage != nil)
        .animation(.easeInOut(duration: 0.2), value: multiSelect)
        .animation(.easeInOut(duration: 0.2), value: selectedPolaroidIDs)
        .animation(.easeInOut(duration: 0.2), value: selectedStackIDs)
        .onAppear {
            if store == nil {
                store = PolaroidEvidenceStore(context: modelContext, sector: sector)
            }
            store?.loadAll()
        }
        .fullScreenCover(item: presentedStackBinding) { wrapper in
            if let store, let stack = store.stacks.first(where: { $0.id == wrapper.id }) {
                StackBrowserView(stack: stack, store: store) { _ in
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
        .fullScreenCover(item: detailBinding) { wrapper in
            if let store, let polaroid = store.polaroids.first(where: { $0.id == wrapper.id }) {
                PolaroidDetailView(polaroid: polaroid, store: store) {
                    detailPolaroidID = nil
                }
            } else {
                Color.clear.onAppear { detailPolaroidID = nil }
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraCaptureView(
                source: .camera,
                onCapture: { image in
                    showingCamera = false
                    capturedImage = image
                    captionText = ""
                    seatLocationText = ""
                    imageScale = 1.0; lastImageScale = 1.0
                    imageOffset = .zero; lastImageOffset = .zero
                    imageRotation = .zero; lastImageRotation = .zero
                },
                onCancel: { showingCamera = false }
            )
            .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $showingLibrary) {
            CameraCaptureView(
                source: .library,
                onCapture: { image in
                    showingLibrary = false
                    capturedImage = image
                    captionText = ""
                    seatLocationText = ""
                    imageScale = 1.0; lastImageScale = 1.0
                    imageOffset = .zero; lastImageOffset = .zero
                    imageRotation = .zero; lastImageRotation = .zero
                },
                onCancel: { showingLibrary = false }
            )
            .ignoresSafeArea()
        }
        .fullScreenCover(item: editPolaroidBinding) { wrapper in
            if let store, let polaroid = store.polaroids.first(where: { $0.id == wrapper.id }) {
                NavigationStack {
                    EditPolaroidView(polaroid: polaroid, store: store)
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
        .onChange(of: showingCamera) { _, showing in
            if !showing && capturedImage != nil {
                captionFocused = true
            }
        }
        .onChange(of: showingLibrary) { _, showing in
            if !showing && capturedImage != nil {
                captionFocused = true
            }
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
                .font(.headline)
                .foregroundStyle(.white)
                .monospacedDigit()
        } else {
            Text("Evidence photos")
                .font(.headline)
                .foregroundStyle(.white)
        }
    }

    @ViewBuilder
    private var topBarRight: some View {
        if let store, !store.polaroids.isEmpty {
            HStack(spacing: 16) {
                Button(multiSelect ? "Done" : "Select") {
                    if multiSelect { exitMultiSelect() } else { enterMultiSelect() }
                }
                .fontWeight(.semibold)
                .foregroundStyle(.white)

                sortMenu
            }
        }
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
            get: { store?.sortOrder ?? .newestFirst },
            set: { store?.sortOrder = $0 }
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

    // MARK: Floating capture buttons

    @ViewBuilder
    private var floatingCaptureButtons: some View {
        #if canImport(UIKit)
        HStack(spacing: 16) {
            Button {
                showingLibrary = true
            } label: {
                Image(systemName: "photo.on.rectangle")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.2), in: Circle())
            }

            Button {
                showingCamera = true
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

    // MARK: Caption editor

    #if canImport(UIKit)
    @ViewBuilder
    private var captionEditorView: some View {
        if let image = capturedImage {
            GeometryReader { geo in
                let isLandscape = geo.size.width > geo.size.height
                ZStack {
                    EvidenceTheme.desktopBackground.ignoresSafeArea()

                    if isLandscape {
                        captionLandscape(image: image, geo: geo)
                    } else {
                        captionPortrait(image: image)
                    }
                }
            }
        }
    }

    private func captionLandscape(image: UIImage, geo: GeometryProxy) -> some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                ZStack {
                    zoomablePolaroid(image: image)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    if hasImageEdits {
                        VStack {
                            HStack {
                                Spacer()
                                Button {
                                    resetImageEdits()
                                } label: {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .frame(width: 36, height: 36)
                                        .background(.black.opacity(0.5), in: Circle())
                                }
                                .padding(12)
                            }
                            Spacer()
                        }
                    }
                }

                HStack(spacing: 10) {
                    Image(systemName: "minus.magnifyingglass")
                        .font(.caption)
                        .foregroundStyle(.gray)
                    Slider(value: $photoScale, in: 1.0...5.0)
                        .tint(.gray)
                        .onChange(of: photoScale) { _, newValue in
                            lastPhotoScale = newValue
                            if newValue <= 1.0 {
                                photoOffset = .zero
                                lastPhotoOffset = .zero
                            }
                        }
                    Image(systemName: "plus.magnifyingglass")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 10)
            }
            .frame(width: geo.size.width * 0.70, height: geo.size.height)

            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Caption")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                        TextField("What happened here?", text: $captionText, axis: .vertical)
                            .lineLimit(1...3)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Seat / location")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                        TextField("3K or Galley 2", text: $seatLocationText)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .textFieldStyle(.roundedBorder)
                    }

                    Divider()
                        .padding(.vertical, 2)

                    Text("Category")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(EvidenceCategory.allCases) { category in
                        Button {
                            selectedCategory = category
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: category.iconSymbol)
                                    .font(.system(size: 12))
                                Text(category.displayName)
                                    .font(.subheadline)
                                Spacer()
                                if selectedCategory == category {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                selectedCategory == category
                                    ? Color.red.opacity(0.1)
                                    : Color.white
                            )
                            .foregroundStyle(
                                selectedCategory == category
                                    ? .red
                                    : .primary
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }

                    Divider()
                        .padding(.vertical, 4)

                    Button {
                        saveCapture(image: image)
                    } label: {
                        Text("Save evidence")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.red, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .disabled(captionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(captionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.4 : 1.0)

                    Button("Discard") {
                        capturedImage = nil
                    }
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                }
                .padding(16)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func captionPortrait(image: UIImage) -> some View {
        VStack(spacing: 20) {
            Spacer()

            polaroidWithCaption(image: image)

            VStack(alignment: .leading, spacing: 4) {
                Text("Seat / location")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                TextField("3K or Galley 2", text: $seatLocationText)
                    .textFieldStyle(.roundedBorder)
            }
            .padding(.horizontal, 40)

            Picker("Category", selection: $selectedCategory) {
                ForEach(EvidenceCategory.allCases) { category in
                    Text(category.displayName).tag(category)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 40)

            Button {
                saveCapture(image: image)
            } label: {
                Text("Save evidence")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.red, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(captionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(captionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.4 : 1.0)
            .padding(.horizontal, 40)

            Button("Discard") {
                capturedImage = nil
            }
            .font(.subheadline)
            .foregroundStyle(.gray)

            Spacer()
        }
    }

    private static let cardWidth: CGFloat = 328
    private static let cardHeight: CGFloat = 350
    private static let captionHeight: CGFloat = cardHeight * 0.2
    private static let imageHeight: CGFloat = cardHeight - captionHeight - 14

    @ViewBuilder
    private func polaroidWithCaption(image: UIImage) -> some View {
        VStack(spacing: 0) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: Self.cardWidth - 28, height: Self.imageHeight)
                .clipped()
                .padding(.top, 14)
                .padding(.horizontal, 14)

            TextField("What happened here?", text: $captionText, axis: .vertical)
                .font(.custom("Impact", size: 15))
                .tracking(0.5)
                .lineLimit(1...3)
                .focused($captionFocused)
                .padding(.horizontal, 18)
                .frame(height: Self.captionHeight)
        }
        .frame(width: Self.cardWidth, height: Self.cardHeight)
        .background(Color(white: 0.96))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .shadow(color: .black.opacity(0.25), radius: 16, x: 0, y: 8)
        .onAppear { captionFocused = true }
    }

    // MARK: Zoomable polaroid (landscape)

    private func zoomablePolaroid(image: UIImage) -> some View {
        VStack(spacing: 0) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .scaleEffect(imageScale)
                .rotationEffect(imageRotation)
                .offset(imageOffset)
                .frame(width: Self.cardWidth - 28, height: Self.imageHeight)
                .clipped()
                .contentShape(Rectangle())
                .gesture(imageMagnifyGesture)
                .gesture(imageRotateGesture)
                .gesture(imageDragGesture)
                .onTapGesture(count: 2) { resetImageEdits() }
                .padding(.top, 14)
                .padding(.horizontal, 14)

            TextField("What happened here?", text: $captionText, axis: .vertical)
                .font(.custom("Impact", size: 15))
                .tracking(0.5)
                .lineLimit(1...3)
                .focused($captionFocused)
                .padding(.horizontal, 18)
                .frame(height: Self.captionHeight)
        }
        .frame(width: Self.cardWidth, height: Self.cardHeight)
        .background(Color(white: 0.96))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .shadow(color: .black.opacity(0.25), radius: 16, x: 0, y: 8)
        .scaleEffect(photoScale)
        .offset(photoOffset)
        .onAppear { captionFocused = true }
    }

    // MARK: Image editing gestures

    private var imageMagnifyGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let newScale = lastImageScale * value.magnification
                imageScale = min(max(newScale, 0.5), 5.0)
            }
            .onEnded { _ in
                lastImageScale = imageScale
            }
    }

    private var imageRotateGesture: some Gesture {
        RotateGesture()
            .onChanged { value in
                imageRotation = lastImageRotation + value.rotation
            }
            .onEnded { _ in
                lastImageRotation = imageRotation
            }
    }

    private var imageDragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                imageOffset = CGSize(
                    width: lastImageOffset.width + value.translation.width,
                    height: lastImageOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                lastImageOffset = imageOffset
            }
    }

    private var hasImageEdits: Bool {
        imageScale != 1.0 || imageOffset != .zero || imageRotation != .zero
    }

    private func resetImageEdits() {
        withAnimation(.spring(duration: 0.3)) {
            imageScale = 1.0
            lastImageScale = 1.0
            imageOffset = .zero
            lastImageOffset = .zero
            imageRotation = .zero
            lastImageRotation = .zero
        }
    }

    private func resetCanvasZoom() {
        withAnimation(.spring(duration: 0.3)) {
            photoScale = 1.0
            lastPhotoScale = 1.0
            photoOffset = .zero
            lastPhotoOffset = .zero
        }
    }

    private func saveCapture(image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.85) else {
            capturedImage = nil
            return
        }
        let route = "\(sector.departureStation)-\(sector.arrivalStation)"
        let trimmedSeat = seatLocationText.trimmingCharacters(in: .whitespacesAndNewlines)
        let metadata = PolaroidMetadata(
            caption: captionText.trimmingCharacters(in: .whitespacesAndNewlines),
            category: selectedCategory,
            flightNumber: sector.flightNumber,
            route: route,
            seatLocation: trimmedSeat.isEmpty ? nil : trimmedSeat,
            capturedAt: Date()
        )
        store?.captureNewPolaroid(
            metadata: metadata,
            imageData: imageData,
            viewportCenter: .zero
        )
        capturedImage = nil
        seatLocationText = ""
    }
    #endif

    // MARK: Grid

    @ViewBuilder
    private var gridContent: some View {
        if let store {
            if store.polaroids.isEmpty {
                emptyState
            } else {
                LibraryGridView(
                    store: store,
                    multiSelect: multiSelect,
                    selectedPolaroidIDs: $selectedPolaroidIDs,
                    selectedStackIDs: $selectedStackIDs,
                    onPolaroidOpen: { id in editPolaroidID = id },
                    onStackOpen: { id in presentedStackID = id }
                )
            }
        } else {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.gray)
            Text("No evidence photos")
                .font(.headline)
                .foregroundStyle(.gray)
            Text("Tap the camera to capture evidence for this sector.")
                .font(.subheadline)
                .foregroundStyle(Color.gray.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(EvidenceTheme.libraryBackground)
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
        guard let store else { return }
        let polaroids = selectedPolaroidIDs.compactMap { id in
            store.polaroids.first(where: { $0.id == id })
        }
        guard !polaroids.isEmpty else { return }
        store.bulkDuplicate(polaroids)
        exitMultiSelect()
    }

    private func performBulkShare() {
        #if canImport(UIKit)
        guard let store else { return }
        let polaroids = selectedPolaroidIDs.compactMap { id in
            store.polaroids.first(where: { $0.id == id })
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
        guard let store else { return }
        let polaroids = selectedPolaroidIDs.compactMap { id in
            store.polaroids.first(where: { $0.id == id })
        }
        let stacks = selectedStackIDs.compactMap { id in
            store.stacks.first(where: { $0.id == id })
        }
        store.bulkDelete(polaroids: polaroids, stacks: stacks)
        exitMultiSelect()
    }

    // MARK: Modal binding wrappers

    private struct IDWrapper: Identifiable {
        let id: UUID
    }

    private var detailBinding: Binding<IDWrapper?> {
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

    private var presentedStackBinding: Binding<IDWrapper?> {
        Binding(
            get: { presentedStackID.map(IDWrapper.init(id:)) },
            set: { presentedStackID = $0?.id }
        )
    }
}
