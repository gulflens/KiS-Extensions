import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

// MARK: - EditPolaroidView

#if canImport(UIKit)
struct EditPolaroidView: View {

    // MARK: Inputs

    let polaroid: PolaroidEvidence
    let store: PolaroidEvidenceStore

    // MARK: Environment

    @Environment(\.dismiss) private var dismiss
    @Query private var settingsArray: [AppSettings]

    private var autoSave: Bool {
        settingsArray.first?.polaroidAutoSave ?? true
    }

    // MARK: State

    @State private var metadata: PolaroidMetadata
    @State private var image: UIImage?
    @FocusState private var captionFocused: Bool

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

    // MARK: Card constants

    private static let cardWidth: CGFloat = 328
    private static let cardHeight: CGFloat = 350
    private static let captionHeight: CGFloat = cardHeight * 0.2
    private static let imageHeight: CGFloat = cardHeight - captionHeight - 14

    // MARK: Init

    init(polaroid: PolaroidEvidence, store: PolaroidEvidenceStore) {
        self.polaroid = polaroid
        self.store = store
        _metadata = State(initialValue: PolaroidMetadata(
            caption: polaroid.caption,
            category: polaroid.category,
            flightNumber: polaroid.flightNumber,
            route: polaroid.route,
            seatLocation: polaroid.seatLocation,
            capturedAt: polaroid.capturedAt,
            aspectMode: polaroid.aspectMode
        ))
        _image = State(initialValue: UIImage(data: polaroid.imageData))
    }

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
        .navigationTitle("Edit polaroid")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Done") {
                    if !autoSave && metadata.isReady {
                        store.updateMetadata(polaroid, metadata: metadata)
                    }
                    dismiss()
                }
                .fontWeight(.semibold)
            }
            ToolbarItem(placement: .topBarTrailing) {
                if autoSave {
                    Text("Auto-save")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onChange(of: metadata) { _, newValue in
            if autoSave && newValue.isReady {
                store.updateMetadata(polaroid, metadata: newValue)
            }
        }
    }

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

    // MARK: - Portrait layout

    private var portraitLayout: some View {
        ScrollView {
            VStack(spacing: 24) {
                polaroidCardPortrait

                field("Seat / location") {
                    TextField("3K or Galley 2", text: bindingForOptional(\.seatLocation))
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal, 40)

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

    // MARK: Polaroid card (landscape)

    @ViewBuilder
    private var polaroidCard: some View {
        if let image {
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
            .scaleEffect(canvasScale)
        }
    }

    // MARK: Polaroid card (portrait)

    @ViewBuilder
    private var polaroidCardPortrait: some View {
        if let image {
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
