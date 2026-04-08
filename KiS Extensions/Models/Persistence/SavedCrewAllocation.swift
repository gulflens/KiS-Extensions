import Foundation
import SwiftData

@Model
final class SavedCrewAllocation {
    var staffNumber: String
    var nickname: String
    var fullname: String
    var gradeRaw: String
    var originalGradeRaw: String
    var outOfGrade: Bool
    var flag: String
    var nationality: String
    var languages: [String]
    var timeInGrade: String
    var timeInGradeMonths: Int
    var ratingIR: Int
    var badges: [Int]
    var comment: String
    var doingDF: Bool
    var index: Int

    // Allocation results stored as JSON-encoded dictionaries
    var positionsJSON: Data
    var breaksJSON: Data
    var doingPAJSON: Data
    var allocatedBadgesJSON: Data = Data()

    var savedTrip: SavedTrip?

    init(
        staffNumber: String,
        nickname: String,
        fullname: String,
        gradeRaw: String,
        originalGradeRaw: String,
        outOfGrade: Bool,
        flag: String,
        nationality: String,
        languages: [String],
        timeInGrade: String,
        timeInGradeMonths: Int,
        ratingIR: Int,
        badges: [Int],
        comment: String,
        doingDF: Bool,
        index: Int,
        positionsJSON: Data,
        breaksJSON: Data,
        doingPAJSON: Data,
        allocatedBadgesJSON: Data
    ) {
        self.staffNumber = staffNumber
        self.nickname = nickname
        self.fullname = fullname
        self.gradeRaw = gradeRaw
        self.originalGradeRaw = originalGradeRaw
        self.outOfGrade = outOfGrade
        self.flag = flag
        self.nationality = nationality
        self.languages = languages
        self.timeInGrade = timeInGrade
        self.timeInGradeMonths = timeInGradeMonths
        self.ratingIR = ratingIR
        self.badges = badges
        self.comment = comment
        self.doingDF = doingDF
        self.index = index
        self.positionsJSON = positionsJSON
        self.breaksJSON = breaksJSON
        self.doingPAJSON = doingPAJSON
        self.allocatedBadgesJSON = allocatedBadgesJSON
    }

    convenience init(from member: CrewMember) {
        let encoder = JSONEncoder()
        let posData = (try? encoder.encode(member.positions)) ?? Data()
        let brkData = (try? encoder.encode(member.breaks)) ?? Data()
        let paData = (try? encoder.encode(member.doingPA)) ?? Data()
        let abData = (try? encoder.encode(member.allocatedBadges)) ?? Data()

        self.init(
            staffNumber: member.staffNumber,
            nickname: member.nickname,
            fullname: member.fullname,
            gradeRaw: member.grade.rawValue,
            originalGradeRaw: member.originalGrade.rawValue,
            outOfGrade: member.outOfGrade,
            flag: member.flag,
            nationality: member.nationality,
            languages: member.languages,
            timeInGrade: member.timeInGrade,
            timeInGradeMonths: member.timeInGradeMonths,
            ratingIR: member.ratingIR,
            badges: member.badges,
            comment: member.comment,
            doingDF: member.doingDF,
            index: member.index,
            positionsJSON: posData,
            breaksJSON: brkData,
            doingPAJSON: paData,
            allocatedBadgesJSON: abData
        )
    }

    func toCrewMember() -> CrewMember {
        let decoder = JSONDecoder()
        let positions = (try? decoder.decode([Int: String].self, from: positionsJSON)) ?? [:]
        let breaks = (try? decoder.decode([Int: Int].self, from: breaksJSON)) ?? [:]
        let doingPA = (try? decoder.decode([Int: [String]].self, from: doingPAJSON)) ?? [:]
        let allocatedBadges = (try? decoder.decode([Int: [Int]].self, from: allocatedBadgesJSON)) ?? [:]

        return CrewMember(
            id: staffNumber,
            index: index,
            ratingIR: ratingIR,
            languages: languages,
            badges: badges,
            grade: CrewGrade(rawValue: gradeRaw) ?? .GR2,
            originalGrade: CrewGrade(rawValue: originalGradeRaw) ?? .GR2,
            outOfGrade: outOfGrade,
            flag: flag,
            timeInGrade: timeInGrade,
            timeInGradeMonths: timeInGradeMonths,
            doingDF: doingDF,
            doingPA: doingPA,
            allocatedBadges: allocatedBadges,
            birthday: Date(),
            lastPosition: [],
            comment: comment,
            staffNumber: staffNumber,
            fullname: fullname,
            nickname: nickname,
            destinationExperience: [:],
            nationality: nationality,
            positions: positions,
            breaks: breaks
        )
    }

    /// Update this allocation from a modified CrewMember
    func update(from member: CrewMember) {
        let encoder = JSONEncoder()
        badges = member.badges
        comment = member.comment
        doingDF = member.doingDF
        positionsJSON = (try? encoder.encode(member.positions)) ?? Data()
        breaksJSON = (try? encoder.encode(member.breaks)) ?? Data()
        doingPAJSON = (try? encoder.encode(member.doingPA)) ?? Data()
        allocatedBadgesJSON = (try? encoder.encode(member.allocatedBadges)) ?? Data()
    }
}
