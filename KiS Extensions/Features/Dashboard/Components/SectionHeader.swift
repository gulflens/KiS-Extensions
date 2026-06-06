import SwiftUI

// MARK: - Section Header

/// Lightweight heading that separates operational zones on the dashboard.
struct SectionHeader: View {
    let title: String
    var systemImage: String? = nil
    var trailingText: String? = nil

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColor.gold)
            }
            Text(title)
                .font(.dashSectionTitle)
                .tracking(0.6)
                .foregroundStyle(AppColor.textSecondary)

            Spacer(minLength: AppSpacing.sm)

            if let trailingText {
                Text(trailingText)
                    .font(.dashMicroLabel)
                    .foregroundStyle(AppColor.textTertiary)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(alignment: .leading, spacing: AppSpacing.xl) {
        SectionHeader(title: "Core Operations", systemImage: "square.grid.2x2")
        SectionHeader(title: "Utilities", systemImage: "wrench.adjustable", trailingText: "4 tools")
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppColor.background)
}
