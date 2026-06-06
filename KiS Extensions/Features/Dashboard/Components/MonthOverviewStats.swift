import SwiftUI

// MARK: - Month Overview Stats

/// Compact strip of month-to-date operational metrics. Every value is derived
/// from real planned-sector data by `OperationalContext.MonthSummary`.
struct MonthOverviewStats: View {
    let summary: OperationalContext.MonthSummary
    var isRegular: Bool = true

    private struct Stat: Identifiable {
        let id = UUID()
        let value: String
        let label: String
        let systemImage: String
        let accent: Color
    }

    private var stats: [Stat] {
        [
            .init(value: summary.blockHoursLabel, label: "Block Hours",
                  systemImage: "clock", accent: AppColor.info),
            .init(value: "\(summary.sectorsFlown)", label: "Sectors Flown",
                  systemImage: "airplane", accent: AppColor.positive),
            .init(value: "\(summary.dutyDays)", label: "Duty Days",
                  systemImage: "calendar", accent: AppColor.gold),
            .init(value: "\(summary.layovers)", label: "Layovers",
                  systemImage: "bed.double", accent: AppColor.navyAccent),
        ]
    }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: AppSpacing.md),
              count: isRegular ? 4 : 2)
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: AppSpacing.md) {
            ForEach(stats) { stat in
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    ZStack {
                        Circle().fill(stat.accent.opacity(0.15))
                        Image(systemName: stat.systemImage)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(stat.accent)
                    }
                    .frame(width: 38, height: 38)
                    Text(stat.value)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColor.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(stat.label)
                        .font(.dashMicroLabel)
                        .tracking(0.5)
                        .foregroundStyle(AppColor.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AppSpacing.lg)
                .dashboardCard(radius: AppRadius.panel, elevated: false)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MonthOverviewStats(summary: .init(
        monthLabel: "May 2026", blockHours: 26.67,
        sectorsFlown: 5, dutyDays: 8, layovers: 2))
    .padding(AppSpacing.xxl)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppColor.background)
}
