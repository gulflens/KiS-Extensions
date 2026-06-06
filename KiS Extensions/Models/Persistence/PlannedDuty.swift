import Foundation
import SwiftUI
import SwiftData

// MARK: - Duty Category

/// Coarse classification used for colouring and grouping on the calendar.
/// The portal exposes many fine-grained sub-types (XX, XXR, XXH, XXC, SA0200,
/// SL08, S06, etc.) — those are preserved as `PlannedDuty.code`, while this
/// enum is the bucket the UI renders.
enum DutyCategory: String, Codable, CaseIterable {
    case dayOff           // XX, XXR, XXH, XXC
    case available        // AVD
    case airportStandby   // SA****
    case homeStandby      // S** (non-airport, non-high-quality)
    case highQualityStandby // SL**
    case groundDuty       // anything else under data-trip-type="training"
    case other

    var label: String {
        switch self {
        case .dayOff: return "Day Off"
        case .available: return "Available"
        case .airportStandby: return "Airport SBY"
        case .homeStandby: return "Standby"
        case .highQualityStandby: return "HQ Standby"
        case .groundDuty: return "Ground Duty"
        case .other: return "Duty"
        }
    }

    /// Short tag shown on the day cell when the day has no trip.
    var shortCode: String {
        switch self {
        case .dayOff: return "XX"
        case .available: return "AVD"
        case .airportStandby: return "ASB"
        case .homeStandby: return "SBY"
        case .highQualityStandby: return "HQ"
        case .groundDuty: return "GD"
        case .other: return "D"
        }
    }

    /// Soft pastel background for the duty chip on the calendar strip.
    /// Chip text uses dark navy on top of these for readability.
    var color: Color {
        switch self {
        case .dayOff:             return Color(red: 0xE6/255.0, green: 0xC0/255.0, blue: 0xBF/255.0) // soft pink
        case .available:          return Color(red: 0xCD/255.0, green: 0xED/255.0, blue: 0xC1/255.0) // soft green
        case .airportStandby:     return Color(red: 0xBF/255.0, green: 0xD9/255.0, blue: 0xEE/255.0) // pale blue
        case .homeStandby:        return Color(red: 0xBF/255.0, green: 0xE8/255.0, blue: 0xEE/255.0) // pale teal
        case .highQualityStandby: return Color(red: 0xC3/255.0, green: 0xBF/255.0, blue: 0xEE/255.0) // pale lavender
        case .groundDuty:         return Color(red: 0xEE/255.0, green: 0xCF/255.0, blue: 0xBF/255.0) // pale apricot
        case .other:              return Color(red: 0xDC/255.0, green: 0xDC/255.0, blue: 0xDC/255.0) // pale gray
        }
    }
}

// MARK: - Planned Duty

/// Non-flight roster entry: day off, standby, available-duty day, ground duty.
/// One row per duty on a calendar day. Flights live in `PlannedFlight`.
@Model
final class PlannedDuty {
    var id: UUID = UUID()

    /// Start-of-day calendar date the duty falls on (for fast day-equality).
    var date: Date = Date()

    /// Portal short code: "XX", "AVD", "SA0200", "SL08", "S06", "XXR", etc.
    var code: String = ""

    /// Bucket the UI renders from. Stored as a raw string to keep SwiftData happy.
    var categoryRaw: String = DutyCategory.other.rawValue

    /// Original human-readable label from the portal (e.g. "AIRPORT STANDBY AT 02:00").
    var title: String = ""

    /// Optional "HH:mm" start / end times for timed duties (standbys).
    var startTime: String?
    var endTime: String?

    /// Absolute start / end moments parsed from the portal's data-content,
    /// in device local time. Helpful for "active now" queries.
    var startDate: Date?
    var endDate: Date?

    /// User-editable notes — never overwritten on resync.
    var notes: String = ""

    /// Sync timestamp from the most recent import.
    var lastSyncedAt: Date = Date()

    var category: DutyCategory {
        get { DutyCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        date: Date,
        code: String,
        category: DutyCategory,
        title: String,
        startTime: String? = nil,
        endTime: String? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        notes: String = "",
        lastSyncedAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.code = code
        self.categoryRaw = category.rawValue
        self.title = title
        self.startTime = startTime
        self.endTime = endTime
        self.startDate = startDate
        self.endDate = endDate
        self.notes = notes
        self.lastSyncedAt = lastSyncedAt
    }
}

// MARK: - Code → Category Classifier

enum DutyClassifier {
    /// Maps a portal short code (case-insensitive, may include digits) to a
    /// `DutyCategory`. Defaults to `.groundDuty` for anything under the
    /// `data-trip-type="training"` umbrella that we don't recognise yet.
    static func category(forCode rawCode: String) -> DutyCategory {
        let code = rawCode.uppercased()
        if code == "XX" || code.hasPrefix("XX") {
            return .dayOff
        }
        if code == "AVD" {
            return .available
        }
        if code.hasPrefix("SA") {
            return .airportStandby
        }
        if code.hasPrefix("SL") {
            return .highQualityStandby
        }
        if code.hasPrefix("S") && code.count >= 2 && code.dropFirst().allSatisfy(\.isNumber) {
            return .homeStandby
        }
        return .groundDuty
    }
}
