import SwiftUI

// MARK: - Quick Action

/// A single quick-action shortcut on the dashboard.
struct QuickAction: Identifiable {
    let id = UUID()
    let title: String
    let systemImage: String
    let accent: Color
    let action: () -> Void
}

// MARK: - Quick Actions Row

/// Horizontal row of large-touch-target shortcuts to common operations.
/// Wraps to a grid on compact width so targets stay comfortable one-handed.
struct QuickActionsRow: View {
    let actions: [QuickAction]
    var isRegular: Bool = true

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: AppSpacing.md),
              count: isRegular ? 4 : 2)
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: AppSpacing.md) {
            ForEach(actions) { action in
                Button(action: action.action) {
                    tile(action)
                }
                .buttonStyle(CardPressStyle())
            }
        }
    }

    private func tile(_ action: QuickAction) -> some View {
        VStack(spacing: AppSpacing.sm) {
            IconBadge(systemImage: action.systemImage, accent: action.accent, size: 42)
            Text(action.title)
                .font(.dashMetadata)
                .foregroundStyle(AppColor.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.lg)
        .padding(.horizontal, AppSpacing.sm)
        .dashboardCard(radius: AppRadius.panel, elevated: false)
    }
}

// MARK: - Preview

#Preview {
    QuickActionsRow(actions: [
        .init(title: "Rest Calculator", systemImage: "bed.double",
              accent: AppColor.critical, action: {}),
        .init(title: "DXB Airport", systemImage: "airplane.departure",
              accent: AppColor.info, action: {}),
        .init(title: "Time Converter", systemImage: "clock.arrow.2.circlepath",
              accent: AppColor.positive, action: {}),
        .init(title: "Crew Checklist", systemImage: "phone.connection",
              accent: AppColor.navyAccent, action: {}),
    ])
    .padding(AppSpacing.xxl)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppColor.background)
}
