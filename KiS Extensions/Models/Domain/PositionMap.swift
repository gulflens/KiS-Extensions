import Foundation

struct GradePositions: Sendable {
    var galley: [String]
    var df: [String]
    var remain: [String]
    var only: [String]

    /// All positions flattened
    var allPositions: [String] {
        galley + df + remain + only
    }

    var count: Int { allPositions.count }
}

/// Maps each grade (+ EXTRA) to its position slots for a given aircraft/operation type
typealias PositionMap = [String: GradePositions]
// Keys are grade rawValues: "PUR", "CSV", "FG1", "GR1", "W", "GR2", "CSA", "EXTRA"
