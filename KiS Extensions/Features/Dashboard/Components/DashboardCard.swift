import SwiftUI

// MARK: - Dashboard Card

/// Core-operations card. Left-aligned, layered surface with an accent icon
/// badge, a faint SF Symbol watermark, and optional live operational metadata.
struct DashboardCard: View {
    let title: String
    let description: String
    let systemImage: String
    let accent: Color
    var metadata: String? = nil   // primary live metric, e.g. "12 saved trips"
    var detail: String? = nil     // secondary context, e.g. "Next: EK241 DXB-LHR"
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    IconBadge(systemImage: systemImage, accent: accent, size: 40)
                    Spacer(minLength: AppSpacing.sm)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppColor.textTertiary)
                }

                Spacer(minLength: AppSpacing.lg)

                Text(title)
                    .font(.dashCardTitle)
                    .foregroundStyle(AppColor.textPrimary)

                Text(description)
                    .font(.dashBody)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)

                if metadata != nil || detail != nil {
                    Divider()
                        .overlay(AppColor.separator)
                        .padding(.vertical, AppSpacing.md)

                    if let metadata {
                        Text(metadata)
                            .font(.dashCardMetric)
                            .foregroundStyle(accent)
                    }
                    if let detail {
                        Text(detail)
                            .font(.dashMetadata)
                            .foregroundStyle(AppColor.textSecondary)
                            .lineLimit(1)
                            .padding(.top, metadata == nil ? 0 : 2)
                    }
                }
            }
            .padding(AppSpacing.xl)
            .frame(maxWidth: .infinity, minHeight: 168, alignment: .leading)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                        .fill(AppColor.surfaceElevated)
                    RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                        .fill(LinearGradient(
                            colors: [accent.opacity(0.10), .clear],
                            startPoint: .topLeading, endPoint: .center))
                    Image(systemName: systemImage)
                        .font(.system(size: 124, weight: .semibold))
                        .foregroundStyle(accent.opacity(0.06))
                        .offset(x: 34, y: 40)
                }
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            }
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .strokeBorder(AppColor.border, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.10), radius: 14, x: 0, y: 8)
        }
        .buttonStyle(CardPressStyle())
    }
}

// MARK: - Preview

#Preview {
    let columns = [GridItem(.flexible(), spacing: AppSpacing.lg),
                   GridItem(.flexible(), spacing: AppSpacing.lg)]
    return LazyVGrid(columns: columns, spacing: AppSpacing.lg) {
        DashboardCard(title: "Flight Planner",
                      description: "Browse saved trips and sectors",
                      systemImage: "calendar.day.timeline.leading",
                      accent: AppColor.accent(for: .flightPlanner),
                      metadata: "12 saved trips",
                      detail: "Next: EK241 DXB-LHR") {}
        DashboardCard(title: "EK Crew Rest",
                      description: "Service and rest schedule calculator",
                      systemImage: "bed.double",
                      accent: AppColor.accent(for: .ekCrewRest)) {}
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppColor.background)
}
