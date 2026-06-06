import SwiftUI

// MARK: - Route Overlay

/// Draws a `PlannedRoute` over the schematic map. Lines connect successive
/// segment endpoints (looked up via `DXBSchematicLayout.position(forId:)`).
/// Stub segments draw orange dashed; measured segments draw green solid.
/// Origin and destination get distinguishing markers.
struct RouteOverlay: View {
    let route: PlannedRoute
    let layout: DXBSchematicLayout

    var body: some View {
        ZStack {
            ForEach(route.segments) { segment in
                if let from = layout.position(forId: segment.fromId),
                   let to = layout.position(forId: segment.toId) {
                    Path { path in
                        path.move(to: from)
                        path.addLine(to: to)
                    }
                    .stroke(
                        segment.isStub ? Color.orange : Color.green,
                        style: StrokeStyle(
                            lineWidth: 5,
                            lineCap: .round,
                            dash: segment.isStub ? [10, 6] : []
                        )
                    )
                }
            }

            if let first = route.segments.first,
               let originPos = layout.position(forId: first.fromId) {
                endpointMarker(at: originPos, color: .green, symbol: "play.fill")
            }

            if let last = route.segments.last,
               let destPos = layout.position(forId: last.toId) {
                endpointMarker(at: destPos, color: .red, symbol: "flag.fill")
            }
        }
        .allowsHitTesting(false)
    }

    private func endpointMarker(at point: CGPoint, color: Color, symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 26, height: 26)
            .background(Circle().fill(color))
            .overlay(Circle().stroke(Color.white, lineWidth: 2))
            .position(point)
    }
}
