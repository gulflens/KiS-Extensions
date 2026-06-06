import SwiftUI

// MARK: - Quick Access Capsule

/// Floating pill-shaped quick-access bar shown above the bottom safe area on
/// the dashboard. Each shortcut shows its feature icon above a text label.
/// Pure shortcuts: no active state since the dashboard is the implied page.
struct QuickAccessCapsule: View {
    var onOpen: (FeatureID) -> Void

    private let shortcuts: [FeatureID] = [
        .flightPlanner,
        .allocatePositions,
        .timeConverter,
        .settings,
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(shortcuts, id: \.self) { id in
                let module = FeatureRegistry.module(for: id)
                item(title: module.title,
                     systemImage: module.icon,
                     accent: AppColor.accent(for: id)) {
                    onOpen(id)
                }
            }
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.sm)
        .background(
            Capsule(style: .continuous)
                .fill(AppColor.surfaceElevated)
        )
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(AppColor.border, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 6)
        .padding(.horizontal, AppSpacing.lg)
    }

    // MARK: - Item

    private func item(title: String,
                      systemImage: String,
                      accent: Color,
                      action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        Spacer()
        QuickAccessCapsule(onOpen: { _ in })
            .padding(.bottom, AppSpacing.lg)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppColor.background)
}
