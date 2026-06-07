import Foundation
import SwiftData

// MARK: - We Care Config (Stage 3 — persisted input)
//
// One saved We Care configuration per planned sector. Keyed by the sector's
// id (no SwiftData relationship) so it stays CloudKit-safe and does not couple
// to the shared PlannedSector schema. All properties are optional / defaulted
// for CloudKit lightweight migration.

@Model
final class WeCareConfig {

    /// Links to `PlannedSector.id`.
    var sectorID: UUID?

    /// Aircraft family/model key matching the rule base (e.g. "A380", "B773").
    var aircraftKey: String?
    /// Flight category, 1 to 8.
    var flightCategory: Int?
    /// Operating cabins as `WeCareCabinCode` raw values.
    var operatingCabinCodes: [String]?

    /// Take-off / landing as minutes from midnight (Dubai time).
    var takeoffMinute: Int?
    var landingMinute: Int?
    var beforeLandingBufferMinutes: Int?

    /// Meal-service blocks, JSON-encoded `[WeCareMealBlock]`.
    var mealBlocksData: Data?

    /// Supervisor-entered per-cycle crew for the manual cabins.
    var manualYCLCrew: Int?
    var manualWCLCrew: Int?

    var updatedAt: Date?

    init(sectorID: UUID) {
        self.sectorID = sectorID
        self.beforeLandingBufferMinutes = 30
        self.flightCategory = 5
        self.updatedAt = Date()
    }

    // MARK: - Operating Cabins

    var operatingCabins: [WeCareCabinCode] {
        get { (operatingCabinCodes ?? []).compactMap { WeCareCabinCode(rawValue: $0) } }
        set { operatingCabinCodes = newValue.map(\.rawValue) }
    }

    func isOperating(_ cabin: WeCareCabinCode) -> Bool {
        operatingCabins.contains(cabin)
    }

    func setOperating(_ cabin: WeCareCabinCode, _ on: Bool) {
        var set = operatingCabins
        set.removeAll { $0 == cabin }
        if on { set.append(cabin) }
        // Keep a stable cabin order (First to Economy).
        operatingCabins = WeCareCabinCode.allCases.filter { set.contains($0) }
    }

    // MARK: - Meal Blocks

    var mealBlocks: [WeCareMealBlock] {
        get {
            guard let data = mealBlocksData else { return [] }
            return (try? JSONDecoder().decode([WeCareMealBlock].self, from: data)) ?? []
        }
        set {
            mealBlocksData = try? JSONEncoder().encode(newValue.sorted { $0.start < $1.start })
        }
    }

    // MARK: - Context Mapping

    /// Build the engine input from the saved values, filling sensible defaults.
    /// Validation (including missing manual crew) is performed by the engine.
    func makeContext() -> WeCareFlightContext {
        var landing = landingMinute ?? 0
        let takeoff = takeoffMinute ?? 0
        if landing <= takeoff { landing += 24 * 60 } // landing after midnight

        var manual: [WeCareCabinCode: Int] = [:]
        if let y = manualYCLCrew { manual[.YCL] = y }
        if let w = manualWCLCrew { manual[.WCL] = w }

        return WeCareFlightContext(
            aircraftKey: aircraftKey ?? "",
            flightCategory: flightCategory ?? 0,
            operatingCabins: operatingCabins,
            takeoffMinute: takeoff,
            landingMinute: landing,
            mealServiceBlocks: mealBlocks,
            beforeLandingBufferMinutes: beforeLandingBufferMinutes ?? 30,
            manualCrew: manual
        )
    }
}

// MARK: - Cabin Availability

/// Maps an aircraft model and class count to the cabins it operates, so the
/// input form can default the operating cabins (Premium Economy appears on
/// A350 and 4-class aircraft).
enum WeCareCabinAvailability {
    static func cabins(model: String, classes: Int) -> [WeCareCabinCode] {
        switch (model, classes) {
        case ("A350", _):
            return [.JCL, .WCL, .YCL]
        case (_, 2):
            return [.JCL, .YCL]
        case (_, 3):
            return [.FCL, .JCL, .YCL]
        case (_, 4):
            return [.FCL, .JCL, .WCL, .YCL]
        default:
            return [.JCL, .YCL]
        }
    }
}
