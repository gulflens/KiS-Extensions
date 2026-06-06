import Foundation

// MARK: - Trip Rules

/// Operational thresholds for classifying the gap between two consecutive
/// sectors. A trip is a rotation of sectors that starts and ends at base (DXB).
enum TripRules {
    /// A gap at or below this is ground time (continuous flight, no sleep-over).
    /// Above it is a layover. (Per ops: layover only when strictly over 6 hours.)
    static let continuousMaxMinutes = 360            // 6 hours
    /// Assumed ground time when an actual gap cannot be computed.
    static let defaultGroundMinutes = 90
    /// Informational: a typical turnaround ground time runs 1–3 hours.
    static let normalGroundRange = 60...180
}

// MARK: - Sector Gap

/// The relationship between sector `index` and the sector after it.
enum SectorGapKind {
    /// Short gap on the same aircraft — crew stay on board and keep position.
    case continuousOperation
    /// Short gap but the aircraft changes (or registration unknown) — crew may
    /// re-position; not treated as continuous.
    case groundConnection
    /// Long gap (over 6h) — a sleep-over layover. Positions reset.
    case layover
}

struct SectorGap: Identifiable {
    /// Index of the earlier sector in the pair.
    let id: Int
    let minutes: Int
    let kind: SectorGapKind

    /// Crew retain their position across this gap only on a continuous operation.
    var keepsCrewPosition: Bool { kind == .continuousOperation }
    var isLayover: Bool { kind == .layover }
}

// MARK: - Trip Classifier

/// Pure classification of trips and inter-sector gaps from sector times and
/// aircraft registration. No persistence, no SwiftUI — fully testable.
///
/// "Always look at the gap between sectors": a gap over 6h is a layover; a
/// shorter gap is ground time, and is a continuous operation (crew keep their
/// position) only when the same registration spans both sectors.
enum TripClassifier {

    // MARK: Gaps

    /// One `SectorGap` per consecutive pair, ordered by sector index.
    static func gaps(for sectors: [PlannedSector]) -> [SectorGap] {
        let ordered = sectors.sorted { $0.sectorIndex < $1.sectorIndex }
        guard ordered.count > 1 else { return [] }

        var result: [SectorGap] = []
        for i in 0..<(ordered.count - 1) {
            let prev = ordered[i]
            let next = ordered[i + 1]
            let minutes = gapMinutes(from: prev, to: next) ?? TripRules.defaultGroundMinutes
            result.append(SectorGap(id: prev.sectorIndex,
                                    minutes: minutes,
                                    kind: kind(minutes: minutes, prev: prev, next: next)))
        }
        return result
    }

    private static func kind(minutes: Int, prev: PlannedSector, next: PlannedSector) -> SectorGapKind {
        if minutes > TripRules.continuousMaxMinutes { return .layover }
        return sameAircraft(prev, next) ? .continuousOperation : .groundConnection
    }

    // MARK: Trip Type

    /// Classify a whole trip from its sectors.
    /// - 2 sectors, ground gap → turnaround
    /// - 2 sectors, layover gap → layover
    /// - 3+ sectors → multi-sector (stored as `.transit`)
    static func classify(_ sectors: [PlannedSector]) -> TripType {
        let ordered = sectors.sorted { $0.sectorIndex < $1.sectorIndex }
        guard ordered.count >= 2 else { return .turnaround }
        if ordered.count >= 3 { return .transit }   // multi-sector
        let onlyGap = gaps(for: ordered).first
        return (onlyGap?.isLayover ?? false) ? .layover : .turnaround
    }

    // MARK: Helpers

    /// Whole-minute gap between `prev`'s arrival and `next`'s departure,
    /// resolved in each station's timezone. Nil when a time cannot be parsed.
    static func gapMinutes(from prev: PlannedSector, to next: PlannedSector) -> Int? {
        guard
            let arrival = absoluteDate(day: prev.date, hhmm: prev.arrivalTime,
                                       station: prev.arrivalStation,
                                       departure: prev.departureTime),
            let departure = absoluteDate(day: next.date, hhmm: next.departureTime,
                                         station: next.departureStation, departure: nil)
        else { return nil }
        return max(0, Int(departure.timeIntervalSince(arrival) / 60))
    }

    /// Two sectors share an aircraft when both registrations are present and
    /// match after normalising case and separators ("A6-EWJ" == "a6ewj").
    static func sameAircraft(_ a: PlannedSector, _ b: PlannedSector) -> Bool {
        guard let ra = normalizedRegistration(a.registration),
              let rb = normalizedRegistration(b.registration) else { return false }
        return ra == rb
    }

    private static func normalizedRegistration(_ reg: String?) -> String? {
        guard let reg else { return nil }
        let cleaned = reg.uppercased().filter { $0.isLetter || $0.isNumber }
        return cleaned.isEmpty ? nil : cleaned
    }

    /// Combine a calendar day with an `"HH:mm"` clock time in `station`'s zone.
    /// When `departure` is given and the arrival reads earlier, the arrival is
    /// rolled to the next day (overnight sector).
    private static func absoluteDate(day: Date, hhmm: String, station: String, departure: String?) -> Date? {
        guard let base = resolve(day: day, hhmm: hhmm, station: station) else { return nil }
        if let departure,
           let dep = resolve(day: day, hhmm: departure, station: station),
           base < dep {
            return base.addingTimeInterval(86_400)
        }
        return base
    }

    private static func resolve(day: Date, hhmm: String, station: String) -> Date? {
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
