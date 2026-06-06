import Foundation

// MARK: - Fleet Entry

/// Loaded from `ek_fleet_v110.json`. Shape matches the v110 demo's fleetDB entries.
/// This file also bridges fleet data to the cross-check helper's strategy types.
struct FleetEntry: Codable, Hashable {
    let type: String           // "B777", "A380", "A350"
    let model: String          // "B777-300ER", "A350-900", "A380-800"
    let variant: String        // "3C-Refit", "4C-484", etc.
    let configuration: String
    let classes: Int           // 2, 3, 4
    let capacity: Int
    let hasFC: Bool
    let crc: String?           // "CRC", "MD-CRC", "LD-CRC", or nil
    let hasCrewSeats: Bool
    let note: String?

    /// "B777-300ER · 3 Class · CRC + curtains" — mirrors aircraftLabel() in the demo.
    var displayLabel: String {
        var parts: [String] = [model, "\(classes) Class"]
        if let crc { parts.append(crc) }
        if hasCrewSeats && crc == nil { parts.append("Curtains") }
        if !hasCrewSeats && crc == nil { parts.append("No rest") }
        return parts.joined(separator: " · ")
    }

    var aircraftLabel: String {
        var rest: String
        if let crc {
            rest = hasCrewSeats ? "\(crc) + Crew seats" : crc
        } else {
            rest = hasCrewSeats ? "Crew seats" : "No rest facility"
        }
        return "\(model) · \(rest)"
    }

    /// Facility options the demo allows the user to choose between.
    var facilityOptions: [Facility] {
        var out: [Facility] = []
        switch crc {
        case "CRC":    out.append(.crc)
        case "MD-CRC": out.append(.mdCrc)
        case "LD-CRC": out.append(.ldCrc)
        default: break
        }
        if hasCrewSeats { out.append(.crewSeats) }
        return out
    }
}

// MARK: - Facility

/// Rest facility category — same four buckets the demo uses.
enum Facility: String, Codable, CaseIterable, Identifiable, Hashable {
    case crc       = "CRC"
    case mdCrc     = "MD-CRC"
    case ldCrc     = "LD-CRC"
    case crewSeats = "CrewSeats"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .crc:       return "CRC"
        case .mdCrc:     return "MD-CRC"
        case .ldCrc:     return "LD-CRC"
        case .crewSeats: return "Crew seats"
        }
    }

    static func options(for aircraft: String) -> [Facility] {
        switch aircraft {
        case "A380": return [.ldCrc, .mdCrc, .crewSeats]
        default:     return [.crc, .crewSeats]
        }
    }

    /// Number of equal rest blocks for this facility (matches breaksForFacility() in the demo).
    var numBreaks: Int {
        switch self {
        case .crc:       return 2
        case .mdCrc:     return 3
        case .ldCrc:     return 2
        case .crewSeats: return 4
        }
    }
}

// MARK: - Bridge to cross-check strategy types

extension FleetEntry {

    var aircraftKind: AircraftKind {
        switch type {
        case "B777": return .b777
        case "A380": return .a380
        case "A350": return .a350
        default:     return .a350
        }
    }

    var b777Variant: B777Variant? {
        guard type == "B777" else { return nil }
        let v = variant.uppercased()
        if v.hasPrefix("200LR") { return .v200LR }
        if v.hasPrefix("300LR") || v.contains("ULR") { return .v300LR }
        if v.hasPrefix("300")   { return .v300 }
        if v.hasPrefix("200")   { return .v200 }
        return nil
    }

    /// Maps fleet's facility to the cross-check resolver's RestFacility.
    func crossCheckFacility(selected: Facility) -> RestFacility {
        switch selected {
        case .crc:       return .crc
        case .mdCrc:     return .mdcrc
        case .ldCrc:     return .ldcrc
        case .crewSeats: return .hardBlocked
        }
    }
}
