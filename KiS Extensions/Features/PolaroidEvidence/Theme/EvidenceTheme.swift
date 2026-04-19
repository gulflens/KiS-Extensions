import SwiftUI

// MARK: - Evidence Theme

/// Feature-scoped colour tokens for Polaroid Evidence.
///
/// Mirrors the per-feature theme pattern used by `CrewRestTheme`. When a
/// shared brand-token system is introduced these values should be replaced
/// with references to it.
enum EvidenceTheme {

    // MARK: Brand

    static let brandNavy = Color(red: 0x00 / 255.0, green: 0x1F / 255.0, blue: 0x47 / 255.0)
    static let brandGold = Color(red: 0xC8 / 255.0, green: 0xA9 / 255.0, blue: 0x51 / 255.0)

    // MARK: Surfaces

    static let desktopBackground = Color(red: 0xF4 / 255.0, green: 0xF1 / 255.0, blue: 0xEA / 255.0)
    static let libraryBackground = Color(red: 0x2D / 255.0, green: 0x2D / 255.0, blue: 0x2D / 255.0)

    // MARK: Category tints

    static let seatDefect            = Color(red: 0xC0 / 255.0, green: 0x39 / 255.0, blue: 0x2B / 255.0)
    static let cabinDefect           = brandNavy
    static let foodIssue             = Color(red: 0x2E / 255.0, green: 0x86 / 255.0, blue: 0x4E / 255.0)
    static let nonStandardEquipment  = brandGold
    static let other                 = Color(red: 0x6B / 255.0, green: 0x6F / 255.0, blue: 0x76 / 255.0)
}
