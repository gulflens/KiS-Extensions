import Foundation

// Top-level: { "flight-key": TripDTO, ... }
typealias DataPoolDTO = [String: TripDTO]

struct TripDTO: Codable, Sendable {
    let shortInfo: ShortInfoDTO?
    let crewData: [CrewDTO]?
    let flightData: FlightDataContainerDTO?
}

struct ShortInfoDTO: Codable, Sendable {
    let flightNumber: String?
    let flightLegs: [String]?
    let flightDate: FlexibleDate?
    let sectors: FlexibleInt?
    let durations: [FlexibleDouble]?
    let sectorsPerDuty: [Int]?
    let layovers: [FlexibleDouble]?
    let staff: String?
}

struct CrewDTO: Codable, Sendable {
    let FirstName: String?
    let LastName: String?
    let NickName: String?
    let StaffID: String?
    let DOB: String?
    let OperationGrade: String?
    let HRGrade: String?
    let GradeExp: String?
    let NationalityCode: String?
    let Nationality: String?
    let SocialStatus: String?
    let Profile: String?
    let destinationExperiences: [DestinationExperienceDTO]?
}

struct DestinationExperienceDTO: Codable, Sendable {
    let Destination: String?
    let VisitedCount: Int?
}

struct FlightDataContainerDTO: Codable, Sendable {
    let FlightData: [FlightDataItemDTO]?
}

struct FlightDataItemDTO: Codable, Sendable {
    let AircraftTail: String?
    let ServiceType: String?
}

/// Handles date that can be a string, number (timestamp), or null
struct FlexibleDate: Codable, Sendable {
    let date: Date

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            date = Date()
            return
        }
        if let dateString = try? container.decode(String.self) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let d = formatter.date(from: dateString) {
                date = d
                return
            }
            // Without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            if let d = formatter.date(from: dateString) {
                date = d
                return
            }
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            for format in ["yyyy-MM-dd'T'HH:mm:ss.SSSZ", "yyyy-MM-dd'T'HH:mm:ss", "yyyy-MM-dd", "MM/dd/yyyy", "dd/MM/yyyy", "M/dd/yyyy h:mm:ss a"] {
                df.dateFormat = format
                if let d = df.date(from: dateString) {
                    date = d
                    return
                }
            }
            date = Date()
        } else if let timestamp = try? container.decode(Double.self) {
            date = Date(timeIntervalSince1970: timestamp / 1000.0)
        } else {
            date = Date()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(date.timeIntervalSince1970 * 1000.0)
    }
}

/// Handles numbers that might come as strings or ints
struct FlexibleInt: Codable, Sendable {
    let value: Int

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let i = try? container.decode(Int.self) {
            value = i
        } else if let s = try? container.decode(String.self), let i = Int(s) {
            value = i
        } else if let d = try? container.decode(Double.self) {
            value = Int(d)
        } else {
            value = 0
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

/// Handles numbers that might come as strings or doubles
struct FlexibleDouble: Codable, Sendable {
    let value: Double

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let d = try? container.decode(Double.self) {
            value = d
        } else if let s = try? container.decode(String.self), let d = Double(s) {
            value = d
        } else if let i = try? container.decode(Int.self) {
            value = Double(i)
        } else {
            value = 0
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}
