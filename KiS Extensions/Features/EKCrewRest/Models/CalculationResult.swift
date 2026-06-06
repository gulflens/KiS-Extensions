import Foundation

// MARK: - Timed Block

/// Output of Calculator.calc() — mirrors the demo's `c` object 1:1.
struct TimedBlock: Identifiable, Hashable {
    var id: String { "\(label)-\(start)-\(end)" }
    let label: String
    let start: Int     // minutes from midnight
    let end: Int
    var durationMin: Int { end - start }
}

// MARK: - First Class Result

struct FCResult: Hashable {
    let breaks: [TimedBlock]
    let overlap: Int
    let dropped: Int
    let breakDur: Int
    let allowOverlap: Bool
    let fcStart: Int
    let windowEnd: Int
    let startAfterTO: Int
    let endBuffer: Int
}

// MARK: - Calculation Result

struct CalculationResult: Hashable {

    // Time anchors (minutes since midnight)
    let T0: Int           // take-off
    let LAND: Int         // landing
    let TWENTY: Int       // 20 to top
    let TOD: Int          // top of descent
    let isLong: Bool      // flight > 4h → settling-in applies

    let settlingStart: Int?
    let settlingEnd: Int?

    let services: [TimedBlock]
    let breaks: [TimedBlock]

    let numBreaks: Int
    let totalRest: Int
    let flightMin: Int
    let svc1Extension: Int

    let fc: FCResult?
    let fcApplies: Bool

    /// Snapshot of inputs at calculation time, used by the schedule card to
    /// describe what was computed.
    let registration: String
    let aircraft: String
    let facility: Facility
    let matchedFleet: FleetEntry?
}
