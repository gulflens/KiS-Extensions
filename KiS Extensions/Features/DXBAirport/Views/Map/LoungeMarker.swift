import SwiftUI

// MARK: - Lounge Marker

/// Tappable lounge marker on the schematic map. Anchored beneath the nearest
/// gate dot via `DXBSchematicLayout.loungePositions`. Sofa symbol on a gold
/// circle so it reads distinct from gate dots.
struct LoungeMarker: View {
    let lounge: Lounge
    let position: CGPoint
    let onTap: (Lounge) -> Void

    var body: some View {
        Button {
            onTap(lounge)
        } label: {
            Image(systemName: "sofa.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(
                    Circle()
                        .fill(Color(red: 0xB8/255, green: 0x86/255, blue: 0x0B/255))
                )
                .overlay(
                    Circle().stroke(Color.white, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
        .position(position)
    }
}
