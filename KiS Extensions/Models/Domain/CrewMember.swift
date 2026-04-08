import Foundation

struct CrewMember: Identifiable, Sendable, Equatable {
    let id: String // staffNumber
    var index: Int
    var ratingIR: Int // DF rating 1-20, 21 = no rating
    var languages: [String]
    var badges: [Int]
    var grade: CrewGrade
    var originalGrade: CrewGrade
    var outOfGrade: Bool
    var flag: String // lowercase nationality code
    var timeInGrade: String
    var timeInGradeMonths: Int
    var doingDF: Bool = false
    var doingPA: [Int: [String]] = [:] // sector index -> [language]
    var allocatedBadges: [Int: [Int]] = [:] // sector index -> [badge codes] for MFP/W/UD/IR/PA
    var birthday: Date
    var lastPosition: [String]
    var comment: String
    var staffNumber: String
    var fullname: String
    var nickname: String
    var destinationExperience: [String: Int]
    var nationality: String
    var positions: [Int: String] = [:] // sector index -> position
    var breaks: [Int: Int] = [:] // sector index -> break group
}
