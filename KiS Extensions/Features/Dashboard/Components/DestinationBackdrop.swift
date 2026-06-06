import SwiftUI
import UIKit

// MARK: - Destination Backdrop

/// Background panel for the duty card centre. Shows a city skyline photo when a
/// matching asset exists, otherwise falls back to a premium navy gradient with a
/// subtle aircraft motif. Add photos to the asset catalog named
/// `skyline-<code>` (lowercase station code, e.g. `skyline-khi`).
struct DestinationBackdrop: View {
    let code: String

    private var assetName: String { "skyline-\(code.lowercased())" }
    private var hasPhoto: Bool { UIImage(named: assetName) != nil }

    var body: some View {
        ZStack {
            if hasPhoto {
                Image(assetName)
                    .resizable()
                    .scaledToFill()
                LinearGradient(colors: [.black.opacity(0.15), .black.opacity(0.55)],
                               startPoint: .top, endPoint: .bottom)
            } else {
                LinearGradient(colors: [Color(red: 0.07, green: 0.20, blue: 0.40),
                                        Color(red: 0.02, green: 0.10, blue: 0.24)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                Image(systemName: "building.2.crop.circle")
                    .font(.system(size: 70, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.10))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    HStack {
        DestinationBackdrop(code: "KHI")
        DestinationBackdrop(code: "DXB")
    }
    .frame(height: 150)
    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    .padding()
}
