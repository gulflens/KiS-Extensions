import SwiftUI
import Photos
#if canImport(UIKit)
import UIKit
#endif

// MARK: - PolaroidDetailView

/// Wrapper that adds a NavigationStack for fullScreenCover presentations.
/// For push-navigation contexts (e.g. StackBrowserView), use
/// `PolaroidDetailContent` directly.
#if canImport(UIKit)
struct PolaroidDetailView: View {

    let polaroid: PolaroidEvidence
    let store: PolaroidEvidenceStore
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            PolaroidDetailContent(polaroid: polaroid, store: store, onDismiss: onDismiss)
        }
    }
}
#endif

// MARK: - PolaroidDetailContent

/// Full detail surface for a single polaroid. Landscape shows photo on the
/// left with metadata column on the right. Portrait shows the classic
/// vertical layout. Photo supports pinch-to-zoom and double-tap reset.
#if canImport(UIKit)
struct PolaroidDetailContent: View {

    // MARK: Inputs

    let polaroid: PolaroidEvidence
    let store: PolaroidEvidenceStore
    let onDismiss: (() -> Void)?

    // MARK: State

    @State private var showingDeleteConfirm = false
    @State private var shareItem: ShareableImage?
    @State private var savedToPhotos = false
    @State private var showingSaveAlert = false
    @State private var saveAlertMessage = ""

    // MARK: Canvas zoom
    @State private var canvasScale: CGFloat = 1.0
    @State private var lastCanvasScale: CGFloat = 1.0

    // MARK: Image editing
    @State private var imageScale: CGFloat = 1.0
    @State private var lastImageScale: CGFloat = 1.0
    @State private var imageOffset: CGSize = .zero
    @State private var lastImageOffset: CGSize = .zero
    @State private var imageRotation: Angle = .zero
    @State private var lastImageRotation: Angle = .zero

    // MARK: Body

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
        .navigationTitle(truncatedTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let onDismiss {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { onDismiss() }
                        .fontWeight(.semibold)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    EditPolaroidView(polaroid: polaroid, store: store)
                        .navigationBarBackButtonHidden(true)
                } label: {
                    Text("Edit")
                        .fontWeight(.semibold)
                }
            }
        }
        .confirmationDialog(
            "Delete this polaroid?",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                store.delete(polaroid)
                if let onDismiss { onDismiss() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This evidence cannot be recovered after deletion.")
        }
        .sheet(item: $shareItem) { item in
            ShareSheet(items: [item.image]) {
                shareItem = nil
            }
        }
        .alert("Photos", isPresented: $showingSaveAlert) {
            Button("OK") {}
        } message: {
            Text(saveAlertMessage)
        }
    }

    // MARK: Title

    private var truncatedTitle: String {
        let trimmed = polaroid.caption.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Polaroid" }
        if trimmed.count <= 32 { return trimmed }
        return String(trimmed.prefix(30)) + "\u{2026}"
    }

    // MARK: Card constants

    private static let cardWidth: CGFloat = 328
    private static let cardHeight: CGFloat = 350
    private static let captionHeight: CGFloat = cardHeight * 0.2
    private static let imageHeight: CGFloat = cardHeight - captionHeight - 14

    // MARK: - Landscape layout

    private func landscapeLayout(geo: GeometryProxy) -> some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                ZStack {
                    polaroidCard
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
                    Slider(value: $canvasScale, in: 1.0...5.0)
                        .tint(.gray)
                        .onChange(of: canvasScale) { _, newValue in
                            lastCanvasScale = newValue
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
                VStack(alignment: .leading, spacing: 16) {
                    metadataColumn
                    actionColumn
                }
                .padding(20)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Portrait layout

    private var portraitLayout: some View {
        ScrollView {
            VStack(spacing: 24) {
                polaroidHero
                metadataCard
                actionButtons
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
    }

    // MARK: Polaroid card

    @ViewBuilder
    private var polaroidCard: some View {
        if let uiImage = UIImage(data: polaroid.imageData) {
            VStack(spacing: 0) {
                Image(uiImage: uiImage)
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

                Text(polaroid.caption.isEmpty ? "Untitled" : polaroid.caption)
                    .font(.custom("Impact", size: 15))
                    .tracking(0.5)
                    .lineLimit(1...3)
                    .foregroundStyle(polaroid.caption.isEmpty ? .secondary : .primary)
                    .padding(.horizontal, 18)
                    .frame(height: Self.captionHeight)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: Self.cardWidth, height: Self.cardHeight)
            .background(Color(white: 0.96))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .shadow(color: .black.opacity(0.25), radius: 16, x: 0, y: 8)
            .scaleEffect(canvasScale)
        }
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

    // MARK: Metadata column (landscape right side)

    private var metadataColumn: some View {
        VStack(alignment: .leading, spacing: 10) {
            metadataRow("Category", value: polaroid.category.displayName, tint: polaroid.category.tintColor)
            if let flight = polaroid.flightNumber, !flight.isEmpty {
                metadataRow("Flight", value: flight, monospaced: true)
            }
            if let route = polaroid.route, !route.isEmpty {
                metadataRow("Route", value: route, monospaced: true)
            }
            if let seat = polaroid.seatLocation, !seat.isEmpty {
                metadataRow("Seat / location", value: seat)
            }
            metadataRow("Captured", value: polaroid.capturedAt.formatted(date: .abbreviated, time: .shortened))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    // MARK: Action column (landscape right side)

    private var actionColumn: some View {
        VStack(spacing: 10) {
            Button {
                saveToPhotos()
            } label: {
                Label("Open in Photos", systemImage: "photo.on.rectangle")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button {
                shareFlattenedPolaroid()
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button(role: .destructive) {
                showingDeleteConfirm = true
            } label: {
                Label("Delete", systemImage: "trash")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
    }

    // MARK: Portrait hero

    private var polaroidHero: some View {
        HStack {
            Spacer()
            PolaroidCardView(model: PolaroidCardView.Model(polaroid: polaroid))
                .frame(width: 360, height: 287)
            Spacer()
        }
        .padding(.vertical, 12)
        .onTapGesture(count: 2) { }
    }

    // MARK: Portrait metadata card

    private var metadataCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            row("Category", value: polaroid.category.displayName, tint: polaroid.category.tintColor)
            if let flight = polaroid.flightNumber, !flight.isEmpty {
                row("Flight", value: flight, monospaced: true)
            }
            if let route = polaroid.route, !route.isEmpty {
                row("Route", value: route, monospaced: true)
            }
            if let seat = polaroid.seatLocation, !seat.isEmpty {
                row("Seat / location", value: seat)
            }
            row("Captured", value: polaroid.capturedAt.formatted(date: .abbreviated, time: .shortened))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    // MARK: Portrait action buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                saveToPhotos()
            } label: {
                Label("Open in Photos", systemImage: "photo.on.rectangle")
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button {
                shareFlattenedPolaroid()
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button(role: .destructive) {
                showingDeleteConfirm = true
            } label: {
                Label("Delete", systemImage: "trash")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
    }

    // MARK: Row helpers

    @ViewBuilder
    private func row(_ label: String, value: String, tint: Color? = nil, monospaced: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            HStack(spacing: 8) {
                if let tint {
                    Circle().fill(tint).frame(width: 8, height: 8)
                }
                Text(value)
                    .font(monospaced ? .subheadline.monospaced().weight(.medium) : .subheadline.weight(.medium))
                    .foregroundStyle(EvidenceTheme.brandNavy)
            }
        }
    }

    @ViewBuilder
    private func metadataRow(_ label: String, value: String, tint: Color? = nil, monospaced: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
            HStack(spacing: 6) {
                if let tint {
                    Circle().fill(tint).frame(width: 7, height: 7)
                }
                Text(value)
                    .font(monospaced ? .caption.monospaced().weight(.medium) : .caption.weight(.medium))
                    .foregroundStyle(EvidenceTheme.brandNavy)
            }
        }
    }

    // MARK: Share flattened polaroid

    private func shareFlattenedPolaroid() {
        let model = PolaroidCardView.Model(polaroid: polaroid)
        guard let rendered = PolaroidCardView.renderToImage(model: model) else { return }
        shareItem = ShareableImage(image: rendered)
    }

    // MARK: Save to Photos

    private func saveToPhotos() {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async {
                    saveAlertMessage = "Photo library access is required. Please enable it in Settings."
                    showingSaveAlert = true
                }
                return
            }
            PHPhotoLibrary.shared().performChanges {
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .photo, data: polaroid.imageData, options: nil)
            } completionHandler: { success, _ in
                DispatchQueue.main.async {
                    saveAlertMessage = success ? "Saved to photo library." : "Could not save photo."
                    showingSaveAlert = true
                }
            }
        }
    }
}

// MARK: - ShareableImage

private struct ShareableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}
#endif
