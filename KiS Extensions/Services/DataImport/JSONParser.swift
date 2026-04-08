import Foundation

struct JSONParser {
    enum ParseError: LocalizedError {
        case invalidJSON
        case emptyData
        case decodingFailed(String)

        var errorDescription: String? {
            switch self {
            case .invalidJSON: return "Invalid JSON format"
            case .emptyData: return "No trip data found"
            case .decodingFailed(let msg): return "Decoding failed: \(msg)"
            }
        }
    }

    static func parse(_ jsonString: String) throws -> [ParsedTrip] {
        guard let data = jsonString.data(using: .utf8) else {
            throw ParseError.invalidJSON
        }
        return try parse(data)
    }

    static func parse(_ data: Data) throws -> [ParsedTrip] {
        let decoder = JSONDecoder()

        let dataPool: DataPoolDTO
        do {
            dataPool = try decoder.decode(DataPoolDTO.self, from: data)
        } catch {
            throw ParseError.decodingFailed(error.localizedDescription)
        }

        guard !dataPool.isEmpty else {
            throw ParseError.emptyData
        }

        var trips: [ParsedTrip] = []

        for (key, tripDTO) in dataPool {
            // Skip entries without shortInfo (incomplete data)
            guard let shortInfo = tripDTO.shortInfo else { continue }

            let durations = shortInfo.durations?.map { $0.value } ?? []
            let sectors = shortInfo.sectors?.value ?? max(1, durations.count)

            let flightInfo = FlightInfo(
                flightNumber: shortInfo.flightNumber ?? "???",
                flightLegs: shortInfo.flightLegs ?? ["DXB"],
                flightDate: shortInfo.flightDate?.date ?? Date(),
                sectors: sectors,
                durations: durations,
                sectorsPerDuty: shortInfo.sectorsPerDuty ?? [sectors]
            )

            let flightData = FlightData(
                aircraftTail: tripDTO.flightData?.FlightData?.first?.AircraftTail,
                serviceType: tripDTO.flightData?.FlightData?.first?.ServiceType
            )

            let rawCrewData = tripDTO.crewData ?? []
            let crewMembers = CrewLoader.loadCrew(from: rawCrewData)

            let trip = ParsedTrip(
                key: key,
                flightInfo: flightInfo,
                flightData: flightData,
                crewMembers: crewMembers,
                rawCrewData: rawCrewData
            )

            trips.append(trip)
        }

        return trips
    }
}
