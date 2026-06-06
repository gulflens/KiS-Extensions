import SwiftUI

// MARK: - Dashboard Support

/// Shared building blocks used across the dashboard component set.

// MARK: - Card Press Style

/// Subtle press feedback for tappable dashboard cards.
struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Icon Badge

/// Rounded, accent-tinted container for an SF Symbol.
struct IconBadge: View {
    let systemImage: String
    let accent: Color
    var size: CGFloat = 38

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(accent)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
                    .fill(accent.opacity(0.14))
            )
    }
}
