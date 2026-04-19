import Foundation
import Observation

// MARK: - Crew Rest State

/// Observable state container for the EK Crew Rest mini-app.
/// Renamed from the porter's `AppState` to avoid colliding with the main-app `AppState`.
@Observable
final class CrewRestState {

    // MARK: - UserDefaults persistence

    private static let defaults = UserDefaults.standard
    private static let prefix = "crewRest_"

    private static func key(_ name: String) -> String { prefix + name }

    /// Restores a previously saved state, or returns a fresh instance with defaults.
    static func restored() -> CrewRestState {
        let s = CrewRestState()
        let d = defaults

        if d.object(forKey: key("takeoffMin")) != nil {
            s.takeoffMin     = d.integer(forKey: key("takeoffMin"))
            s.flightMin      = d.integer(forKey: key("flightMin"))
            s.registration   = d.string(forKey: key("registration")) ?? ""
            s.aircraft       = d.string(forKey: key("aircraft")) ?? "B777"
            s.hasFC          = d.bool(forKey: key("hasFC"))
            s.facility       = Facility(rawValue: d.string(forKey: key("facility")) ?? "") ?? .crc
            s.settlingMin    = d.integer(forKey: key("settlingMin"))
            s.numServices    = d.integer(forKey: key("numServices"))
            s.fcAllowOverlap = d.bool(forKey: key("fcAllowOverlap"))
            s.fcStartAfterTO = d.integer(forKey: key("fcStartAfterTO"))
            s.fcEndBuffer    = d.integer(forKey: key("fcEndBuffer"))

            s.breakStartOverride = d.bool(forKey: key("breakStartOverride"))
            s.breakStartMin = d.integer(forKey: key("breakStartMin"))

            if let seq = d.string(forKey: key("mdCrcSequence")) {
                s.mdCrcSequence = MDCrcSequence(rawValue: seq) ?? .srsrrs
            }

            if let data = d.array(forKey: key("services")) as? [Int], data.count == 3 {
                s.services = data
            }
        }

        return s
    }

    /// Persists all user-editable fields to UserDefaults.
    func save() {
        let d = Self.defaults

        d.set(takeoffMin,              forKey: Self.key("takeoffMin"))
        d.set(flightMin,               forKey: Self.key("flightMin"))
        d.set(registration,            forKey: Self.key("registration"))
        d.set(aircraft,                forKey: Self.key("aircraft"))
        d.set(hasFC,                   forKey: Self.key("hasFC"))
        d.set(facility.rawValue,       forKey: Self.key("facility"))
        d.set(settlingMin,             forKey: Self.key("settlingMin"))
        d.set(numServices,             forKey: Self.key("numServices"))
        d.set(services,                forKey: Self.key("services"))
        d.set(mdCrcSequence.rawValue,  forKey: Self.key("mdCrcSequence"))
        d.set(breakStartOverride,      forKey: Self.key("breakStartOverride"))
        d.set(breakStartMin,           forKey: Self.key("breakStartMin"))
        d.set(fcAllowOverlap,          forKey: Self.key("fcAllowOverlap"))
        d.set(fcStartAfterTO,          forKey: Self.key("fcStartAfterTO"))
        d.set(fcEndBuffer,             forKey: Self.key("fcEndBuffer"))
    }

    // MARK: - Flight inputs

    /// Take-off in minutes from midnight. Default 14:30 → 870.
    var takeoffMin: Int = 14 * 60 + 30

    /// Total scheduled flight time in minutes. Default 7h 30m.
    var flightMin: Int = 7 * 60 + 30

    // MARK: - Aircraft / facility

    /// Three-letter registration suffix (the part after "A6-"). Uppercase.
    var registration: String = ""

    /// Selected aircraft family — set automatically when registration matches a fleet entry,
    /// or manually via the segmented control.
    var aircraft: String = "B777"

    var hasFC: Bool = true

    var fcAvailable: Bool {
        (aircraft == "B777" && facility == .crc) || (aircraft == "A380" && facility == .ldCrc)
    }

    /// Selected rest facility.
    var facility: Facility = .crc

    // MARK: - Settling

    /// Settling-in duration in minutes (only applies when flight > 4h).
    var settlingMin: Int = 30

    // MARK: - Services

    var numServices: Int = 2

    /// Three service durations in minutes. Only the first `numServices` are used.
    var services: [Int] = [90, 90, 90]

    // MARK: - MD-CRC Sequence

    /// When MD-CRC + 3 services: which sequence to use.
    /// `.srsrrs` = S1 R1 S2 R2 R3 S3,  `.srrsrs` = S1 R1 R2 S2 R3 S3.
    var mdCrcSequence: MDCrcSequence = .srsrrs

    // MARK: - Break override

    var breakStartOverride: Bool = false
    var breakStartMin: Int = 0

    // MARK: - First Class

    var fcAllowOverlap: Bool = true
    var fcStartAfterTO: Int = 60
    var fcEndBuffer:    Int = 90

    /// Most recently computed result, if any.
    var result: CalculationResult?

    // MARK: - Derived

    /// Service duration values currently exposed to the user (cap to numServices).
    var activeServices: [Int] { Array(services.prefix(numServices)) }

    /// Returns the matching fleet entry for the current registration, or nil.
    var matchedFleet: FleetEntry? {
        FleetLoader.shared.entry(forSuffix: registration)
    }

    /// Header summary like "B777 · CRC".
    var headerSummary: String {
        if let m = matchedFleet {
            return m.displayLabel
        }
        return "\(aircraft) · \(facility.label)"
    }
}

// MARK: - MD-CRC Sequence

enum MDCrcSequence: String, CaseIterable, Identifiable, Hashable {
    case srsrrs
    case srrsrs

    var id: String { rawValue }

    var label: String {
        switch self {
        case .srsrrs: return "S-R-S-R-R-S"
        case .srrsrs: return "S-R-R-S-R-S"
        }
    }
}
