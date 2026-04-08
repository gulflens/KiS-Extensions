import Foundation
import UIKit
import UniformTypeIdentifiers

/// Coordinates all 5 data import methods, converging to [ParsedTrip]
@Observable
class DataImportService {
    var error: String?
    var isImporting = false

    /// Method 1: Import from clipboard
    func importFromClipboard() throws -> [ParsedTrip] {
        guard let text = UIPasteboard.general.string, !text.isEmpty else {
            throw ImportError.clipboardEmpty
        }
        return try JSONParser.parse(text)
    }

    /// Method 2: Import from text input
    func importFromText(_ text: String) throws -> [ParsedTrip] {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ImportError.emptyInput
        }
        return try JSONParser.parse(text)
    }

    /// Method 3: Import from file URL
    func importFromFile(_ url: URL) throws -> [ParsedTrip] {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing { url.stopAccessingSecurityScopedResource() }
        }
        let data = try Data(contentsOf: url)
        return try JSONParser.parse(data)
    }

    /// Method 4: Import from shared data (App open URL / share extension)
    func importFromSharedData(_ data: Data) throws -> [ParsedTrip] {
        return try JSONParser.parse(data)
    }

    /// Method 5: Manual entry — builds ParsedTrip from form data
    func createFromManualEntry(
        flightNumber: String,
        flightLegs: [String],
        flightDate: Date,
        sectors: Int,
        durations: [Double],
        registration: String?,
        crewEntries: [ManualCrewEntry]
    ) -> ParsedTrip {
        let flightInfo = FlightInfo(
            flightNumber: flightNumber,
            flightLegs: flightLegs,
            flightDate: flightDate,
            sectors: sectors,
            durations: durations,
            sectorsPerDuty: [sectors]
        )

        let flightData = FlightData(
            aircraftTail: registration,
            serviceType: "Passenger flight"
        )

        let crewDTOs = crewEntries.map { $0.toCrewDTO() }
        let crewMembers = CrewLoader.loadCrew(from: crewDTOs)

        return ParsedTrip(
            key: "manual-\(UUID().uuidString)",
            flightInfo: flightInfo,
            flightData: flightData,
            crewMembers: crewMembers,
            rawCrewData: crewDTOs
        )
    }

    enum ImportError: LocalizedError {
        case clipboardEmpty
        case emptyInput
        case fileReadFailed

        var errorDescription: String? {
            switch self {
            case .clipboardEmpty: return "Clipboard is empty. Copy JSON data first."
            case .emptyInput: return "Input is empty. Paste JSON data."
            case .fileReadFailed: return "Could not read the selected file."
            }
        }
    }
}

/// Data structure for manual crew entry form
struct ManualCrewEntry: Identifiable {
    let id = UUID()
    var firstName: String = ""
    var lastName: String = ""
    var nickName: String = ""
    var staffID: String = ""
    var dob: Date = Date()
    var operationGrade: CrewGrade = .GR2
    var hrGrade: CrewGrade = .GR2
    var gradeExp: String = "0 Years 0 Months"
    var nationalityCode: String = ""
    var nationality: String = ""
    var profile: String = ""

    func toCrewDTO() -> CrewDTO {
        let dobFormatter = ISO8601DateFormatter()
        return CrewDTO(
            FirstName: firstName,
            LastName: lastName,
            NickName: nickName.isEmpty ? nil : nickName,
            StaffID: staffID,
            DOB: dobFormatter.string(from: dob),
            OperationGrade: operationGrade.rawValue,
            HRGrade: hrGrade.rawValue,
            GradeExp: gradeExp,
            NationalityCode: nationalityCode,
            Nationality: nationality,
            SocialStatus: nil,
            Profile: profile,
            destinationExperiences: []
        )
    }
}
