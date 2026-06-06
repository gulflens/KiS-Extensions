import SwiftUI
import UIKit

// MARK: - Theme

/// Centralized design system for the KiS Extensions dashboard.
/// One source of truth for colors, spacing, radius, typography, and elevation.
/// All colors resolve correctly in Light and Dark appearance.

// MARK: - Hex Color Support

private extension UIColor {
    /// Create a UIColor from a 24-bit RGB hex value (e.g. 0x001F47).
    convenience init(rgb: UInt32) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        )
    }
}

private extension Color {
    /// Build an appearance-aware color from light and dark hex values.
    static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(rgb: dark)
                : UIColor(rgb: light)
        })
    }

    /// Build an appearance-aware color from explicit UIColors (used for alpha tints).
    static func dynamic(lightColor: UIColor, darkColor: UIColor) -> Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? darkColor : lightColor
        })
    }
}

// MARK: - App Color Tokens

enum AppColor {

    // MARK: Surfaces

    /// App background — warm graphite in light, deep navy-black in dark.
    static let background = Color.dynamic(light: 0xF4F5F7, dark: 0x07111F)
    /// Standard surface for panels and content blocks.
    static let surface = Color.dynamic(light: 0xFFFFFF, dark: 0x101826)
    /// Raised surface for cards that sit above `surface`.
    static let surfaceElevated = Color.dynamic(light: 0xFFFFFF, dark: 0x16202F)
    /// Recessed surface for inset wells, chips, and field backgrounds.
    static let surfaceSunken = Color.dynamic(light: 0xEDEEF1, dark: 0x0C1420)

    // MARK: Brand

    /// Primary Emirates navy. Constant across appearances — used for fills.
    static let navy = Color(UIColor(rgb: 0x001F47))
    /// Navy as a foreground accent — brightened in dark mode for legibility.
    static let navyAccent = Color.dynamic(light: 0x002A5C, dark: 0x6B97D6)
    /// Gold accent detail.
    static let gold = Color.dynamic(light: 0xC8A951, dark: 0xD4B968)

    // MARK: Text

    static let textPrimary = Color.dynamic(light: 0x0F172A, dark: 0xEAEEF4)
    static let textSecondary = Color.dynamic(light: 0x64748B, dark: 0x8C99AC)
    static let textTertiary = Color.dynamic(light: 0x94A3B8, dark: 0x5C6B7E)
    /// Text drawn on top of the constant navy hero surface.
    static let textOnNavy = Color(UIColor(rgb: 0xEAEEF4))
    static let textOnNavySecondary = Color(UIColor(white: 1, alpha: 0.62))

    // MARK: Lines

    /// Low-opacity navy-tinted border for cards and panels.
    static let border = Color.dynamic(
        lightColor: UIColor(rgb: 0x001F47).withAlphaComponent(0.10),
        darkColor: UIColor.white.withAlphaComponent(0.08)
    )
    /// Hairline divider between rows.
    static let separator = Color.dynamic(
        lightColor: UIColor.black.withAlphaComponent(0.06),
        darkColor: UIColor.white.withAlphaComponent(0.07)
    )

    // MARK: Status

    static let positive = Color.dynamic(light: 0x0E8A5F, dark: 0x2FBE86)
    static let warning = Color.dynamic(light: 0xC9821A, dark: 0xE3A23F)
    static let critical = Color.dynamic(light: 0xC8102E, dark: 0xE85567)
    static let info = Color.dynamic(light: 0x1E5FD6, dark: 0x6098F0)

    /// Vivid orange used to mark "today" in the day calendar strip.
    static let todayAccent = Color.dynamic(light: 0xF2682C, dark: 0xFF8A4E)

    // MARK: Hero Gradient

    /// Deep navy gradient for the operational hero card (constant in both modes).
    static let heroGradient = LinearGradient(
        colors: [Color(UIColor(rgb: 0x0A2A55)), Color(UIColor(rgb: 0x041A38))],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: Mini-App Accents

    /// Restrained per-module accent. Used only for thin lines, icons, and small details.
    static func accent(for id: FeatureID) -> Color {
        switch id {
        case .dashboard:           return navyAccent
        case .flightPlanner:       return .dynamic(light: 0x1E5FD6, dark: 0x6098F0) // sapphire
        case .ekCrewRest:          return .dynamic(light: 0xC8102E, dark: 0xE85567) // emirates red
        case .allocatePositions:   return .dynamic(light: 0x0E7C99, dark: 0x35B3D1) // cyan
        case .dxbAirport:          return .dynamic(light: 0x4338CA, dark: 0x8A80EE) // indigo
        case .polaroidEvidence:    return .dynamic(light: 0xB8923C, dark: 0xD4B968) // gold
        case .timeConverter:       return .dynamic(light: 0x0E8A5F, dark: 0x2FBE86) // emerald
        case .flightCrewChecklist: return .dynamic(light: 0x7A3CE0, dark: 0xA67CF0) // violet
        case .settings:            return .dynamic(light: 0x6B7280, dark: 0x9BA6B5) // titanium
        }
    }
}

// MARK: - Spacing Scale

enum AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
}

// MARK: - Corner Radius Scale

enum AppRadius {
    static let card: CGFloat = 22
    static let panel: CGFloat = 18
    static let control: CGFloat = 12
    static let chip: CGFloat = 10
}

// MARK: - Typography

extension Font {
    /// Large operational figures — countdowns, primary metrics.
    static let dashHeroNumber = Font.system(size: 36, weight: .bold, design: .rounded)
    /// Live clock readout.
    static let dashClockTime = Font.system(size: 30, weight: .bold, design: .rounded)
    /// Hero card title.
    static let dashHeroTitle = Font.system(size: 22, weight: .semibold)
    /// Standard card title.
    static let dashCardTitle = Font.system(size: 16, weight: .semibold)
    /// Numeric card metric (rounded, tabular).
    static let dashCardMetric = Font.system(size: 15, weight: .semibold, design: .rounded)
    /// Section header label.
    static let dashSectionTitle = Font.system(size: 13, weight: .semibold)
    /// Supporting body / description copy.
    static let dashBody = Font.system(size: 14, weight: .regular)
    /// Card metadata line.
    static let dashMetadata = Font.system(size: 13, weight: .medium)
    /// Small tracked operational label (apply `.tracking(0.8)` at use site).
    static let dashMicroLabel = Font.system(size: 11, weight: .semibold)
    /// Monospaced value for flight codes, times, registrations.
    static let dashMono = Font.system(size: 14, weight: .medium, design: .monospaced)
}

// MARK: - Elevation

/// Soft, restrained elevation for layered surfaces.
struct DashboardCardStyle: ViewModifier {
    var radius: CGFloat = AppRadius.card
    var elevated: Bool = true

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(elevated ? AppColor.surfaceElevated : AppColor.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(AppColor.border, lineWidth: 1)
            )
            .shadow(color: .black.opacity(elevated ? 0.10 : 0.05),
                    radius: elevated ? 14 : 6,
                    x: 0, y: elevated ? 8 : 3)
    }
}

extension View {
    /// Apply the standard layered dashboard card surface.
    func dashboardCard(radius: CGFloat = AppRadius.card, elevated: Bool = true) -> some View {
        modifier(DashboardCardStyle(radius: radius, elevated: elevated))
    }
}
