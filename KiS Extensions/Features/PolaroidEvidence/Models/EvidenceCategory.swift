import SwiftUI

// MARK: - EvidenceCategory

enum EvidenceCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case seatDefect
    case cabinDefect
    case foodIssue
    case nonStandardEquipment
    case other

    // MARK: Identifiable

    var id: String { rawValue }

    // MARK: Display

    var displayName: String {
        switch self {
        case .seatDefect:           return "Seat defect"
        case .cabinDefect:          return "Cabin defect"
        case .foodIssue:            return "Food issue"
        case .nonStandardEquipment: return "Non standard equipment"
        case .other:                return "Other"
        }
    }

    var iconSymbol: String {
        switch self {
        case .seatDefect:           return "chair.lounge.fill"
        case .cabinDefect:          return "airplane.circle.fill"
        case .foodIssue:            return "fork.knife"
        case .nonStandardEquipment: return "wrench.and.screwdriver.fill"
        case .other:                return "questionmark.circle.fill"
        }
    }

    var tintColor: Color {
        switch self {
        case .seatDefect:           return EvidenceTheme.seatDefect
        case .cabinDefect:          return EvidenceTheme.cabinDefect
        case .foodIssue:            return EvidenceTheme.foodIssue
        case .nonStandardEquipment: return EvidenceTheme.nonStandardEquipment
        case .other:                return EvidenceTheme.other
        }
    }
}
