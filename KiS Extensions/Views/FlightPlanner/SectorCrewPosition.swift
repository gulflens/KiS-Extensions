import Foundation

// MARK: - Sector Crew Position

/// Lightweight snapshot of one crew member's position data for a single sector.
/// Stored as a JSON array inside PlannedSector.crewPositionsJSON.
struct SectorCrewPosition: Codable, Identifiable {
    var id: String { staffNumber }

    let staffNumber: String
    let nickname: String
    let fullname: String
    let grade: String
    let flag: String
    let nationality: String
    let position: String
    let breakGroup: Int
    let allocatedBadges: [Int]
    var documentsChecked: Bool
    var notes: String

    init(
        staffNumber: String,
        nickname: String,
        fullname: String,
        grade: String,
        flag: String,
        nationality: String,
        position: String,
        breakGroup: Int,
        allocatedBadges: [Int],
        documentsChecked: Bool = false,
        notes: String = ""
    ) {
        self.staffNumber = staffNumber
        self.nickname = nickname
        self.fullname = fullname
        self.grade = grade
        self.flag = flag
        self.nationality = nationality
        self.position = position
        self.breakGroup = breakGroup
        self.allocatedBadges = allocatedBadges
        self.documentsChecked = documentsChecked
        self.notes = notes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        staffNumber = try container.decode(String.self, forKey: .staffNumber)
        nickname = try container.decode(String.self, forKey: .nickname)
        fullname = try container.decode(String.self, forKey: .fullname)
        grade = try container.decode(String.self, forKey: .grade)
        flag = try container.decode(String.self, forKey: .flag)
        nationality = try container.decode(String.self, forKey: .nationality)
        position = try container.decode(String.self, forKey: .position)
        breakGroup = try container.decode(Int.self, forKey: .breakGroup)
        allocatedBadges = try container.decode([Int].self, forKey: .allocatedBadges)
        documentsChecked = try container.decodeIfPresent(Bool.self, forKey: .documentsChecked) ?? false
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
    }
}
