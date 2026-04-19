import SwiftUI

// MARK: - DXB Schematic Map View

/// Pan/zoom schematic of DXB Airport. Shows concourses, transit lines,
/// runways, gate dots, lounge markers, and an optional `PlannedRoute`
/// overlay. Gate positions are approximate — see `Documentation/DXBAirport/GAPS.md`.
struct DXBSchematicMapView: View {
    let route: PlannedRoute?

    @Environment(DXBDataStore.self) private var dataStore
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var selectedBay: Bay?
    @State private var selectedLounge: Lounge?

    private var layout: DXBSchematicLayout { dataStore.mapLayout }

    var body: some View {
        VStack(spacing: 0) {
            schematicBanner
            mapBody
        }
        .navigationTitle("Airport map")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    resetView()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                }
            }
        }
        .sheet(item: $selectedBay) { bay in
            BayDetailSheet(bay: bay)
        }
        .sheet(item: $selectedLounge) { lounge in
            NavigationStack {
                LoungeDetailView(lounge: lounge)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { selectedLounge = nil }
                        }
                    }
            }
        }
    }

    // MARK: - Banner

    private var schematicBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
                .foregroundStyle(.orange)
            Text("Schematic only — gate positions are approximate, not surveyed.")
                .font(.caption)
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.10))
    }

    // MARK: - Map body

    private var mapBody: some View {
        GeometryReader { geo in
            let initialScale = min(
                geo.size.width / DXBSchematicLayout.displayedSize.width,
                geo.size.height / DXBSchematicLayout.displayedSize.height
            )
            let effectiveScale = initialScale * scale

            ZStack {
                Color(.systemGroupedBackground)

                ZStack {
                    ZStack {
                        ConcoursesLayer()

                        ForEach(dataStore.catalog.bays) { bay in
                            if let pos = layout.bayPositions[bay.bayId] {
                                GateMarker(bay: bay, position: pos) { tappedBay in
                                    selectedBay = tappedBay
                                }
                            }
                        }

                        if scale >= Self.labelVisibilityThreshold {
                            ForEach(dataStore.catalog.bays) { bay in
                                if let pos = layout.bayPositions[bay.bayId] {
                                    gateLabel(
                                        bay: bay,
                                        at: pos,
                                        offset: layout.bayLabelOffsets[bay.bayId]
                                            ?? CGSize(width: -22, height: 0)
                                    )
                                }
                            }
                        }

                        ForEach(dataStore.lounges) { lounge in
                            if let pos = layout.loungePositions[lounge.id] {
                                LoungeMarker(lounge: lounge, position: pos) { tappedLounge in
                                    selectedLounge = tappedLounge
                                }
                            }
                        }

                        if let route {
                            RouteOverlay(route: route, layout: layout)
                        }
                    }
                    .frame(
                        width: DXBSchematicLayout.canvasSize.width,
                        height: DXBSchematicLayout.canvasSize.height
                    )
                    .rotationEffect(.degrees(DXBSchematicLayout.rotationDegrees))
                }
                .frame(
                    width: DXBSchematicLayout.displayedSize.width,
                    height: DXBSchematicLayout.displayedSize.height
                )
                .scaleEffect(effectiveScale)
                .offset(offset)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
            .contentShape(Rectangle())
            .gesture(
                SimultaneousGesture(
                    MagnifyGesture()
                        .onChanged { value in
                            let newScale = max(0.4, min(4.0, lastScale * value.magnification))
                            scale = newScale
                            offset = clamp(
                                offset: offset,
                                effectiveScale: initialScale * newScale,
                                viewport: geo.size
                            )
                        }
                        .onEnded { _ in
                            lastScale = scale
                            lastOffset = offset
                        },
                    DragGesture()
                        .onChanged { value in
                            let proposed = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                            offset = clamp(
                                offset: proposed,
                                effectiveScale: effectiveScale,
                                viewport: geo.size
                            )
                        }
                        .onEnded { _ in
                            lastOffset = offset
                        }
                )
            )
            .onChange(of: geo.size) { _, newSize in
                offset = clamp(
                    offset: offset,
                    effectiveScale: initialScale * scale,
                    viewport: newSize
                )
                lastOffset = offset
            }
        }
    }

    // MARK: - Pan clamp

    /// Restricts pan offset so the scaled map's edges cannot move past the
    /// viewport edges. When the drawn map is smaller than the viewport on an
    /// axis, the offset on that axis snaps to 0 (centered).
    private func clamp(offset: CGSize, effectiveScale: CGFloat, viewport: CGSize) -> CGSize {
        let drawnWidth = DXBSchematicLayout.displayedSize.width * effectiveScale
        let drawnHeight = DXBSchematicLayout.displayedSize.height * effectiveScale
        let maxX = max(0, (drawnWidth - viewport.width) / 2)
        let maxY = max(0, (drawnHeight - viewport.height) / 2)
        return CGSize(
            width: min(maxX, max(-maxX, offset.width)),
            height: min(maxY, max(-maxY, offset.height))
        )
    }

    // MARK: - Gate label (zoom-conditional)

    /// Threshold on the user-controlled `scale` (multiplier on top of the
    /// fit-to-screen base scale) above which gate id labels appear.
    private static let labelVisibilityThreshold: CGFloat = 1.3

    private func gateLabel(bay: Bay, at point: CGPoint, offset: CGSize) -> some View {
        let labelText = bay.gateId ?? bay.bayId
        return Text(labelText)
            .font(.system(size: 9, weight: .bold).monospaced())
            .foregroundStyle(.primary)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(.regularMaterial, in: Capsule())
            .position(x: point.x + offset.width, y: point.y + offset.height)
            .allowsHitTesting(false)
    }

    // MARK: - Reset

    private func resetView() {
        withAnimation(.easeInOut(duration: 0.25)) {
            scale = 1.0
            lastScale = 1.0
            offset = .zero
            lastOffset = .zero
        }
    }
}
