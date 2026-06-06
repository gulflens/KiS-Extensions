import SwiftUI

// MARK: - Next Flight Panel

/// Detail card for the next departing sector: a countdown headline followed by
/// the operational facts that have real backing data. Pure presentation.
struct NextFlightPanel: View {
    let next: DashboardFlightResolver.NextFlight?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.forward.circle")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColor.info)
                Text("Next Flight".uppercased())
                    .font(.dashMicroLabel)
                    .tracking(1.0)
                    .foregroundStyle(AppColor.textSecondary)
            }

            if let next {
                content(next)
            } else {
                emptyState
            }
        }
        .padding(AppSpacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard()
    }

    private func content(_ next: DashboardFlightResolver.NextFlight) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Countdown headline
            VStack(alignment: .leading, spacing: 1) {
                Text(next.countdownLabel)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColor.textPrimary)
                Text("until \(next.flightNumber)")
                    .font(.dashMetadata)
                    .foregroundStyle(AppColor.textSecondary)
            }

            Divider().overlay(AppColor.separator)

            detailRow("Route", next.route)
            detailRow("Departs", next.std)
            detailRow("Arrives", next.sta)
            if let registration = next.registration {
                detailRow("Aircraft", registration)
            }
            detailRow("Date", "\(next.dateLabel) · \(next.relativeLabel)")
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.dashMetadata)
                .foregroundStyle(AppColor.textSecondary)
            Spacer()
            Text(value)
                .font(.dashMono)
                .foregroundStyle(AppColor.textPrimary)
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("No next flight")
                .font(.dashBody)
                .foregroundStyle(AppColor.textPrimary)
            Text("Add a trip in Flight Planner.")
                .font(.dashMetadata)
                .foregroundStyle(AppColor.textSecondary)
        }
        .padding(.vertical, AppSpacing.sm)
    }
}

// MARK: - Preview

#Preview {
    NextFlightPanel(next: .init(
        id: UUID(), flightNumber: "EK0622", route: "DXB → LHR",
        std: "STD 22:00", sta: "STA 02:30", dateLabel: "Wed 21 May",
        relativeLabel: "Today", registration: "A6-ENV", countdownLabel: "5h 50m"))
    .padding(AppSpacing.xxl)
    .frame(maxWidth: 360)
    .background(AppColor.background)
}
