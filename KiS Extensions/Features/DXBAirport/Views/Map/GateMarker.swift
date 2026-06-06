import SwiftUI

// MARK: - Gate Marker

/// Tappable dot for a single bay/gate on the schematic map. Color encodes
/// type (contact/remote/closed); inner ring marks A380 capability; stroke
/// marks biometric boarding.
struct GateMarker: View {
    let bay: Bay
    let position: CGPoint
    let onTap: (Bay) -> Void

    var body: some View {
        Button {
            onTap(bay)
        } label: {
            ZStack {
                if bay.isA380Capable {
                    Circle()
                        .stroke(Color.indigo.opacity(0.7), lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                }
                Circle()
                    .fill(fillColor)
                    .frame(width: 14, height: 14)
                    .overlay(
                        Circle()
                            .stroke(Color.purple, lineWidth: bay.biometricBoarding ? 2 : 0)
                    )
            }
            .contentShape(Circle().size(width: 30, height: 30))
        }
        .buttonStyle(.plain)
        .position(position)
    }

    private var fillColor: Color {
        if bay.operationalStatus == .closed { return .red }
        if bay.isContact { return .blue }
        return .orange
    }
}
