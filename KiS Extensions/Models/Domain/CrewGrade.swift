import Foundation

enum CrewGrade: String, Codable, CaseIterable, Identifiable {
    case PUR, CSV, FG1, GR1, W, GR2, CSA

    var id: String { rawValue }

    var indexModifier: Int {
        switch self {
        case .PUR: return 0
        case .CSV: return 10
        case .FG1: return 20
        case .GR1: return 30
        case .W:   return 40
        case .GR2: return 50
        case .CSA: return 70
        }
    }

    var displayName: String {
        switch self {
        case .PUR: return "Purser"
        case .CSV: return "Cabin Supervisor"
        case .FG1: return "Flight Steward Grade 1"
        case .GR1: return "Grade 1"
        case .W:   return "Premium Economy"
        case .GR2: return "Grade 2"
        case .CSA: return "Cabin Service Attendant"
        }
    }

    var sectionName: String {
        switch self {
        case .PUR, .CSV: return "Seniors"
        case .FG1: return "First"
        case .GR1: return "Business"
        case .W:   return "Premium"
        case .GR2: return "Economy"
        case .CSA: return "CSA"
        }
    }

    /// Whether this grade uses only-type positions (no galley/df/remain split)
    var usesOnlyPositions: Bool {
        switch self {
        case .PUR, .CSV, .CSA: return true
        default: return false
        }
    }
}
