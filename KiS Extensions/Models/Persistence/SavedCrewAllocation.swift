import Foundation
import SwiftData

@Model
final class SavedCrewAllocation {
    var staffNumber: String = ""
    var nickname: String = ""
    var fullname: String = ""
    var gradeRaw: String = ""
    var originalGradeRaw: String = ""
    var outOfGrade: Bool = false
    var flag: String = ""
    var nationality: String = ""
    var languages: [String] = []
    var timeInGrade: String = ""
    var timeInGradeMonths: Int = 0
    var ratingIR: Int = 0
    var badges: [Int] = []
    var comment: String = ""
    var doingDF: Bool = false
    var index: Int = 0
    var birthday: Date = Date.distantPast

    var positionsJSON: Data = Data()
    var breaksJSON: Data = Data()
    var doingPAJSON: Data = Data()
    var allocatedBadgesJSON: Data = Data()
    var destinationExperienceJSON: Data = Data()
    var isManualOverride: Bool = false
    var isSupy: Bool = false

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
        birthday: Date,
        positionsJSON: Data,
        breaksJSON: Data,
        doingPAJSON: Data,
        allocatedBadgesJSON: Data,
        destinationExperienceJSON: Data = Data(),
        isManualOverride: Bool = false,
        isSupy: Bool = false
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
        self.birthday = birthday
        self.positionsJSON = positionsJSON
        self.breaksJSON = breaksJSON
        self.doingPAJSON = doingPAJSON
        self.allocatedBadgesJSON = allocatedBadgesJSON
        self.destinationExperienceJSON = destinationExperienceJSON
        self.isManualOverride = isManualOverride
        self.isSupy = isSupy
    }

    convenience init(from member: CrewMember) {
        let encoder = JSONEncoder()
        let posData = (try? encoder.encode(member.positions)) ?? Data()
        let brkData = (try? encoder.encode(member.breaks)) ?? Data()
        let paData = (try? encoder.encode(member.doingPA)) ?? Data()
        let abData = (try? encoder.encode(member.allocatedBadges)) ?? Data()
        let deData = (try? encoder.encode(member.destinationExperience)) ?? Data()

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
            birthday: member.birthday,
            positionsJSON: posData,
            breaksJSON: brkData,
            doingPAJSON: paData,
            allocatedBadgesJSON: abData,
            destinationExperienceJSON: deData,
            isManualOverride: member.isManualOverride,
            isSupy: member.isSupy
        )
    }

    func toCrewMember() -> CrewMember {
        let decoder = JSONDecoder()
        let positions = (try? decoder.decode([Int: String].self, from: positionsJSON)) ?? [:]
        let breaks = (try? decoder.decode([Int: Int].self, from: breaksJSON)) ?? [:]
        let doingPA = (try? decoder.decode([Int: [String]].self, from: doingPAJSON)) ?? [:]
        let allocatedBadges = (try? decoder.decode([Int: [Int]].self, from: allocatedBadgesJSON)) ?? [:]
        let destExp = (try? decoder.decode([String: Int].self, from: destinationExperienceJSON)) ?? [:]

        var member = CrewMember(
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
            birthday: birthday,
            lastPosition: [],
            comment: comment,
            staffNumber: staffNumber,
            fullname: fullname,
            nickname: nickname,
            destinationExperience: destExp,
            nationality: nationality,
            positions: positions,
            breaks: breaks
        )
        member.isManualOverride = isManualOverride
        member.isSupy = isSupy
        return member
    }

    /// Update this allocation from a modified CrewMember
    func update(from member: CrewMember) {
        let encoder = JSONEncoder()
        nickname = member.nickname
        fullname = member.fullname
        gradeRaw = member.grade.rawValue
        originalGradeRaw = member.originalGrade.rawValue
        flag = member.flag
        nationality = member.nationality
        languages = member.languages
        badges = member.badges
        comment = member.comment
        doingDF = member.doingDF
        birthday = member.birthday
        isManualOverride = member.isManualOverride
        isSupy = member.isSupy
        positionsJSON = (try? encoder.encode(member.positions)) ?? Data()
        breaksJSON = (try? encoder.encode(member.breaks)) ?? Data()
        doingPAJSON = (try? encoder.encode(member.doingPA)) ?? Data()
        allocatedBadgesJSON = (try? encoder.encode(member.allocatedBadges)) ?? Data()
        destinationExperienceJSON = (try? encoder.encode(member.destinationExperience)) ?? Data()
    }
}
