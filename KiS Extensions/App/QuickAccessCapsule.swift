import SwiftUI

// MARK: - Quick Access Capsule

/// Full-width bar pinned to the bottom of the dashboard. Each shortcut shows
/// its feature icon above a text label. The surface spans edge to edge and
/// extends under the home indicator (ignoring the bottom safe area); a top
/// hairline separates it from the content above.
struct QuickAccessCapsule: View {
    var onOpen: (FeatureID) -> Void

    private let shortcuts: [FeatureID] = [
        .flightPlanner,
        .allocatePositions,
        .timeConverter,
        .dxbAirport,
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
        .padding(.top, AppSpacing.sm)
        .padding(.bottom, AppSpacing.xs)
        .frame(maxWidth: .infinity)
        .background(
            AppColor.surface
                .ignoresSafeArea(edges: .bottom)
        )
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppColor.border)
                .frame(height: 1)
        }
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
