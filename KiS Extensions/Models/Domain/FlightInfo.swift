import Foundation

struct FlightInfo: Sendable {
    var flightNumber: String
    var flightLegs: [String] // e.g. ["DXB", "AMS", "DXB"]
    var flightDate: Date
    var sectors: Int
    var durations: [Double]
    var sectorsPerDuty: [Int]

    var isULR: Bool {
        guard let maxDuration = durations.max() else { return false }
        return maxDuration > 9.5
    }

    /// Destinations (excluding base DXB)
    var destinations: [String] {
        Array(Set(flightLegs.filter { $0 != "DXB" }))
    }
}

struct FlightData: Sendable {
    var aircraftTail: String?
    var serviceType: String?
}
