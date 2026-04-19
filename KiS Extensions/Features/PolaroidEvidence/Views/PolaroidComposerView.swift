import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - PolaroidComposerView

/// Capture entry point. On first appear, presents a camera (or library
/// fallback if camera is denied or unavailable). Once an image is captured,
/// shows a metadata form with a live polaroid preview. Save returns image
/// + metadata to the caller via `onSave`; cancel discards.
#if canImport(UIKit)
struct PolaroidComposerView: View {

    // MARK: Inputs

    let initialSource: CameraCaptureView.Source
    let sectorMode: Bool
    let onSave: (PolaroidMetadata, UIImage) -> Void
    let onCancel: () -> Void

    init(
        initialSource: CameraCaptureView.Source = .camera,
        prefill: PolaroidMetadata? = nil,
        sectorMode: Bool = false,
        onSave: @escaping (PolaroidMetadata, UIImage) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.initialSource = initialSource
        self.sectorMode = sectorMode
        self._metadata = State(initialValue: prefill ?? PolaroidMetadata())
        self.onSave = onSave
        self.onCancel = onCancel
    }

    // MARK: Phase

    private enum Phase {
        case pickingPhoto
        case denied
        case editing(UIImage)
    }

    // MARK: State

    @State private var phase: Phase = .pickingPhoto
    @State private var pickerSource: CameraCaptureView.Source = .camera
    @State private var showingPicker = false
    @State private var showingDeniedAlert = false
    @State private var metadata: PolaroidMetadata

    // MARK: Body

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("New Polaroid")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarContent }
        }
        .onAppear { startCapture() }
        .fullScreenCover(isPresented: $showingPicker) {
            CameraCaptureView(
                source: pickerSource,
                onCapture: { image in
                    showingPicker = false
                    metadata.capturedAt = Date()
                    phase = .editing(image)
                },
                onCancel: {
                    showingPicker = false
                    if case .editing = phase {
                        // Retake cancelled — keep existing image.
                        return
                    }
                    onCancel()
                }
            )
            .ignoresSafeArea()
        }
        .alert("Camera not available", isPresented: $showingDeniedAlert) {
            Button("Choose from Library") {
                pickerSource = .library
                showingPicker = true
            }
            Button("Cancel", role: .cancel) { onCancel() }
        } message: {
            Text("Allow camera access in Settings, or pick an existing photo from your library.")
        }
    }

    // MARK: Content

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .pickingPhoto, .denied:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(EvidenceTheme.desktopBackground.ignoresSafeArea())
        case .editing(let image):
            EditingForm(image: image, metadata: $metadata, sectorMode: sectorMode) {
                pickerSource = .camera
                showingPicker = true
            }
        }
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Cancel") { onCancel() }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button("Save") { commit() }
                .fontWeight(.semibold)
                .disabled(!canSave)
        }
    }

    private var canSave: Bool {
        guard case .editing = phase else { return false }
        return metadata.isReady
    }

    private func commit() {
        guard case .editing(let image) = phase, metadata.isReady else { return }
        onSave(metadata, image)
    }

    // MARK: Capture flow

    private func startCapture() {
        // If the caller asked for the library directly, skip the camera
        // permission dance entirely — PHPicker-style UX.
        if initialSource == .library {
            pickerSource = .library
            showingPicker = true
            return
        }
        #if targetEnvironment(simulator)
        // No real camera on simulator; route straight to library so the
        // composer flow is testable without device hardware.
        pickerSource = .library
        showingPicker = true
        return
        #else
        switch CameraPermission.current {
        case .granted:
            pickerSource = .camera
            showingPicker = true
        case .needsRequest:
            Task { @MainActor in
                let granted = await CameraPermission.request()
                if granted {
                    pickerSource = .camera
                    showingPicker = true
                } else {
                    fallToDenied()
                }
            }
        case .denied:
            if !UIImagePickerController.isSourceTypeAvailable(.camera) {
                pickerSource = .library
                showingPicker = true
            } else {
                fallToDenied()
            }
        }
        #endif
    }

    private func fallToDenied() {
        phase = .denied
        showingDeniedAlert = true
    }
}

// MARK: - EditingForm

private struct EditingForm: View {

    let image: UIImage
    @Binding var metadata: PolaroidMetadata
    let sectorMode: Bool
    let onRetake: () -> Void

    @FocusState private var captionFocused: Bool

    // MARK: Canvas zoom
    @State private var photoScale: CGFloat = 1.0
    @State private var lastPhotoScale: CGFloat = 1.0
    @State private var photoOffset: CGSize = .zero
    @State private var lastPhotoOffset: CGSize = .zero

    // MARK: Image editing
    @State private var imageScale: CGFloat = 1.0
    @State private var lastImageScale: CGFloat = 1.0
    @State private var imageOffset: CGSize = .zero
    @State private var lastImageOffset: CGSize = .zero
    @State private var imageRotation: Angle = .zero
    @State private var lastImageRotation: Angle = .zero

    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            if isLandscape {
                landscapeLayout(geo: geo)
            } else {
                portraitLayout
            }
        }
        .background(EvidenceTheme.desktopBackground.ignoresSafeArea())
    }

    // MARK: Landscape layout

    private func landscapeLayout(geo: GeometryProxy) -> some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                ZStack {
                    zoomablePolaroid
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
            .frame(width: geo.size.width * 0.65, height: geo.size.height)

            ScrollView {
                VStack(spacing: 16) {
                    field("Caption") {
                        TextField("What happened here?", text: $metadata.caption, axis: .vertical)
                            .lineLimit(1...3)
                            .textFieldStyle(.roundedBorder)
                    }

                    field("Seat / location") {
                        TextField("3K or Galley 2", text: bindingForOptional(\.seatLocation))
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .textFieldStyle(.roundedBorder)
                    }

                    if !sectorMode {
                        field("Flight") {
                            TextField("EK342", text: bindingForOptional(\.flightNumber))
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .font(.body.monospaced())
                                .textFieldStyle(.roundedBorder)
                        }

                        field("Route") {
                            TextField("DXB-LHR", text: bindingForOptional(\.route))
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .font(.body.monospaced())
                                .textFieldStyle(.roundedBorder)
                        }
                    }

                    Divider()
                        .padding(.vertical, 2)

                    Text("Category")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(EvidenceCategory.allCases) { category in
                        Button {
                            metadata.category = category
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: category.iconSymbol)
                                    .font(.system(size: 12))
                                Text(category.displayName)
                                    .font(.subheadline)
                                Spacer()
                                if metadata.category == category {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                metadata.category == category
                                    ? Color.red.opacity(0.1)
                                    : Color.white
                            )
                            .foregroundStyle(
                                metadata.category == category
                                    ? .red
                                    : .primary
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: Zoomable polaroid (landscape)

    private static let cardWidth: CGFloat = 328
    private static let cardHeight: CGFloat = 350
    private static let captionHeight: CGFloat = cardHeight * 0.2
    private static let imageHeight: CGFloat = cardHeight - captionHeight - 14

    private var zoomablePolaroid: some View {
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

            TextField("What happened here?", text: $metadata.caption, axis: .vertical)
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

    // MARK: Portrait layout

    private var portraitLayout: some View {
        ScrollView {
            VStack(spacing: 24) {
                polaroidWithCaption

                VStack(alignment: .leading, spacing: 4) {
                    Text("Seat / location")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    TextField("3K or Galley 2", text: bindingForOptional(\.seatLocation))
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal, 40)

                if !sectorMode {
                    VStack(spacing: 12) {
                        field("Flight") {
                            TextField("EK342", text: bindingForOptional(\.flightNumber))
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .font(.body.monospaced())
                                .textFieldStyle(.roundedBorder)
                        }

                        field("Route") {
                            TextField("DXB-LHR", text: bindingForOptional(\.route))
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .font(.body.monospaced())
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    .padding(.horizontal, 40)
                }

                Picker("Category", selection: $metadata.category) {
                    ForEach(EvidenceCategory.allCases) { category in
                        Text(category.displayName).tag(category)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 40)
            }
            .padding(.vertical, 24)
        }
    }

    // MARK: Polaroid with caption (portrait)

    private var polaroidWithCaption: some View {
        VStack(spacing: 0) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: Self.cardWidth - 28, height: Self.imageHeight)
                .clipped()
                .padding(.top, 14)
                .padding(.horizontal, 14)

            TextField("What happened here?", text: $metadata.caption, axis: .vertical)
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

    // MARK: Field helper

    @ViewBuilder
    private func field<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            content()
        }
    }

    private func bindingForOptional(_ keyPath: WritableKeyPath<PolaroidMetadata, String?>) -> Binding<String> {
        Binding(
            get: { metadata[keyPath: keyPath] ?? "" },
            set: { metadata[keyPath: keyPath] = $0.isEmpty ? nil : $0 }
        )
    }
}
#endif
