import Foundation

// MARK: - We Care Schedule Models (Stage 2)
//
// Pure value types consumed and produced by the schedule engine. These are
// deliberately persistence-free; Stage 3 adds a SwiftData model that maps to
// and from `WeCareFlightContext`.
//
// All times are integer minutes on a single monotonic timeline (e.g. minutes
// from midnight). The caller guarantees landing > take-off (adding 1440 to a
// past-midnight landing if needed) and supplies meal-service blocks on the
// same timeline.

// MARK: - Meal Service Block

struct WeCareMealBlock: Equatable {
    let start: Int
    let end: Int
}

// MARK: - Flight Context (engine input)

struct WeCareFlightContext {
    /// Aircraft family key matching the rule base (e.g. "A380", "B777", "A350").
    var aircraftKey: String
    /// Flight category, 1 to 8.
    var flightCategory: Int
    /// Cabins operating on this sector, in display order.
    var operatingCabins: [WeCareCabinCode]
    /// Take-off, on the shared minutes timeline.
    var takeoffMinute: Int
    /// Landing, on the shared minutes timeline (must be greater than take-off).
    var landingMinute: Int
    /// Meal-service blocks during which cycles are suspended.
    var mealServiceBlocks: [WeCareMealBlock]
    /// Time reserved before landing for before-landing duties (descent prep).
    var beforeLandingBufferMinutes: Int
    /// Supervisor-entered per-cycle crew for manual cabins (YCL, WCL).
    var manualCrew: [WeCareCabinCode: Int]

    init(
        aircraftKey: String,
        flightCategory: Int,
        operatingCabins: [WeCareCabinCode],
        takeoffMinute: Int,
        landingMinute: Int,
        mealServiceBlocks: [WeCareMealBlock] = [],
        beforeLandingBufferMinutes: Int = 30,
        manualCrew: [WeCareCabinCode: Int] = [:]
    ) {
        self.aircraftKey = aircraftKey
        self.flightCategory = flightCategory
        self.operatingCabins = operatingCabins
        self.takeoffMinute = takeoffMinute
        self.landingMinute = landingMinute
        self.mealServiceBlocks = mealServiceBlocks
        self.beforeLandingBufferMinutes = beforeLandingBufferMinutes
        self.manualCrew = manualCrew
    }
}

// MARK: - Duty Leg

enum WeCareDutyKind: String, Equatable {
    case cleanliness
    case customerCare
    case refreshments

    /// British-English label for display and print.
    var label: String {
        switch self {
        case .cleanliness:  return "Cleanliness"
        case .customerCare: return "Customer Care"
        case .refreshments: return "Refreshments"
        }
    }
}

struct WeCareDutyLeg: Equatable {
    let kind: WeCareDutyKind
    let durationMinutes: Int
}

// MARK: - Cycle Window

struct WeCareCycleWindow: Equatable {
    let cabin: WeCareCabinCode
    /// 1-based cycle number within the cabin.
    let index: Int
    let start: Int
    let end: Int
    /// Resolved per-cycle crew for the cabin.
    let crewCount: Int
    /// Ordered duty legs (Cleanliness, Customer Care, Refreshments — subset).
    let legs: [WeCareDutyLeg]
    /// A reduced cycle run when time is short before landing.
    let isCleanlinessOnly: Bool
    /// Whether the We Care completion e-form is required (categories 3 to 8).
    let eFormRequired: Bool
}

// MARK: - Cabin Schedule

struct WeCareCabinSchedule: Equatable {
    let cabin: WeCareCabinCode
    let crewCount: Int
    let timing: WeCareTimingMode
    let cycles: [WeCareCycleWindow]
}

// MARK: - Schedule (engine output)

struct WeCareSchedule: Equatable {
    let cabins: [WeCareCabinSchedule]

    func cabin(_ code: WeCareCabinCode) -> WeCareCabinSchedule? {
        cabins.first { $0.cabin == code }
    }
}

// MARK: - Errors

enum WeCareScheduleError: Error, Equatable {
    case invalidCategory(Int)
    case invalidWindow
    case unknownCabinRule(WeCareCabinCode)
    case noFixedCrewForAircraft(WeCareCabinCode, aircraft: String)
    case missingManualCrew(WeCareCabinCode)

    /// British-English, user-facing explanation.
    var message: String {
        switch self {
        case .invalidCategory(let c):
            return "Flight category \(c) is not valid. Enter a category from 1 to 8."
        case .invalidWindow:
            return "Landing time must be after take-off time."
        case .unknownCabinRule(let cabin):
            return "No We Care rule found for the \(cabin.rawValue) cabin."
        case .noFixedCrewForAircraft(let cabin, let aircraft):
            return "No \(cabin.rawValue) crew figure is defined for aircraft \(aircraft)."
        case .missingManualCrew(let cabin):
            return "Enter the number of \(cabin.rawValue) crew per cycle before generating the schedule."
        }
    }
}
