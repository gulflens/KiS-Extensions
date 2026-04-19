import SwiftUI

// MARK: - Crew Rest Theme

/// Colour and spacing tokens for the EK Crew Rest mini-app.
/// Matches the demo HTML 1:1 (CSS variables --emirates-red, --service, --rest, --settle, etc.).
/// Renamed from the porter's `Theme` to keep the namespace clean inside the host project.
enum CRTheme {
    static let ekRed     = Color(red: 0xD7/255, green: 0x19/255, blue: 0x21/255)
    static let ekRedDark = Color(red: 0xA8/255, green: 0x12/255, blue: 0x1A/255)
    static let accent    = Color(red: 0x00/255, green: 0x7A/255, blue: 0xFF/255)

    // Timeline block colours (--service / --rest / --settle in dark + light)
    static let service   = Color(red: 0x00/255, green: 0x7A/255, blue: 0xFF/255)
    static let rest      = Color(red: 0x34/255, green: 0xC7/255, blue: 0x59/255)
    static let settle    = Color(red: 0xFF/255, green: 0x95/255, blue: 0x00/255)

    // FC card background (--card-fc bg)
    static let fcCardBg  = Color(red: 0xFF/255, green: 0xFB/255, blue: 0xEB/255)

    // Surface / spacing tokens
    static let cardCorner: CGFloat = 14
    static let cardPadH: CGFloat = 14
    static let cardPadV: CGFloat = 12
}
