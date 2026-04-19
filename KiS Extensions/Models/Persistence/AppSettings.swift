import Foundation
import SwiftData

enum AppearanceMode: Int, Codable, CaseIterable, Identifiable {
    case system = 0
    case light = 1
    case dark = 2

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

@Model
final class AppSettings {
    // General
    var appearanceModeRaw: Int = 1

    // Flight Planner
    var openAllCardsSimultaneously: Bool = true

    // Polaroid Evidence
    var polaroidAutoSave: Bool = true

    // Crew Positions
    var additionalInfo: Bool = true
    var ramadan: Bool = false
    var languagesAndPAs: Bool = true
    var breakAutoCorrection: Bool = true
    var repeatedPositionsHighlight: Bool = true
    var positionsBadges: Bool = true
    var clickableHeaders: Bool = true

    init() {}

    var appearanceMode: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceModeRaw) ?? .system }
        set { appearanceModeRaw = newValue.rawValue }
    }
}
