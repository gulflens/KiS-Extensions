// MARK: - DXBGuide Models
// Schema version: 0.2.0
// Last updated: 2026-05-04
//
// Decoding via JSONDecoder() with default key strategy.
// Loader should index Bay records by BOTH bayId AND gateId for dual-search.

import Foundation

// MARK: - Common

struct Coordinates: Codable, Hashable {
    let lat: Double?
    let lng: Double?
}

enum Confidence: String, Codable {
    case high, medium, low, stub
}

// MARK: - Bay (Stand)

struct Bay: Codable, Identifiable, Hashable {
    /// Internal ground ops bay identifier (e.g. "A06", "D05", "F18", "REMOTE_A6")
    let bayId: String

    /// Public-facing gate identifier (e.g. "A24", "A12", "B13")
    /// Optional - some bays exist without an active gate (e.g. B07 in Concourse C)
    let gateId: String?

    /// Pre-renumbering gate label (e.g. "217" for old crew context)
    let oldGateId: String?

    let concourse: Concourse
    let terminal: String
    let type: BayType
    let stand: StandSpec
    let biometricBoarding: Bool
    let aircraftCapability: [String]
    let bridges: BridgeInfo
    let hasStairs: Bool

    /// Operational state for remote stands
    let operationalStatus: OperationalStatus?

    let _confidence: Confidence
    let _sources: [String]?
    let _notes: String?

    // Identifiable conformance
    var id: String { bayId }

    // Convenience
    var isContact: Bool { type == .contact }
    var isA380Capable: Bool { aircraftCapability.contains("A380") }
    var hasUpperDeckBridge: Bool { bridges.hasUpperDeckBridge ?? false }
    var hasDuda: Bool { stand.duda ?? false }

    /// Display string combining bay and gate for crew familiarity
    var displayLabel: String {
        if let gate = gateId, gate != bayId {
            return "Bay \(bayId) (Gate \(gate))"
        }
        return bayId
    }
}

enum BayType: String, Codable { case contact, remote }

enum Concourse: String, Codable, CaseIterable {
    /// T3 — Emirates west pier (gates A1-A24).
    case A
    /// T3 — Emirates centre pier, attached to T3 main (gates B1-B32).
    case B
    /// T3 — formerly Concourse 1, Emirates only since 2016 (gates C1-C50).
    case C
    /// T1 — Concourse D, non-Emirates international (gates D1-D32).
    /// Connected to T1 main via APM. Opened 2016.
    case D
    /// T2 — standalone terminal (gates F1-F12), all bus-boarded remote stands.
    /// Primarily flydubai + regional carriers.
    case F
    /// Apron G — east-side remote parking apron (not a passenger concourse).
    /// Stands G01-G22 used for overnight parking, maintenance staging,
    /// charter, and overflow positions adjacent to the Royal Airwing.
    /// Modelled here as a "concourse" because the schema field acts as
    /// a zone identifier.
    case G
    /// Apron E — north-side apron. Hosts T2's actual aircraft parking
    /// positions (E04-E13) that the F1-F12 boarding lounges bus to,
    /// plus the General Aviation overflow positions (E30-E38).
    case E
    /// Apron H — Dubai Royal Air Wing terminal and hangar area at the
    /// far east end of the airport. H01-H02 are the terminal gates,
    /// H03-H04 are hangar-adjacent positions.
    case H
    /// Apron Q — north-central apron near the Emirates Technical Centre.
    /// Q01-Q11 are EK maintenance staging positions.
    case Q
    /// Apron S — additional remote stand area. Specific operational
    /// purpose not publicly documented; stand IDs S01-S15 sourced from
    /// the IFATC sim database.
    case S

    // MARK: Display

    /// Full descriptive name for the zone tile (e.g. "Concourse A",
    /// "Apron G", "Concourse D · T1").
    var displayName: String {
        switch self {
        case .A, .B, .C:    return "Concourse \(rawValue)"
        case .D:            return "Concourse D · T1"
        case .F:            return "Concourse F · T2"
        case .E, .G, .H, .Q, .S: return "Apron \(rawValue)"
        }
    }

    /// Short qualifier that fits in narrow grid tiles. Identifies the
    /// terminal for passenger concourses, otherwise "Apron".
    var compactName: String {
        switch self {
        case .A, .B, .C:    return "T3"
        case .D:            return "T1"
        case .F:            return "T2"
        case .E, .G, .H, .Q, .S: return "Apron"
        }
    }

    /// One-line context shown under the zone name in the browse grid.
    var subtitle: String {
        switch self {
        case .A: return "T3 · Emirates west pier"
        case .B: return "T3 · Emirates centre pier"
        case .C: return "T3 · Emirates east pier"
        case .D: return "T1 · Non-Emirates international"
        case .F: return "T2 · flydubai and regional"
        case .E: return "Remote · north apron / GA"
        case .G: return "Remote · east apron"
        case .H: return "Royal Air Wing"
        case .Q: return "Maintenance · EK Tech Centre"
        case .S: return "Remote · other"
        }
    }
}

enum OperationalStatus: String, Codable {
    case open, closed, hybridClosed
}

struct StandSpec: Codable, Hashable {
    /// "E" = wide-body non-A380. "F" = A380 capable.
    let code: String

    /// Dual Upper Deck Access. True = upper-deck bridge for A380 boarding.
    /// Null = unknown / not specified by source
    let duda: Bool?

    /// True for remote stands where pax walk apron-side directly to aircraft (no bus)
    let directBoarding: Bool?

    var isA380Capable: Bool { code == "F" }
}

struct BridgeInfo: Codable, Hashable {
    /// Total jetbridge count. Null = not specified by source.
    let totalCount: Int?

    /// Upper-deck bridge for A380 (same as stand.duda for clarity at point of use)
    let hasUpperDeckBridge: Bool?
}

// MARK: - Bay container (for JSON top-level)

struct BayCatalog: Codable {
    let bays: [Bay]
}

// MARK: - Lounge

struct Lounge: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let `operator`: LoungeOperator
    let kind: LoungeKind
    let terminal: String
    let concourse: Concourse
    let level: String?
    let nearestGate: String?
    let entranceDescription: String?
    let openingHours: String
    let directBoarding: Bool?
    let amenities: [String]
    let areaSqm: Int?
    let capacityPax: Int?
    let accessRules: AccessRules

    let _confidence: Confidence
    let _sources: [String]?
    let _notes: String?
}

enum LoungeOperator: String, Codable {
    case emirates, marhaba, ahlan, plazaPremium
}

enum LoungeKind: String, Codable {
    case first, business, shared, thirdParty
}

// MARK: - Access Rules

struct AccessRules: Codable, Hashable {
    let denyConditions: [AccessPredicate]?
    let complimentary: [ComplimentaryRule]?
    let paidAccess: [PaidAccessRule]?
}

struct ComplimentaryRule: Codable, Hashable {
    let match: AccessPredicate
    let guests: GuestEntitlement?
    let _note: String?
    let _source: String?
    let _confidence: Confidence?
}

struct PaidAccessRule: Codable, Hashable {
    let match: AccessPredicate
    let approxPriceUSD: Double?
    let approxPriceAED: Double?
    let _note: String?
    let _confidence: Confidence?
}

/// Predicate against a PassengerContext.
/// Each non-nil field must match. Nil = "don't care".
struct AccessPredicate: Codable, Hashable {
    let cabinClass: StringOrArray?
    let skywardsTier: StringOrArray?
    let skywardsSkysurfer: StringOrArray?
    let skywardsMember: Bool?
    let `operator`: String?
    let journeyType: String?
    let anyPax: Bool?
}

struct GuestEntitlement: Codable, Hashable {
    let adults: Int
    let childrenUnder17: Int
}

// MARK: - StringOrArray helper

enum StringOrArray: Codable, Hashable {
    case single(String)
    case multiple([String])

    var values: [String] {
        switch self {
        case .single(let s): return [s]
        case .multiple(let arr): return arr
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let s = try? container.decode(String.self) {
            self = .single(s); return
        }
        let arr = try container.decode([String].self)
        self = .multiple(arr)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .single(let s): try container.encode(s)
        case .multiple(let arr): try container.encode(arr)
        }
    }
}

// MARK: - PassengerContext (input to access engine)

struct PassengerContext: Hashable {
    var cabinClass: CabinClass
    var skywardsTier: SkywardsTier
    var skywardsSkysurfer: SkywardsTier?
    var operatingCarrier: String       // "EK", "FZ", "QF", "UA"
    var journeyType: JourneyType
    var partnerStatus: String?
    var requestedGuests: GuestRequest

    struct GuestRequest: Hashable {
        var adults: Int = 0
        var childrenUnder17: Int = 0
    }
}

enum CabinClass: String, Codable, CaseIterable {
    case F, J, W, Y
}

enum SkywardsTier: String, Codable, CaseIterable {
    case Blue, Silver, Gold, Platinum, iO
}

enum JourneyType: String, Codable {
    case originating, connecting, arriving
}

// MARK: - Lounge Access Decision (output)

enum LoungeAccessDecision: Hashable {
    case allowed(reason: String, guests: GuestEntitlement?)
    case allowedWithLimitedGuests(maxAdults: Int, maxChildren: Int, reason: String)
    case paidOnly(approxPriceUSD: Double?, approxPriceAED: Double?, reason: String)
    case denied(reason: String)
}

// MARK: - Routing Graph

struct RoutingGraph: Codable {
    let nodes: [GraphNode]
    let edges: [GraphEdge]
}

struct GraphNode: Codable, Identifiable, Hashable {
    let id: String
    let kind: GraphNodeKind
    let label: String?
    let concourse: Concourse?
    let coordinates: Coordinates?
    let _confidence: Confidence?
}

enum GraphNodeKind: String, Codable {
    case gate, waypoint, trainStation, lounge
}

struct GraphEdge: Codable, Hashable {
    let from: String
    let to: String
    let kind: EdgeKind
    let timeSeconds: Double?
    let distanceMeters: Double?
    let frequencyMinutes: Double?
    let oneWay: Bool?
    let notes: String?
    let _confidence: Confidence?
}

enum EdgeKind: String, Codable {
    case walk, train, stairs, elevator
}

// MARK: - Routing Result

struct RouteResult: Hashable {
    let segments: [RouteSegment]
    var totalSeconds: Double { segments.map(\.timeSeconds).reduce(0, +) }
    var verdict: RouteVerdict
}

struct RouteSegment: Hashable {
    let kind: EdgeKind
    let from: String
    let to: String
    let timeSeconds: Double
    let humanLabel: String   // e.g. "Walk to APM station — 4 min"
}

enum RouteVerdict: Hashable {
    case comfortable          // > 25 min before departure
    case tight(minutesSpare: Int)
    case unrealistic(reason: String)
}

// MARK: - Bay Lookup Helper

extension BayCatalog {
    /// Build a dictionary indexed by both bayId AND gateId.
    /// Allows search by either identifier.
    func buildLookupIndex() -> [String: Bay] {
        var index: [String: Bay] = [:]
        for bay in bays {
            index[bay.bayId.uppercased()] = bay
            if let gate = bay.gateId {
                // Don't overwrite if bayId == gateId
                if index[gate.uppercased()] == nil {
                    index[gate.uppercased()] = bay
                }
            }
            if let oldGate = bay.oldGateId {
                index[oldGate.uppercased()] = bay
            }
        }
        return index
    }

    /// Filter bays by concourse
    func bays(in concourse: Concourse) -> [Bay] {
        bays.filter { $0.concourse == concourse }
    }

    /// Find by either bay id, gate id, or old gate id (case-insensitive)
    func find(query: String) -> Bay? {
        let normalised = query.uppercased().trimmingCharacters(in: .whitespaces)
        return bays.first { bay in
            bay.bayId.uppercased() == normalised
                || bay.gateId?.uppercased() == normalised
                || bay.oldGateId?.uppercased() == normalised
        }
    }
}
