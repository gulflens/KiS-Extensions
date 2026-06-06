import SwiftUI

// MARK: - Month Calendar Strip

/// Compact month grid. Days that have at least one sector are dotted; today is
/// ringed. Pure presentation — the active days are resolved upstream.
struct MonthCalendarStrip: View {
    let referenceDate: Date
    let activeDays: Set<Date>   // start-of-day dates with sectors

    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = .dubai
        c.firstWeekday = 2 // Monday
        return c
    }

    private let weekdaySymbols = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: 0) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppColor.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                HStack(spacing: 0) {
                    ForEach(Array(week.enumerated()), id: \.offset) { _, day in
                        dayCell(day)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    // MARK: Day Cell

    @ViewBuilder
    private func dayCell(_ day: Date?) -> some View {
        if let day {
            let isToday = calendar.isDate(day, inSameDayAs: referenceDate)
            let isActive = activeDays.contains(calendar.startOfDay(for: day))
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: day))")
                    .font(.system(size: 13, weight: isToday ? .bold : .regular, design: .rounded))
                    .foregroundStyle(isToday ? AppColor.navyAccent : AppColor.textPrimary)
                Circle()
                    .fill(isActive ? AppColor.gold : .clear)
                    .frame(width: 5, height: 5)
            }
            .frame(height: 34)
            .frame(maxWidth: .infinity)
            .background {
                if isToday {
                    RoundedRectangle(cornerRadius: AppRadius.chip, style: .continuous)
                        .fill(AppColor.navyAccent.opacity(0.12))
                }
            }
        } else {
            Color.clear.frame(height: 34)
        }
    }

    // MARK: Grid

    /// The month laid out as weeks of 7 optional days (nil = padding).
    private var weeks: [[Date?]] {
        guard let interval = calendar.dateInterval(of: .month, for: referenceDate) else { return [] }
        let firstOfMonth = interval.start
        let dayCount = calendar.range(of: .day, in: .month, for: referenceDate)?.count ?? 30

        // Leading blanks before the first day, based on weekday.
        let weekday = calendar.component(.weekday, from: firstOfMonth)
        let leading = (weekday - calendar.firstWeekday + 7) % 7

        var cells: [Date?] = Array(repeating: nil, count: leading)
        for offset in 0..<dayCount {
            cells.append(calendar.date(byAdding: .day, value: offset, to: firstOfMonth))
        }
        while cells.count % 7 != 0 { cells.append(nil) }
        return stride(from: 0, to: cells.count, by: 7).map { Array(cells[$0..<$0 + 7]) }
    }
}

// MARK: - Preview

#Preview {
    let cal = Calendar.current
    let now = Date()
    MonthCalendarStrip(
        referenceDate: now,
        activeDays: Set([0, 1, 5, 12, 20].compactMap {
            cal.date(byAdding: .day, value: $0, to: cal.startOfDay(for: now))
        }))
    .padding(AppSpacing.xl)
    .frame(maxWidth: 360)
    .dashboardCard()
    .padding()
    .background(AppColor.background)
}
