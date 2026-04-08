import Foundation

struct ParsedTrip: Identifiable, Sendable {
    let id = UUID()
    var key: String // original key from dataPool
    var flightInfo: FlightInfo
    var flightData: FlightData
    var crewMembers: [CrewMember]
    var rawCrewData: [CrewDTO] // keep raw for re-parsing if needed

    var registration: String? {
        get { flightData.aircraftTail }
        set { flightData.aircraftTail = newValue }
    }

    var aircraftTypeCode: Int? {
        guard let reg = registration else { return nil }
        return FleetRegistry.fleet[reg]
    }
}
