import Foundation
import SwiftData

@Model
final class SavedTrip {
    var tripKey: String = ""
    var flightNumber: String = ""
    var flightLegs: [String] = []
    var flightDate: Date = Date()
    var sectors: Int = 0
    var durations: [Double] = []
    var sectorsPerDuty: [Int] = []
    var aircraftTail: String?
    var serviceType: String?
    var registration: String?
    var savedAt: Date = Date()
    var notes: String = ""

    @Relationship(deleteRule: .cascade, inverse: \SavedCrewAllocation.savedTrip)
    var crewAllocations: [SavedCrewAllocation] = []

    // Store raw JSON so trip can be re-imported / re-allocated
    var rawJSON: Data?

    init(
        tripKey: String,
        flightNumber: String,
        flightLegs: [String],
        flightDate: Date,
        sectors: Int,
        durations: [Double],
        sectorsPerDuty: [Int],
        aircraftTail: String? = nil,
        serviceType: String? = nil,
        registration: String? = nil,
        savedAt: Date = Date(),
        notes: String = "",
        crewAllocations: [SavedCrewAllocation] = [],
        rawJSON: Data? = nil
    ) {
        self.tripKey = tripKey
        self.flightNumber = flightNumber
        self.flightLegs = flightLegs
        self.flightDate = flightDate
        self.sectors = sectors
        self.durations = durations
        self.sectorsPerDuty = sectorsPerDuty
        self.aircraftTail = aircraftTail
        self.serviceType = serviceType
        self.registration = registration
        self.savedAt = savedAt
        self.notes = notes
        self.crewAllocations = crewAllocations
        self.rawJSON = rawJSON
    }

    convenience init(from trip: ParsedTrip) {
        let allocations = trip.crewMembers.map { SavedCrewAllocation(from: $0) }

        // Encode raw crew data for re-allocation
        let rawData = try? JSONEncoder().encode(trip.rawCrewData)

        self.init(
            tripKey: trip.key,
            flightNumber: trip.flightInfo.flightNumber,
            flightLegs: trip.flightInfo.flightLegs,
            flightDate: trip.flightInfo.flightDate,
            sectors: trip.flightInfo.sectors,
            durations: trip.flightInfo.durations,
            sectorsPerDuty: trip.flightInfo.sectorsPerDuty,
            aircraftTail: trip.flightData.aircraftTail,
            serviceType: trip.flightData.serviceType,
            registration: trip.registration,
            savedAt: Date(),
            crewAllocations: allocations,
            rawJSON: rawData
        )
    }

    func toParsedTrip() -> ParsedTrip {
        let flightInfo = FlightInfo(
            flightNumber: flightNumber,
            flightLegs: flightLegs,
            flightDate: flightDate,
            sectors: sectors,
            durations: durations,
            sectorsPerDuty: sectorsPerDuty
        )

        let flightData = FlightData(
            aircraftTail: aircraftTail,
            serviceType: serviceType
        )

        let crewMembers = crewAllocations
            .sorted { $0.index < $1.index }
            .map { $0.toCrewMember() }

        // Decode raw crew data if available
        let rawCrewData: [CrewDTO]
        if let rawJSON, let decoded = try? JSONDecoder().decode([CrewDTO].self, from: rawJSON) {
            rawCrewData = decoded
        } else {
            rawCrewData = []
        }

        return ParsedTrip(
            key: tripKey,
            flightInfo: flightInfo,
            flightData: flightData,
            crewMembers: crewMembers,
            rawCrewData: rawCrewData
        )
    }

    /// Update crew allocations from a modified ParsedTrip
    func updateAllocations(from trip: ParsedTrip) {
        let incomingStaffNumbers = Set(trip.crewMembers.map { $0.staffNumber })

        for member in trip.crewMembers {
            if let existing = crewAllocations.first(where: { $0.staffNumber == member.staffNumber }) {
                existing.update(from: member)
            } else {
                // New crew member (manual override add)
                let newAlloc = SavedCrewAllocation(from: member)
                newAlloc.savedTrip = self
                crewAllocations.append(newAlloc)
            }
        }

        // Remove deleted crew (manual override removal)
        crewAllocations.removeAll { alloc in
            !incomingStaffNumbers.contains(alloc.staffNumber)
        }

        savedAt = Date()
    }

    /// Route string for display (e.g. "DXB - AMS - DXB")
    var routeString: String {
        flightLegs.joined(separator: " - ")
    }

    /// Duration text for display
    var durationText: String {
        durations.map { String(format: "%.1fh", $0) }.joined(separator: " → ")
    }

    /// Whether this is a ULR flight
    var isULR: Bool {
        guard let maxDuration = durations.max() else { return false }
        return maxDuration > 9.5
    }
}
