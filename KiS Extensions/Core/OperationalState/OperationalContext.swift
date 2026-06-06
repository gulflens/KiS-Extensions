import Foundation

// MARK: - Operational Context

/// Pure operational summary derived from the planned schedule. Adds the active
/// rotation and the rolling month summary on top of `DashboardFlightResolver`
/// (which still owns the hero flight and upcoming list). Performs no
/// persistence and no SwiftUI work — fully testable.
///
/// Time model matches `DashboardFlightResolver`: each sector stores a calendar
/// `date` plus `"HH:mm"` local strings, resolved in the station's timezone.
enum OperationalContext {

    // MARK: - Rotation

    /// The trip currently being flown (or next up), expressed as ordered steps.
    struct Rotation {
        enum Status { case completed, active, upcoming }

        struct Step: Identifiable {
            let id: UUID
            let from: String
            let to: String
            let status: Status
        }

        let title: String      // trip number or lead flight number
        let steps: [Step]
    }

    /// Build the rotation for the trip containing the active or next sector.
    static func rotation(sectors: [PlannedSector], now: Date = .now) -> Rotation? {
        let timed = sectors.compactMap { Timed(sector: $0) }
        let active = timed
            .filter { now >= $0.departure && now <= $0.arrival }
            .min { $0.departure < $1.departure }
        let next = timed
            .filter { $0.departure > now }
            .min { $0.departure < $1.departure }
        guard let focus = active ?? next else { return nil }

        // Sectors that share the focus sector's parent trip, in order.
        let tripSectors: [PlannedSector]
        if let trip = focus.sector.parentTrip {
            tripSectors = trip.sortedSectors
        } else {
            tripSectors = [focus.sector]
        }

        let steps: [Rotation.Step] = tripSectors.map { sector in
            let status: Rotation.Status
            if let t = Timed(sector: sector) {
                if now > t.arrival { status = .completed }
                else if now >= t.departure { status = .active }
                else { status = .upcoming }
            } else {
                status = .upcoming
            }
            return .init(id: sector.id,
                         from: sector.departureStation.uppercased(),
                         to: sector.arrivalStation.uppercased(),
                         status: status)
        }

        let title = focus.sector.parentTrip?.tripNumber.nonEmpty
            ?? focus.sector.flightNumber.nonEmpty
            ?? "Rotation"
        return Rotation(title: title, steps: steps)
    }

    // MARK: - Month Summary

    /// Rolling summary of the calendar month containing `now`. Only metrics with
    /// real backing data are produced; nothing is estimated.
    struct MonthSummary {
        let monthLabel: String   // "May 2026"
        let blockHours: Double   // sum of flown sector durations
        let sectorsFlown: Int    // sectors whose arrival is in the past
        let dutyDays: Int        // distinct calendar days with a sector
        let layovers: Int        // sectors flagged as a layover

        var blockHoursLabel: String {
            let h = Int(blockHours)
            let m = Int((blockHours - Double(h)) * 60)
            return String(format: "%d:%02d", h, m)
        }
    }

    static func monthSummary(sectors: [PlannedSector], now: Date = .now) -> MonthSummary {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .dubai
        let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let monthEnd = calendar.dateInterval(of: .month, for: now)?.end ?? now

        let inMonth = sectors
            .compactMap { Timed(sector: $0) }
            .filter { $0.departure >= monthStart && $0.departure < monthEnd }

        let flown = inMonth.filter { $0.arrival <= now }
        let blockHours = flown.reduce(0.0) { $0 + $1.arrival.timeIntervalSince($1.departure) / 3600 }
        let dutyDays = Set(inMonth.map { calendar.startOfDay(for: $0.departure) }).count
        let layovers = inMonth.filter { $0.sector.savedIsLayover == true }.count

        let f = DateFormatter()
        f.locale = Locale(identifier: "en_GB")
        f.dateFormat = "MMMM yyyy"

        return MonthSummary(
            monthLabel: f.string(from: now),
            blockHours: blockHours,
            sectorsFlown: flown.count,
            dutyDays: dutyDays,
            layovers: layovers
        )
    }

    // MARK: - Timed Sector

    /// A sector resolved to absolute departure/arrival `Date`s. Mirrors the
    /// resolution rule used by `DashboardFlightResolver`.
    private struct Timed {
        let sector: PlannedSector
        let departure: Date
        let arrival: Date

        init?(sector: PlannedSector) {
            guard
                let dep = Self.absoluteDate(day: sector.date, hhmm: sector.departureTime, station: sector.departureStation),
                var arr = Self.absoluteDate(day: sector.date, hhmm: sector.arrivalTime, station: sector.arrivalStation)
            else { return nil }
            if arr < dep { arr = arr.addingTimeInterval(86_400) } // overnight
            self.sector = sector
            self.departure = dep
            self.arrival = arr
        }

        static func absoluteDate(day: Date, hhmm: String, station: String) -> Date? {
            let parts = hhmm.split(separator: ":")
            guard parts.count == 2, let hour = Int(parts[0]), let minute = Int(parts[1]) else { return nil }
            let tz = StationTimezones.timeZone(for: station.uppercased()) ?? .current
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = tz
            let ymd = Calendar.current.dateComponents([.year, .month, .day], from: day)
            var comps = DateComponents()
            comps.year = ymd.year; comps.month = ymd.month; comps.day = ymd.day
            comps.hour = hour; comps.minute = minute
            return calendar.date(from: comps)
        }
    }
}

// MARK: - String Helper

private extension String {
    /// Returns `nil` when the string is empty after trimming whitespace.
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? nil : trimmed
    }
}
