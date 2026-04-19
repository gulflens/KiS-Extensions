import Foundation

struct FlightInfo: Sendable {
    var flightNumber: String
    var flightLegs: [String] // e.g. ["DXB", "AMS", "DXB"]
    var flightDate: Date
    var sectors: Int
    var durations: [Double]
    var sectorsPerDuty: [Int]
    var hasBreaks: [Bool]
    var selectedFacility: String?

    init(
        flightNumber: String,
        flightLegs: [String],
        flightDate: Date,
        sectors: Int,
        durations: [Double],
        sectorsPerDuty: [Int],
        hasBreaks: [Bool]? = nil,
        selectedFacility: String? = nil
    ) {
        self.flightNumber = flightNumber
        self.flightLegs = flightLegs
        self.flightDate = flightDate
        self.sectors = sectors
        self.durations = durations
        self.sectorsPerDuty = sectorsPerDuty
        self.hasBreaks = hasBreaks ?? durations.map { $0 > 3.5 }
        self.selectedFacility = selectedFacility
    }

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
