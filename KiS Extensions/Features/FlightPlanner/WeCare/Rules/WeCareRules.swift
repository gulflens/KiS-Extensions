import Foundation

// MARK: - We Care Rule Base
//
// Decodable mirror of `we_care_rules_v1_30.json`, encoding the We Care matrix,
// cabin deltas and category rules from the Cabin Crew Service Training Manual,
// Ch. 11 Crew Duties & Galley Management, V1.30 (24APR2026).
//
// SOURCE INCONSISTENCY — DO NOT "FIX":
// The manual's generic intro line states cycles run "every 30 min", but the
// operative Economy (YCL) figures in the same section are a 45-minute interval
// split 15 + 15 + 15. YCL is therefore intentionally encoded as 45 in the JSON.
// Do not change it back to 30 to match the generic intro line.
//
// AIRCRAFT KEYS:
// The manual's crew matrix says "B777 = 2", but this app's fleet data models
// the 777 family as "B772" and "B773" (there is no "B777"). JCL crew is
// therefore keyed by the actual fleet model strings: A380 = 4, B773 = 2,
// B772 = 2, A350 = 2. Premium Economy (WCL) is carried on A350 and 4-class
// aircraft; its crew is manual (supervisor-entered), so it is not keyed here.

// MARK: - Cabin Code

enum WeCareCabinCode: String, Codable, CaseIterable, Identifiable {
    case YCL
    case WCL
    case JCL
    case FCL

    var id: String { rawValue }
}

// MARK: - Refreshment Style

enum WeCareRefreshmentStyle: String, Codable {
    case cart
    case tray
}

// MARK: - Crew Spec

enum WeCareCrewMode: String, Codable {
    case fixed
    case manual
}

/// How a cabin's per-cycle crew count is determined. Fixed cabins resolve from
/// the rule base (JCL by aircraft, FCL a flat value); manual cabins (YCL, WCL)
/// require a supervisor-entered count captured elsewhere.
struct WeCareCrewSpec: Codable {
    let mode: WeCareCrewMode
    /// Fixed crew per aircraft family key (e.g. "A380", "B777", "A350"). JCL only.
    let byAircraft: [String: Int]?
    /// Flat fixed crew count irrespective of aircraft. FCL only.
    let value: Int?
    /// Guidance shown to the supervisor for manual cabins.
    let manualHint: String?
}

// MARK: - Duties

struct WeCareDuties: Codable {
    let cleanliness: Int
    let customerCare: Int
    let refreshments: Int
}

// MARK: - Timing

enum WeCareTimingMode: String, Codable {
    /// Runs as a rotation between and after meal services (suspended for them).
    case betweenServices
    /// Ongoing rotation starting after take-off.
    case ongoingAfterTakeoff
}

/// A category band mapped to a timing mode (FCL splits by flight category).
struct WeCareCategoryTiming: Codable {
    let from: Int
    let to: Int
    let mode: WeCareTimingMode

    func contains(_ category: Int) -> Bool {
        (from...to).contains(category)
    }
}

/// A cabin's cycle timing: either uniform across categories, or split by
/// category band (FCL: cat 1 to 3 between services, cat 4 to 8 ongoing).
enum WeCareTiming: Codable {
    case uniform(WeCareTimingMode)
    case byCategory([WeCareCategoryTiming])

    private enum CodingKeys: String, CodingKey { case byCategory }

    init(from decoder: Decoder) throws {
        // The JSON value is either a bare mode string or an object carrying a
        // "byCategory" array.
        if let single = try? decoder.singleValueContainer(),
           let mode = try? single.decode(WeCareTimingMode.self) {
            self = .uniform(mode)
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let bands = try container.decode([WeCareCategoryTiming].self, forKey: .byCategory)
        self = .byCategory(bands)
    }

    func encode(to encoder: Encoder) throws {
        switch self {
        case .uniform(let mode):
            var single = encoder.singleValueContainer()
            try single.encode(mode)
        case .byCategory(let bands):
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(bands, forKey: .byCategory)
        }
    }

    /// The effective timing mode for a given flight category.
    func mode(for category: Int) -> WeCareTimingMode {
        switch self {
        case .uniform(let mode):
            return mode
        case .byCategory(let bands):
            return bands.first(where: { $0.contains(category) })?.mode ?? .betweenServices
        }
    }
}

// MARK: - Cabin Rule

struct WeCareCabinRule: Codable, Identifiable {
    let code: WeCareCabinCode
    let cycleIntervalMinutes: Int
    let duties: WeCareDuties
    let refreshmentStyle: WeCareRefreshmentStyle
    let refreshmentMinCategory: Int
    let crew: WeCareCrewSpec
    let timing: WeCareTiming
    let notes: String?

    var id: WeCareCabinCode { code }

    /// Resolved per-cycle crew for fixed cabins. Returns `nil` for manual
    /// cabins (YCL, WCL) — the caller must supply a supervisor-entered count.
    func fixedCrew(forAircraft aircraftKey: String) -> Int? {
        guard crew.mode == .fixed else { return nil }
        if let value = crew.value { return value }
        return crew.byAircraft?[aircraftKey]
    }

    /// Whether the refreshments duty applies for a given flight category.
    func refreshmentsApply(category: Int) -> Bool {
        category >= refreshmentMinCategory
    }
}

// MARK: - Rule Base Root

struct WeCareRules: Codable {
    let version: Int
    let sourceVersion: String
    /// Inclusive [min, max] flight-category band that requires the We Care e-form.
    let eFormCategories: [Int]
    /// Governance and suspension rules, verbatim for the printable guideline.
    let governanceRules: [String]
    let cabins: [WeCareCabinRule]

    func cabin(_ code: WeCareCabinCode) -> WeCareCabinRule? {
        cabins.first { $0.code == code }
    }

    /// The We Care completion e-form is required for these categories (3 to 8).
    func eFormRequired(category: Int) -> Bool {
        guard eFormCategories.count == 2 else { return false }
        return (eFormCategories[0]...eFormCategories[1]).contains(category)
    }
}
