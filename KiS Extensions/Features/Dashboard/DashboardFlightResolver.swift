import Foundation

// MARK: - Dashboard Flight Resolver

/// Pure logic that derives the dashboard's operational view of `PlannedSector`
/// data: the hero card's active flight and the upcoming-sector summary list.
/// Performs no persistence and no SwiftUI work — it is fully testable.
///
/// Time model: each sector stores a `date` plus `"HH:mm"` local departure and
/// arrival strings. The calendar day is taken from `date` (device calendar)
/// and the clock time is resolved in the relevant station's timezone. Sectors
/// whose arrival reads earlier than departure are treated as overnight.
enum DashboardFlightResolver {

    // MARK: - Upcoming Sector Summary

    struct UpcomingSector: Identifiable {
        let id: UUID
        let flightNumber: String
        let route: String           // "DXB - LHR"
        let dateLabel: String       // "Sat 17 May"
        let departureLabel: String  // "STD 02:15"
        let relativeLabel: String   // "Today" / "Tomorrow" / "in 3 days"
    }

    // MARK: - Hero Resolution

    /// The flight to feature: an in-progress sector if one exists, otherwise
    /// the next upcoming sector. Returns `nil` when no future sector exists.
    static func resolveHero(sectors: [PlannedSector], now: Date = .now) -> OperationalHeroCard.Flight? {
        let timed = sectors.compactMap { TimedSector(sector: $0) }

        if let active = timed
            .filter({ now >= $0.departure && now <= $0.arrival })
            .min(by: { $0.departure < $1.departure }) {
            return heroFlight(from: active, now: now, inProgress: true)
        }

        if let next = timed
            .filter({ $0.departure > now })
            .min(by: { $0.departure < $1.departure }) {
            return heroFlight(from: next, now: now, inProgress: false)
        }

        return nil
    }

    /// Up to `limit` sectors that have not yet landed, soonest first.
    static func upcoming(sectors: [PlannedSector], now: Date = .now, limit: Int = 3) -> [UpcomingSector] {
        sectors
            .compactMap { TimedSector(sector: $0) }
            .filter { $0.arrival >= now }
            .sorted { $0.departure < $1.departure }
            .prefix(limit)
            .map { ts in
                let s = ts.sector
                return UpcomingSector(
                    id: s.id,
                    flightNumber: s.flightNumber.isEmpty ? "Sector \(s.sectorIndex + 1)" : s.flightNumber,
                    route: "\(s.departureStation.uppercased()) - \(s.arrivalStation.uppercased())",
                    dateLabel: dayFormatter.string(from: ts.departure),
                    departureLabel: "STD \(s.departureTime)",
                    relativeLabel: relativeDay(to: ts.departure, now: now)
                )
            }
    }

    // MARK: - Next Flight Detail

    /// Detailed snapshot of the next sector that departs in the future.
    struct NextFlight: Identifiable {
        let id: UUID
        let flightNumber: String
        let route: String           // "DXB → LHR"
        let std: String             // "STD 02:15"
        let sta: String             // "STA 07:40"
        let dateLabel: String       // "Sat 17 May"
        let relativeLabel: String   // "Today" / "Tomorrow" / "in 3 days"
        let registration: String?
        let countdownLabel: String  // "5h 50m"
    }

    static func nextFlight(sectors: [PlannedSector], now: Date = .now) -> NextFlight? {
        let timed = sectors.compactMap { TimedSector(sector: $0) }
        guard let next = timed.filter({ $0.departure > now }).min(by: { $0.departure < $1.departure })
        else { return nil }
        let s = next.sector
        return NextFlight(
            id: s.id,
            flightNumber: s.flightNumber.isEmpty ? "Sector \(s.sectorIndex + 1)" : s.flightNumber,
            route: "\(s.departureStation.uppercased()) → \(s.arrivalStation.uppercased())",
            std: "STD \(s.departureTime)",
            sta: "STA \(s.arrivalTime)",
            dateLabel: dayFormatter.string(from: next.departure),
            relativeLabel: relativeDay(to: next.departure, now: now),
            registration: s.registration,
            countdownLabel: durationLabel(next.departure.timeIntervalSince(now))
        )
    }

    /// Start-of-day dates within `date`'s month that have at least one sector.
    static func activeDays(sectors: [PlannedSector], monthOf date: Date) -> Set<Date> {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .dubai
        guard let interval = calendar.dateInterval(of: .month, for: date) else { return [] }
        let days = sectors
            .compactMap { TimedSector(sector: $0) }
            .map { calendar.startOfDay(for: $0.departure) }
            .filter { $0 >= interval.start && $0 < interval.end }
        return Set(days)
    }

    // MARK: - Hero Builder

    private static func heroFlight(from ts: TimedSector, now: Date, inProgress: Bool) -> OperationalHeroCard.Flight {
        let s = ts.sector
        let phase: String
        let countdown: String
        let progress: Double
        let ringTop: String
        let ringBottom: String

        if inProgress {
            phase = "En route"
            let remaining = ts.arrival.timeIntervalSince(now)
            countdown = "Lands in " + durationLabel(remaining)
            let total = ts.arrival.timeIntervalSince(ts.departure)
            progress = total > 0 ? min(max(now.timeIntervalSince(ts.departure) / total, 0), 1) : 0
            ringTop = durationLabel(remaining)
            ringBottom = "remaining"
        } else {
            let toDeparture = ts.departure.timeIntervalSince(now)
            phase = toDeparture <= 5400 ? "Boarding" : "Scheduled" // within 90 minutes
            countdown = "Departs in " + durationLabel(toDeparture)
            progress = 0
            ringTop = durationLabel(toDeparture)
            ringBottom = "to departure"
        }

        // Sector position within the parent trip (only when more than one leg).
        let sectorPosition: String?
        if let total = s.parentTrip?.sectors.count, total > 1 {
            sectorPosition = "Sector \(s.sectorIndex + 1) of \(total)"
        } else {
            sectorPosition = nil
        }

        return OperationalHeroCard.Flight(
            flightNumber: s.flightNumber.isEmpty ? "Sector \(s.sectorIndex + 1)" : s.flightNumber,
            departureCode: s.departureStation.uppercased(),
            arrivalCode: s.arrivalStation.uppercased(),
            departureCity: StationTimezones.cityName(for: s.departureStation.uppercased()),
            arrivalCity: StationTimezones.cityName(for: s.arrivalStation.uppercased()),
            std: s.departureTime,
            sta: s.arrivalTime,
            phaseLabel: phase,
            countdownLabel: countdown,
            registration: s.registration,
            nextMilestone: nil,
            progress: progress,
            ringTop: ringTop,
            ringBottom: ringBottom,
            sectorPosition: sectorPosition,
            blockTime: durationLabel(ts.arrival.timeIntervalSince(ts.departure)),
            timeDiff: timeDiffLabel(from: s.departureStation, to: s.arrivalStation, on: ts.departure)
        )
    }

    /// Whole-hour offset between two stations at a given instant, e.g. "+1h",
    /// "-3h", "Same". Falls back to "—" when a timezone is unknown.
    private static func timeDiffLabel(from: String, to: String, on date: Date) -> String {
        guard
            let depTZ = StationTimezones.timeZone(for: from.uppercased()),
            let arrTZ = StationTimezones.timeZone(for: to.uppercased())
        else { return "—" }
        let diff = arrTZ.secondsFromGMT(for: date) - depTZ.secondsFromGMT(for: date)
        if diff == 0 { return "Same" }
        let hours = Double(diff) / 3600
        let sign = hours > 0 ? "+" : "−"
        let magnitude = abs(hours)
        let text = magnitude.rounded() == magnitude
            ? String(format: "%.0f", magnitude)
            : String(format: "%.1f", magnitude)
        return "\(sign)\(text)h"
    }

    // MARK: - Timed Sector

    /// A sector with its departure and arrival resolved to absolute `Date`s.
    private struct TimedSector {
        let sector: PlannedSector
        let departure: Date
        let arrival: Date

        init?(sector: PlannedSector) {
            guard
                let dep = Self.absoluteDate(day: sector.date,
                                            hhmm: sector.departureTime,
                                            station: sector.departureStation),
                var arr = Self.absoluteDate(day: sector.date,
                                            hhmm: sector.arrivalTime,
                                            station: sector.arrivalStation)
            else { return nil }

            if arr < dep { arr = arr.addingTimeInterval(86_400) } // overnight sector

            self.sector = sector
            self.departure = dep
            self.arrival = arr
        }

        /// Combine the calendar day of `day` with an `"HH:mm"` clock time
        /// resolved in `station`'s timezone.
        static func absoluteDate(day: Date, hhmm: String, station: String) -> Date? {
            let parts = hhmm.split(separator: ":")
            guard parts.count == 2, let hour = Int(parts[0]), let minute = Int(parts[1]) else { return nil }

            let tz = StationTimezones.timeZone(for: station.uppercased()) ?? .current
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = tz

            let ymd = Calendar.current.dateComponents([.year, .month, .day], from: day)
            var comps = DateComponents()
            comps.year = ymd.year
            comps.month = ymd.month
            comps.day = ymd.day
            comps.hour = hour
            comps.minute = minute
            return calendar.date(from: comps)
        }
    }

    // MARK: - Formatting

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_GB")
        f.dateFormat = "EEE dd MMM"
        return f
    }()

    private static func durationLabel(_ interval: TimeInterval) -> String {
        let totalMinutes = max(0, Int(interval) / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours == 0 { return "\(minutes)m" }
        if minutes == 0 { return "\(hours)h" }
        return "\(hours)h \(minutes)m"
    }

    private static func relativeDay(to date: Date, now: Date) -> String {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day],
                                           from: calendar.startOfDay(for: now),
                                           to: calendar.startOfDay(for: date)).day ?? 0
        switch days {
        case ..<0:  return "Departed"
        case 0:     return "Today"
        case 1:     return "Tomorrow"
        default:    return "in \(days) days"
        }
    }
}
