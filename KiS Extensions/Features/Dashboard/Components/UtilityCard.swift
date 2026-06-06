import SwiftUI

// MARK: - Utility Card

/// Lower-emphasis card for utility mini-apps. Compact horizontal layout.
struct UtilityCard: View {
    let title: String
    let description: String
    let systemImage: String
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                IconBadge(systemImage: systemImage, accent: accent, size: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppColor.textPrimary)
                    Text(description)
                        .font(.system(size: 12.5, weight: .regular))
                        .foregroundStyle(AppColor.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: AppSpacing.sm)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColor.textTertiary)
            }
            .padding(AppSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .dashboardCard(radius: AppRadius.panel, elevated: false)
        }
        .buttonStyle(CardPressStyle())
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: AppSpacing.md) {
        UtilityCard(title: "DXB Airport",
                    description: "Search bays, gates, and lounges",
                    systemImage: "airplane.departure",
                    accent: AppColor.accent(for: .dxbAirport)) {}
        UtilityCard(title: "Polaroid Evidence",
                    description: "Capture cabin evidence",
                    systemImage: "camera.viewfinder",
                    accent: AppColor.accent(for: .polaroidEvidence)) {}
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppColor.background)
}
