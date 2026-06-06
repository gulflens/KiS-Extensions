import SwiftUI

// MARK: - Operational Hero Card

/// Primary operational focus of the dashboard: the current or next flight.
/// Renders on a constant deep-navy surface in both appearances.
struct OperationalHeroCard: View {

    // MARK: Flight Model

    /// Display-ready snapshot of the active sector. Built by the dashboard's
    /// data layer; this view performs no calculation.
    struct Flight {
        let flightNumber: String
        let departureCode: String
        let arrivalCode: String
        let departureCity: String?
        let arrivalCity: String?
        let std: String              // scheduled departure, "HH:mm"
        let sta: String              // scheduled arrival, "HH:mm"
        let phaseLabel: String       // "Scheduled" / "Boarding" / "En route" / "Landed"
        let countdownLabel: String   // "Departs in 4h 12m" / "In progress"
        let registration: String?
        let nextMilestone: String?   // optional next operational step
        let progress: Double         // 0...1 sector completion (0 before departure)
        let ringTop: String          // ring center, e.g. "5h 08m"
        let ringBottom: String       // ring caption, e.g. "remaining" / "to departure"
        let sectorPosition: String?  // "Sector 2 of 4"
        let blockTime: String        // scheduled block, e.g. "5h 00m"
        let timeDiff: String         // station offset, e.g. "+1h"
    }

    let flight: Flight?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xl) {
            header
            if let flight {
                content(flight)
            } else {
                emptyState
            }
        }
        .padding(AppSpacing.xxl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .fill(AppColor.heroGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .strokeBorder(.white.opacity(0.07), lineWidth: 1)
        )
        .overlay(alignment: .topTrailing) {
            Image(systemName: "airplane")
                .font(.system(size: 150, weight: .semibold))
                .foregroundStyle(.white.opacity(0.04))
                .rotationEffect(.degrees(-12))
                .offset(x: 36, y: -22)
                .clipped()
        }
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .shadow(color: .black.opacity(0.20), radius: 18, x: 0, y: 10)
    }

    // MARK: Header

    private var header: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "airplane.departure")
                    .font(.system(size: 11, weight: .bold))
                Text("Current Duty")
                    .font(.dashMicroLabel)
                    .tracking(1.1)
            }
            .foregroundStyle(AppColor.gold)

            Spacer()

            if let flight {
                StatusChip(text: flight.phaseLabel, systemImage: "dot.radiowaves.up.forward",
                           tint: AppColor.gold, style: .soft)
            }
        }
    }

    // MARK: Content

    private func content(_ flight: Flight) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            // Flight number + registration + sector position
            HStack(alignment: .firstTextBaseline, spacing: AppSpacing.sm) {
                Text(flight.flightNumber)
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppColor.textOnNavy)
                if let registration = flight.registration {
                    Text(registration)
                        .font(.dashMono)
                        .foregroundStyle(AppColor.textOnNavySecondary)
                }
                Spacer()
                if let sectorPosition = flight.sectorPosition {
                    Text(sectorPosition)
                        .font(.dashMicroLabel)
                        .tracking(0.6)
                        .foregroundStyle(AppColor.textOnNavySecondary)
                }
            }

            routeView(flight)
            statTiles(flight)

            Divider().overlay(.white.opacity(0.10))

            // Status line
            HStack(alignment: .center, spacing: AppSpacing.lg) {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppColor.gold)
                Text(flight.countdownLabel)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColor.textOnNavy)
                Spacer()
            }
        }
    }

    // MARK: Route Visualization

    private func routeView(_ flight: Flight) -> some View {
        HStack(alignment: .center, spacing: AppSpacing.md) {
            endpoint(code: flight.departureCode, city: flight.departureCity,
                     time: flight.std, label: "STD", alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            ZStack {
                DestinationBackdrop(code: flight.arrivalCode)
                DutyProgressRing(progress: flight.progress,
                                 centerTop: flight.ringTop,
                                 centerBottom: flight.ringBottom,
                                 diameter: 118, lineWidth: 8)
                    .padding(6)
            }
            .frame(width: 150, height: 138)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.panel, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.panel, style: .continuous)
                    .strokeBorder(.white.opacity(0.12), lineWidth: 1)
            )

            endpoint(code: flight.arrivalCode, city: flight.arrivalCity,
                     time: flight.sta, label: "STA", alignment: .trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    // MARK: Stat Tiles

    private func statTiles(_ flight: Flight) -> some View {
        HStack(spacing: AppSpacing.sm) {
            statTile(icon: "clock", label: "Block", value: flight.blockTime)
            statTile(icon: "globe", label: "Time Diff", value: flight.timeDiff)
            statTile(icon: "airplane", label: "Aircraft",
                     value: flight.registration ?? "—")
        }
    }

    private func statTile(icon: String, label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .bold))
                Text(label.uppercased())
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(0.6)
            }
            .foregroundStyle(AppColor.textOnNavySecondary)
            Text(value)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColor.textOnNavy)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, AppSpacing.sm)
        .padding(.horizontal, AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.chip, style: .continuous)
                .fill(.white.opacity(0.07))
        )
    }

    private func endpoint(code: String, city: String?, time: String,
                          label: String, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 1) {
            Text(code)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(AppColor.textOnNavy)
            if let city {
                Text(city)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppColor.textOnNavySecondary)
                    .lineLimit(1)
            }
            Text("\(label) \(time)")
                .font(.dashMono)
                .foregroundStyle(AppColor.gold)
                .padding(.top, 3)
        }
    }

    // MARK: Empty State

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Image(systemName: "airplane.circle")
                .font(.system(size: 38, weight: .light))
                .foregroundStyle(AppColor.gold.opacity(0.8))
                .padding(.bottom, 2)
            Text("No upcoming flight")
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(AppColor.textOnNavy)
            Text("Add a trip in Flight Planner and it will appear here.")
                .font(.dashBody)
                .foregroundStyle(AppColor.textOnNavySecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, AppSpacing.sm)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: AppSpacing.lg) {
            OperationalHeroCard(flight: .init(
                flightNumber: "EK241",
                departureCode: "DXB", arrivalCode: "LHR",
                departureCity: "Dubai", arrivalCity: "London",
                std: "02:15", sta: "07:40",
                phaseLabel: "En route",
                countdownLabel: "Lands in 3h 05m",
                registration: "A6-EWJ",
                nextMilestone: "Meal service",
                progress: 0.42, ringTop: "3h 05m", ringBottom: "remaining",
                sectorPosition: "Sector 2 of 4", blockTime: "7h 25m", timeDiff: "-3h"))

            OperationalHeroCard(flight: nil)
        }
        .padding()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppColor.background)
}
