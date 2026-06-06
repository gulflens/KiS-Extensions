import SwiftUI

// MARK: - App Top Bar

/// Minimal chrome shown only when a mini-app is open over the dashboard.
/// Hosts the back affordance and feature title.
struct AppTopBar: View {
    let featureTitle: String
    var onBack: () -> Void

    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isRegular: Bool { sizeClass == .regular }

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Button(action: onBack) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                    Text(featureTitle)
                        .font(.dashCardTitle)
                        .lineLimit(1)
                }
                .foregroundStyle(AppColor.navyAccent)
            }
            .buttonStyle(.plain)
            Spacer(minLength: AppSpacing.sm)
        }
        .padding(.horizontal, isRegular ? AppSpacing.xl : AppSpacing.lg)
        .padding(.vertical, AppSpacing.sm)
        .background(AppColor.surface)
    }
}
