import SwiftUI

// MARK: - Strategy Types (shared with FleetEntry)

enum AircraftKind: String, Codable, Hashable { case b777 = "B777", a380 = "A380", a350 = "A350" }
enum B777Variant: String, Codable, Hashable { case v200 = "200", v200LR = "200LR", v300 = "300", v300LR = "300LR" }

enum RestFacility: String, Codable, Hashable {
    case hardBlocked = "HardBlocked"
    case crc = "CRC"
    case mdcrc = "MDCRC"
    case ldcrc = "LDCRC"
    case bunks9 = "9bunks"
    case bunks12 = "12bunks"

    var displayLabel: String {
        switch self {
        case .hardBlocked: return "Hard-blocked"
        case .crc:         return "CRC"
        case .mdcrc:       return "MD-CRC"
        case .ldcrc:       return "LD-CRC"
        case .bunks9:      return "CRC (9 bunks)"
        case .bunks12:     return "CRC (12 bunks)"
        }
    }
}

// MARK: - Flight Category

enum FlightCategory: String, CaseIterable, Identifiable {
    case lrv    = "LRV"
    case nonLRV = "Non-LRV"
    case ccap   = "CCAP"
    var id: String { rawValue }
}

// MARK: - Guide Data Types

struct GuideGroup: Identifiable {
    var id: String { "\(name)-\(crewCount)" }
    let name: String
    let crewCount: Int
    let lines: [String]
}

struct GuideStrategy: Identifiable {
    var id: String { title }
    let title: String
    let groups: [GuideGroup]
    let fcNote: String?
    let notes: [String]
}

// MARK: - Rest Timing Tables

enum RestTimings {

    struct Row: Identifiable {
        var id: String { blockTime }
        let blockTime: String
        let duration: String
    }

    static let lrvRegulatory: [Row] = [
        Row(blockTime: "Under 14 hrs *", duration: "2 hr"),
        Row(blockTime: "14 hr – 14 hr 59 min", duration: "3 hr"),
        Row(blockTime: "15 hr – 15 hr 59 min", duration: "3 hr 30 min"),
        Row(blockTime: "16 hrs and above", duration: "4 hr"),
    ]

    struct CCAPSector: Identifiable {
        var id: String { sector }
        let sector: String
        let rest: String
    }

    static let ccapSectors: [CCAPSector] = [
        CCAPSector(sector: "DXB – CKY", rest: "3 hr"),
        CCAPSector(sector: "NRT – DXB", rest: "3 hr"),
        CCAPSector(sector: "HND – DXB", rest: "3 hr"),
        CCAPSector(sector: "BCN – MEX EK 255 (winter)", rest: "3 hr"),
    ]

    static let nonRegHardBlocked: [Row] = [
        Row(blockTime: "9 hr 30 min – 13 hr 59 min (non-augmenting)", duration: "1 hr – 1 hr 30 min"),
    ]

    static let nonRegMealBreak: [(blockTime: String, duration: String, location: String)] = [
        ("Up to 3 hr 59 min", "Meal break only", "Jump seats"),
        ("4 hr – 9 hr 29 min", "45 min – 1 hr", "Jump seats or soft-blocked seats"),
    ]

    static func minimumRestLRV(blockMinutes: Int) -> String {
        if blockMinutes >= 16 * 60 { return "4 hr" }
        if blockMinutes >= 15 * 60 { return "3 hr 30 min" }
        if blockMinutes >= 14 * 60 { return "3 hr" }
        return "2 hr"
    }
}

// MARK: - Strategy Database

enum StrategyDB {

    // MARK: LRV B777 CRC

    static let lrv_b777_200_2c_crc = GuideStrategy(
        title: "LRV B777-200 · 2 Class · CRC",
        groups: [
            GuideGroup(name: "Group 1", crewCount: 6, lines: [
                "J Class – 2 GR1",
                "Y Class – CSV / 3 GR2",
            ]),
            GuideGroup(name: "Group 2", crewCount: 6, lines: [
                "Purser",
                "J Class – 2 GR1",
                "Y Class – 3 GR2",
            ]),
        ],
        fcNote: nil, notes: []
    )

    static let lrv_b777_200_3c_crc = GuideStrategy(
        title: "LRV B777-200 · 3 Class (J, W and Y) · CRC",
        groups: [
            GuideGroup(name: "Group 1", crewCount: 6, lines: [
                "J Class – 2 GR1",
                "W Class – 1 GR2",
                "Y Class – CSV / 2 GR2",
            ]),
            GuideGroup(name: "Group 2", crewCount: 7, lines: [
                "Purser",
                "J Class – 2 GR1",
                "W Class – 1 GR2",
                "Y Class – 3 GR2",
            ]),
        ],
        fcNote: nil, notes: []
    )

    static let lrv_b777_300_3c_crc = GuideStrategy(
        title: "LRV B777-300 · 3 Class (F, J and Y) · CRC",
        groups: [
            GuideGroup(name: "Group 1", crewCount: 6, lines: [
                "J Class – CSV / 2 GR1",
                "Y Class – 3 GR2",
            ]),
            GuideGroup(name: "Group 2", crewCount: 6, lines: [
                "J Class – 2 GR1",
                "Y Class – CSV / 3 GR2",
            ]),
        ],
        fcNote: nil, notes: []
    )

    static let lrv_b777_300_4c_crc = GuideStrategy(
        title: "LRV B777-300 · 4 Class · CRC",
        groups: [
            GuideGroup(name: "Group 1", crewCount: 7, lines: [
                "J Class – CSV / 2 GR1",
                "W Class – 1 GR2",
                "Y Class – 3 GR2",
            ]),
            GuideGroup(name: "Group 2", crewCount: 6, lines: [
                "J Class – 2 GR1",
                "W Class – 1 GR2",
                "Y Class – CSV / 2 GR2",
            ]),
        ],
        fcNote: "F Class – split into 3 groups\nCan start rest before other cabins\n1 FG1 · 1 FG1 · 1 FG1",
        notes: ["On flights with 3 FG1s, Purser to be paired with an FG1 member for breaks according to service demands."]
    )

    // MARK: LRV A380 MD-CRC

    static let lrv_a380_3c_mdcrc = GuideStrategy(
        title: "LRV A380 · 3 Class · MD-CRC",
        groups: [
            GuideGroup(name: "Group 1", crewCount: 9, lines: [
                "F Class – 1 FG1 / CSA",
                "J Class – CSV / 1 GR1",
                "Y Class – CSV / 4 GR2",
                "CSA",
            ]),
            GuideGroup(name: "Group 2", crewCount: 6, lines: [
                "Purser",
                "F Class – 1 FG1",
                "J Class – 4 GR1",
            ]),
            GuideGroup(name: "Group 3", crewCount: 9, lines: [
                "F Class – 1 FG1",
                "J Class – 3 GR1",
                "Y Class – CSV / 4 GR2",
            ]),
        ],
        fcNote: nil, notes: []
    )

    static let lrv_a380_4c_mdcrc = GuideStrategy(
        title: "LRV A380 · 4 Class · MD-CRC",
        groups: [
            GuideGroup(name: "Group 1", crewCount: 9, lines: [
                "F Class – 1 FG1 / CSA",
                "J Class – CSV / 1 GR1",
                "W Class – 1 GR2",
                "Y Class – CSV / 3 GR2",
                "CSA",
            ]),
            GuideGroup(name: "Group 2", crewCount: 7, lines: [
                "Purser",
                "F Class – 1 FG1",
                "J Class – 4 GR1",
                "W Class – CSV / 1 GR2",
            ]),
            GuideGroup(name: "Group 3", crewCount: 9, lines: [
                "F Class – 1 FG1",
                "J Class – 3 GR1",
                "W Class – CSV",
                "Y Class – 4 GR2",
            ]),
        ],
        fcNote: nil, notes: []
    )

    // MARK: LRV A380 LD-CRC

    static let lrv_a380_3c_ldcrc = GuideStrategy(
        title: "LRV A380 · 3 Class · LD-CRC",
        groups: [
            GuideGroup(name: "Group 1", crewCount: 11, lines: [
                "J Class – CSV / 4 GR1",
                "Y Class – CSV / 4 GR2",
                "CSA",
            ]),
            GuideGroup(name: "Group 2", crewCount: 10, lines: [
                "Purser",
                "J Class – 4 GR1",
                "Y Class – CSV / 4 GR2",
            ]),
        ],
        fcNote: nil, notes: []
    )

    static let lrv_a380_4c_ldcrc = GuideStrategy(
        title: "LRV A380 · 4 Class · LD-CRC",
        groups: [
            GuideGroup(name: "Group 1", crewCount: 11, lines: [
                "J Class – CSV / 4 GR1",
                "W Class – 1 GR2",
                "Y Class – CSV / 3 GR2",
                "CSA",
            ]),
            GuideGroup(name: "Group 2", crewCount: 11, lines: [
                "Purser",
                "J Class – 4 GR1",
                "W Class – CSV / 1 GR2",
                "Y Class – 4 GR2",
            ]),
        ],
        fcNote: "F Class – split into 3 groups\nCan start rest before other cabins\n1 FG1 · 1 FG1 · 1 FG1",
        notes: []
    )

    // MARK: LRV A350 CRC

    static let lrv_a350_3c_crc = GuideStrategy(
        title: "LRV A350 · CRC",
        groups: [
            GuideGroup(name: "Group 1", crewCount: 6, lines: [
                "J Class – 2 GR1",
                "W Class – CSV",
                "Y Class – CSV / 2 GR2",
            ]),
            GuideGroup(name: "Group 2", crewCount: 7, lines: [
                "Purser",
                "J Class – 2 GR1",
                "W Class – 1 GR2",
                "Y Class – 3 GR2",
            ]),
        ],
        fcNote: nil, notes: []
    )

    // MARK: Specific LRV MD-CRC (IAD and YYZ)

    static let lrv_a380_mdcrc_iad_yyz = GuideStrategy(
        title: "Specific LRV · MD-CRC · DXB–IAD (EK 231) and DXB–YYZ (EK 241)",
        groups: [
            GuideGroup(name: "Group 1", crewCount: 9, lines: [
                "F Class – 1 FG1 / CSA",
                "J Class – CSV / 4 GR1",
                "Y Class – CSV / 1 GR2",
            ]),
            GuideGroup(name: "Group 2", crewCount: 7, lines: [
                "Purser",
                "F Class – 1 FG1",
                "J Class – 2 GR1",
                "Y Class – 3 GR2",
            ]),
            GuideGroup(name: "Group 3", crewCount: 8, lines: [
                "F Class – 1 FG1",
                "J Class – 2 GR1",
                "Y Class – CSV / 4 GR2",
            ]),
        ],
        fcNote: nil, notes: []
    )

    // MARK: CCAP B777-200 LR CRC

    static let ccap_b777_200lr_2c_crc = GuideStrategy(
        title: "CCAP B777-200 LR · 2 Class · CRC",
        groups: [
            GuideGroup(name: "Group 1", crewCount: 6, lines: [
                "J Class – 2 GR1",
                "Y Class – CSV / 3 GR2",
            ]),
            GuideGroup(name: "Group 2", crewCount: 6, lines: [
                "Purser",
                "J Class – 2 GR1",
                "Y Class – 3 GR2",
            ]),
        ],
        fcNote: nil, notes: []
    )

    static let ccap_b777_200lr_3c_crc = GuideStrategy(
        title: "CCAP B777-200 LR · 3 Class · CRC (Note 1)",
        groups: [
            GuideGroup(name: "Group 1", crewCount: 6, lines: [
                "J Class – 2 GR1",
                "W Class – 1 GR2",
                "Y Class – CSV / 2 GR2",
            ]),
            GuideGroup(name: "Group 2", crewCount: 6, lines: [
                "Purser",
                "J Class – 2 GR1",
                "W Class – 1 GR2",
                "Y Class – 2 GR2",
            ]),
        ],
        fcNote: nil,
        notes: ["Applicable only during winter schedule 26OCT – 29MAR. On EK 255 BCN/MEX sector (3 Class), while the first group is having their rest, Purser or one GR1 crew to remain in WC/YC to ensure Premium Economy and Economy Class have 4 crew members collectively to meet customer needs at all times."]
    )

    // MARK: CCAP Generic

    static let ccap_b777_300_crc = GuideStrategy(
        title: "CCAP B777-300 · CRC",
        groups: [
            GuideGroup(name: "Group 1", crewCount: 0, lines: [
                "50% of crew including CSV(s) and Business Class galley operator",
            ]),
            GuideGroup(name: "Group 2", crewCount: 0, lines: [
                "Remaining crew including purser",
            ]),
        ],
        fcNote: nil,
        notes: ["When no CRC, refer to OM-A 7.7.1.2"]
    )

    static let ccap_a380_crc = GuideStrategy(
        title: "CCAP A380 · CRC",
        groups: [
            GuideGroup(name: "Group 1", crewCount: 0, lines: [
                "50% of crew including CSV(s) and Business Class galley operator",
            ]),
            GuideGroup(name: "Group 2", crewCount: 0, lines: [
                "Remaining crew including purser",
            ]),
        ],
        fcNote: nil,
        notes: [
            "When no CRC, refer to OM-A 7.7.1.2",
            "Refer to the rest strategy for MD-CRC 4 Class LRV (9 Bunks)",
        ]
    )

    // MARK: Non-LRV B777 Hard-Blocked

    static let nonlrv_b777_200_2c_hb = GuideStrategy(
        title: "Non-LRV B777-200 · 2 Class · Hard-Blocked",
        groups: [
            GuideGroup(name: "Group 1", crewCount: 4, lines: [
                "J Class – 1 GR1",
                "Y Class – CSV / 2 GR2",
            ]),
            GuideGroup(name: "Group 2", crewCount: 4, lines: [
                "J Class – 2 GR1",
                "Y Class – 2 GR2",
            ]),
            GuideGroup(name: "Group 3", crewCount: 4, lines: [
                "Purser",
                "J Class – 1 GR1",
                "Y Class – 2 GR2",
            ]),
        ],
        fcNote: nil, notes: []
    )

    static let nonlrv_b777_200_3c_hb = GuideStrategy(
        title: "Non-LRV B777-200 · 3 Class · Hard-Blocked",
        groups: [
            GuideGroup(name: "Group 1", crewCount: 4, lines: [
                "J Class – 1 GR1",
                "W Class – 1 GR2",
                "Y Class – CSV / 1 GR2",
            ]),
            GuideGroup(name: "Group 2", crewCount: 4, lines: [
                "J Class – 2 GR1",
                "W Class – 1 GR2",
                "Y Class – 1 GR2",
            ]),
            GuideGroup(name: "Group 3", crewCount: 4, lines: [
                "Purser",
                "J Class – 1 GR1",
                "Y Class – 2 GR2",
            ]),
        ],
        fcNote: nil, notes: []
    )

    static let nonlrv_b777_300_2c_hb = GuideStrategy(
        title: "Non-LRV B777-300 · 2 Class · Hard-Blocked",
        groups: [
            GuideGroup(name: "Group 1", crewCount: 3, lines: [
                "J Class – 1 GR1",
                "Y Class – 2 GR2",
            ]),
            GuideGroup(name: "Group 2", crewCount: 4, lines: [
                "J Class – 1 GR1",
                "Y Class – CSV / 2 GR2",
            ]),
            GuideGroup(name: "Group 3", crewCount: 4, lines: [
                "J Class – 2 GR1",
                "Y Class – 2 GR2",
            ]),
            GuideGroup(name: "Group 4", crewCount: 3, lines: [
                "Purser",
                "Y Class – 2 GR2",
            ]),
        ],
        fcNote: nil, notes: []
    )

    static let nonlrv_b777_300_3c_hb = GuideStrategy(
        title: "Non-LRV B777-300 · 3 Class · Hard-Blocked",
        groups: [
            GuideGroup(name: "Group 1", crewCount: 4, lines: [
                "F Class – 1 FG1",
                "J Class – 1 GR1",
                "Y Class – 2 GR2",
            ]),
            GuideGroup(name: "Group 2", crewCount: 4, lines: [
                "F Class – 1 FG1",
                "J Class – CSV / 1 GR1",
                "Y Class – 1 GR2",
            ]),
            GuideGroup(name: "Group 3", crewCount: 4, lines: [
                "J Class – 1 GR1",
                "Y Class – CSV / 2 GR2",
            ]),
            GuideGroup(name: "Group 4", crewCount: 3, lines: [
                "Purser",
                "J Class – 1 GR1",
                "Y Class – 1 GR2",
            ]),
        ],
        fcNote: nil, notes: []
    )

    static let nonlrv_b777_300_4c_hb = GuideStrategy(
        title: "Non-LRV B777-300 · 4 Class · Hard-Blocked",
        groups: [
            GuideGroup(name: "Group 1", crewCount: 4, lines: [
                "F Class – 1 FG1",
                "J Class – 1 GR1",
                "Y Class – 2 GR2",
            ]),
            GuideGroup(name: "Group 2", crewCount: 4, lines: [
                "F Class – 1 FG1",
                "J Class – CSV / 1 GR1",
                "Y Class – 1 GR2",
            ]),
            GuideGroup(name: "Group 3", crewCount: 4, lines: [
                "J Class – 1 GR1",
                "W Class – 1 GR2",
                "Y Class – CSV / 1 GR2",
            ]),
            GuideGroup(name: "Group 4", crewCount: 4, lines: [
                "Purser",
                "J Class – 1 GR1",
                "W Class – 1 GR2",
                "Y Class – 1 GR2",
            ]),
        ],
        fcNote: nil, notes: []
    )

    // MARK: Non-LRV B777 CRC

    static let nonlrv_b777_200lr_2c_crc = GuideStrategy(
        title: "Non-LRV B777-200 LR · 2 Class · CRC",
        groups: [
            GuideGroup(name: "Group 1", crewCount: 6, lines: [
                "J Class – 2 GR1",
                "Y Class – CSV / 3 GR2",
            ]),
            GuideGroup(name: "Group 2", crewCount: 6, lines: [
                "Purser",
                "J Class – 2 GR1",
                "Y Class – 3 GR2",
            ]),
        ],
        fcNote: nil, notes: []
    )

    static let nonlrv_b777_200lr_3c_crc = GuideStrategy(
        title: "Non-LRV B777-200 LR · 3 Class · CRC (Note 1)",
        groups: [
            GuideGroup(name: "Group 1", crewCount: 6, lines: [
                "J Class – 2 GR1",
                "W Class – 1 GR2",
                "Y Class – CSV / 2 GR2",
            ]),
            GuideGroup(name: "Group 2", crewCount: 6, lines: [
                "Purser",
                "J Class – 2 GR1",
                "W Class – 1 GR2",
                "Y Class – 2 GR2",
            ]),
        ],
        fcNote: nil,
        notes: ["On B777-200 LR 3 class, Purser or 1 GR1 to be in WC/YC during 1st break to ensure they have 4 crew at any time in WC and YC collectively."]
    )

    static let nonlrv_b777_300lr_3c_crc = GuideStrategy(
        title: "Non-LRV B777-300 LR · 3 Class · CRC",
        groups: [
            GuideGroup(name: "Group 1", crewCount: 6, lines: [
                "J Class – CSV / 2 GR1",
                "Y Class – 3 GR2",
            ]),
            GuideGroup(name: "Group 2", crewCount: 6, lines: [
                "J Class – 2 GR1",
                "Y Class – CSV / 3 GR2",
            ]),
        ],
        fcNote: nil, notes: []
    )

    static let nonlrv_b777_300lr_4c_crc = GuideStrategy(
        title: "Non-LRV B777-300 LR · 4 Class · CRC",
        groups: [
            GuideGroup(name: "Group 1", crewCount: 8, lines: [
                "J Class – CSV / 2 GR1",
                "W Class – 1 GR2",
                "Y Class – 3 GR2",
            ]),
            GuideGroup(name: "Group 2", crewCount: 7, lines: [
                "J Class – 2 GR1",
                "W Class – 1 GR2",
                "Y Class – CSV / 2 GR2",
            ]),
        ],
        fcNote: "F Class – split into 3 groups\nCan start rest before other cabins\n1 FG1 · 1 FG1 · Purser",
        notes: []
    )

    // MARK: Non-LRV A380 Hard-Blocked

    static let nonlrv_a380_2c_hb = GuideStrategy(
        title: "Non-LRV A380 · 2 Class · Hard-Blocked",
        groups: [
            GuideGroup(name: "Group 1", crewCount: 5, lines: [
                "J Class – 2 GR1",
                "Y Class – CSV / 2 GR2",
            ]),
            GuideGroup(name: "Group 2", crewCount: 5, lines: [
                "J Class – CSV / 1 GR1",
                "Y Class – 3 GR2",
            ]),
            GuideGroup(name: "Group 3", crewCount: 6, lines: [
                "J Class – 2 GR1",
                "Y Class – CSV / 3 GR2",
            ]),
            GuideGroup(name: "Group 4", crewCount: 6, lines: [
                "Purser",
                "J Class – 2 GR1",
                "Y Class – 3 GR2",
            ]),
        ],
        fcNote: nil, notes: []
    )

    static let nonlrv_a380_3c_hb = GuideStrategy(
        title: "Non-LRV A380 · 3 Class · Hard-Blocked",
        groups: [
            GuideGroup(name: "Group 1", crewCount: 6, lines: [
                "F Class – 1 FG1 / CSA",
                "J Class – 2 GR1",
                "Y Class – 2 GR2",
            ]),
            GuideGroup(name: "Group 2", crewCount: 6, lines: [
                "F Class – 1 FG1",
                "J Class – CSV / 2 GR1",
                "Y Class – 2 GR2",
            ]),
            GuideGroup(name: "Group 3", crewCount: 6, lines: [
                "F Class – 1 FG1",
                "J Class – 2 GR1",
                "Y Class – CSV / 2 GR2",
            ]),
            GuideGroup(name: "Group 4", crewCount: 6, lines: [
                "Purser",
                "J Class – 2 GR1",
                "Y Class – 3 GR2",
            ]),
        ],
        fcNote: nil, notes: []
    )

    static let nonlrv_a380_4c_hb = GuideStrategy(
        title: "Non-LRV A380 · 4 Class · Hard-Blocked",
        groups: [
            GuideGroup(name: "Group 1", crewCount: 6, lines: [
                "F Class – 1 FG1",
                "J Class – 2 GR1",
                "W Class – CSV",
                "Y Class – 2 GR2",
                "(CSA can start rest before other cabins)",
            ]),
            GuideGroup(name: "Group 2", crewCount: 6, lines: [
                "F Class – 1 FG1",
                "J Class – CSV / 2 GR1",
                "W Class – 1 GR2",
                "Y Class – 1 GR2",
            ]),
            GuideGroup(name: "Group 3", crewCount: 6, lines: [
                "F Class – 1 FG1",
                "J Class – 2 GR1",
                "W Class – 1 GR2",
                "Y Class – CSV / 1 GR2",
            ]),
            GuideGroup(name: "Group 4", crewCount: 6, lines: [
                "Purser",
                "J Class – 2 GR1",
                "Y Class – 3 GR2",
            ]),
        ],
        fcNote: nil, notes: []
    )

    // MARK: Non-LRV A380 CRC 9 Bunks

    static let nonlrv_a380_3c_9bunks = GuideStrategy(
        title: "Non-LRV A380 · 3 Class · CRC (9 Bunks)",
        groups: [
            GuideGroup(name: "Group 1", crewCount: 9, lines: [
                "F Class – 1 FG1 / CSA",
                "J Class – 3 GR1",
                "Y Class – CSV / 3 GR2",
            ]),
            GuideGroup(name: "Group 2", crewCount: 7, lines: [
                "F Class – 1 FG1",
                "J Class – CSV / 2 GR1",
                "Y Class – 3 GR2",
            ]),
            GuideGroup(name: "Group 3", crewCount: 8, lines: [
                "Purser",
                "F Class – 1 FG1",
                "J Class – 3 GR1",
                "Y Class – 3 GR2",
            ]),
        ],
        fcNote: nil, notes: []
    )

    static let nonlrv_a380_4c_9bunks = GuideStrategy(
        title: "Non-LRV A380 · 4 Class · CRC (9 Bunks)",
        groups: [
            GuideGroup(name: "Group 1", crewCount: 9, lines: [
                "F Class – 1 FG1 / CSA",
                "J Class – 3 GR1",
                "W Class – 1 GR2",
                "Y Class – CSV / 2 GR2",
            ]),
            GuideGroup(name: "Group 2", crewCount: 8, lines: [
                "F Class – 1 FG1",
                "J Class – CSV / 2 GR1",
                "W Class – CSV",
                "Y Class – 3 GR2",
            ]),
            GuideGroup(name: "Group 3", crewCount: 8, lines: [
                "Purser",
                "F Class – 1 FG1",
                "J Class – 3 GR1",
                "W Class – 1 GR2",
                "Y Class – 2 GR2",
            ]),
        ],
        fcNote: nil, notes: []
    )

    // MARK: Non-LRV A380 CRC 12 Bunks

    static let nonlrv_a380_3c_12bunks = GuideStrategy(
        title: "Non-LRV A380 · 3 Class · CRC (12 Bunks)",
        groups: [
            GuideGroup(name: "Group 1", crewCount: 11, lines: [
                "J Class – CSV / 4 GR1",
                "Y Class – 5 GR2",
                "CSA",
            ]),
            GuideGroup(name: "Group 2", crewCount: 10, lines: [
                "Purser",
                "J Class – 4 GR1",
                "Y Class – CSV / 4 GR2",
            ]),
        ],
        fcNote: nil, notes: []
    )

    static let nonlrv_a380_4c_12bunks = GuideStrategy(
        title: "Non-LRV A380 · 4 Class · CRC (12 Bunks)",
        groups: [
            GuideGroup(name: "Group 1", crewCount: 11, lines: [
                "J Class – CSV / 4 GR1",
                "W Class – CSV / 1 GR2",
                "Y Class – 3 GR2",
                "CSA",
            ]),
            GuideGroup(name: "Group 2", crewCount: 11, lines: [
                "Purser",
                "J Class – 4 GR1",
                "W Class – 1 GR2",
                "Y Class – CSV / 4 GR2",
            ]),
        ],
        fcNote: "F Class – split into 3 groups\nCan start rest before other cabins\n1 FG1 · 1 FG1 · 1 FG1",
        notes: []
    )

    // MARK: Non-LRV A350 Hard-Blocked

    static let nonlrv_a350_3c_hb = GuideStrategy(
        title: "Non-LRV A350 · Hard-Blocked",
        groups: [
            GuideGroup(name: "Group 1", crewCount: 5, lines: [
                "J Class – 2 GR1",
                "W Class – 1 GR2",
                "Y Class – 2 GR2",
            ]),
            GuideGroup(name: "Group 2", crewCount: 5, lines: [
                "J Class – 1 GR1",
                "W Class – 1 GR2",
                "Y Class – CSV / 2 GR2",
            ]),
            GuideGroup(name: "Group 3", crewCount: 3, lines: [
                "Purser",
                "J Class – 1 GR1",
                "Y Class – 1 GR2",
            ]),
        ],
        fcNote: nil, notes: []
    )

    // MARK: Lookup

    static func lookup(
        flightCategory: FlightCategory,
        aircraft: AircraftKind,
        variant: B777Variant?,
        classes: Int,
        facility: RestFacility
    ) -> GuideStrategy? {

        switch flightCategory {

        case .lrv:
            switch aircraft {
            case .b777:
                switch (variant, classes) {
                case (.v200, 2), (nil, 2):             return lrv_b777_200_2c_crc
                case (.v200, 3), (.v200, _):           return lrv_b777_200_3c_crc
                case (.v300, 3), (.v300LR, 3):         return lrv_b777_300_3c_crc
                case (.v300, 4), (.v300LR, 4), (.v300, _), (.v300LR, _): return lrv_b777_300_4c_crc
                case (.v200LR, 2):                     return lrv_b777_200_2c_crc
                case (.v200LR, _):                     return lrv_b777_200_3c_crc
                default:                               return lrv_b777_200_2c_crc
                }
            case .a380:
                switch facility {
                case .mdcrc: return classes >= 4 ? lrv_a380_4c_mdcrc : lrv_a380_3c_mdcrc
                case .ldcrc: return classes >= 4 ? lrv_a380_4c_ldcrc : lrv_a380_3c_ldcrc
                default:     return classes >= 4 ? lrv_a380_4c_mdcrc : lrv_a380_3c_mdcrc
                }
            case .a350:
                return lrv_a350_3c_crc
            }

        case .nonLRV:
            switch aircraft {
            case .b777:
                if facility == .hardBlocked {
                    switch (variant, classes) {
                    case (.v200, 2), (nil, 2):                return nonlrv_b777_200_2c_hb
                    case (.v200, _):                          return nonlrv_b777_200_3c_hb
                    case (.v300, 2):                          return nonlrv_b777_300_2c_hb
                    case (.v300, 3):                          return nonlrv_b777_300_3c_hb
                    case (.v300, 4), (.v300, _):              return nonlrv_b777_300_4c_hb
                    case (.v300LR, 3):                        return nonlrv_b777_300_3c_hb
                    case (.v300LR, 4), (.v300LR, _):          return nonlrv_b777_300_4c_hb
                    default:                                  return nonlrv_b777_200_2c_hb
                    }
                } else {
                    switch (variant, classes) {
                    case (.v200LR, 2):                        return nonlrv_b777_200lr_2c_crc
                    case (.v200LR, _):                        return nonlrv_b777_200lr_3c_crc
                    case (.v300LR, 3):                        return nonlrv_b777_300lr_3c_crc
                    case (.v300LR, 4), (.v300LR, _):          return nonlrv_b777_300lr_4c_crc
                    case (.v300, _):                          return nonlrv_b777_300lr_3c_crc
                    case (.v200, 2), (nil, 2):                return nonlrv_b777_200lr_2c_crc
                    default:                                  return nonlrv_b777_200lr_2c_crc
                    }
                }
            case .a380:
                switch facility {
                case .hardBlocked:
                    if classes >= 4 { return nonlrv_a380_4c_hb }
                    if classes == 3 { return nonlrv_a380_3c_hb }
                    return nonlrv_a380_2c_hb
                case .bunks9, .mdcrc:
                    return classes >= 4 ? nonlrv_a380_4c_9bunks : nonlrv_a380_3c_9bunks
                case .bunks12, .ldcrc:
                    return classes >= 4 ? nonlrv_a380_4c_12bunks : nonlrv_a380_3c_12bunks
                default:
                    return classes >= 4 ? nonlrv_a380_4c_9bunks : nonlrv_a380_3c_9bunks
                }
            case .a350:
                return nonlrv_a350_3c_hb
            }

        case .ccap:
            switch aircraft {
            case .b777:
                if variant == .v200LR {
                    return classes >= 3 ? ccap_b777_200lr_3c_crc : ccap_b777_200lr_2c_crc
                }
                return ccap_b777_300_crc
            case .a380:
                return ccap_a380_crc
            case .a350:
                return nil
            }
        }
    }
}

// MARK: - Helper Sheet

struct CrewRestHelperSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(CrewRestState.self) private var state

    @State private var flightCategory: FlightCategory = .lrv

    private var fleet: FleetEntry? { state.matchedFleet }

    private var resolvedStrategy: GuideStrategy? {
        guard let f = fleet else { return nil }
        return StrategyDB.lookup(
            flightCategory: flightCategory,
            aircraft: f.aircraftKind,
            variant: f.b777Variant,
            classes: f.classes,
            facility: f.crossCheckFacility(selected: state.facility)
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    flightInfoCard
                    flightTypeSelector
                    restTimingCard
                    if let strategy = resolvedStrategy {
                        strategyCard(strategy)
                    } else if fleet == nil {
                        emptyState
                    }
                    guidanceCard
                    sourceFooter
                }
                .padding(14)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Crew Rest Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.fontWeight(.medium)
                }
            }
        }
        .onAppear { autoDetectFlightType() }
    }

    private func autoDetectFlightType() {
        if state.flightMin >= 14 * 60 {
            flightCategory = .lrv
        } else {
            flightCategory = .nonLRV
        }
    }

    // MARK: - Flight Info

    private var flightInfoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let f = fleet {
                HStack(alignment: .firstTextBaseline) {
                    Image(systemName: "airplane").foregroundStyle(CRTheme.ekRed)
                    Text("A6-\(state.registration)")
                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text(f.displayLabel)
                        .font(.system(size: 14))
                        .foregroundStyle(.primary)
                }
                HStack(spacing: 16) {
                    infoTag("Flight time", TimeFormatter.dur(state.flightMin))
                    infoTag("Facility", state.facility.label)
                    infoTag("Min rest (LRV)", RestTimings.minimumRestLRV(blockMinutes: state.flightMin))
                }
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle").foregroundStyle(.secondary)
                    Text("Enter a registration in the calculator to auto-resolve the strategy.")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(uiColor: .separator), lineWidth: 0.5))
    }

    private func infoTag(_ label: String, _ value: String) -> some View {
        HStack(spacing: 4) {
            Text(label).font(.system(size: 12)).foregroundStyle(.secondary)
            Text(value).font(.system(size: 12, weight: .semibold, design: .monospaced))
        }
    }

    // MARK: - Flight Type Selector

    private var flightTypeSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("FLIGHT TYPE").font(.system(size: 12, weight: .bold)).tracking(0.6).foregroundStyle(.primary.opacity(0.7))
            Seg(options: FlightCategory.allCases, label: \.rawValue, selection: $flightCategory)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(uiColor: .separator), lineWidth: 0.5))
    }

    // MARK: - Rest Timing

    private var restTimingCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("MINIMUM REST TIMINGS").font(.system(size: 12, weight: .bold)).tracking(0.6).foregroundStyle(.primary.opacity(0.7))

            switch flightCategory {
            case .lrv:
                lrvTimingTable
            case .ccap:
                ccapTimingTable
            case .nonLRV:
                nonLRVTimingTable
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(uiColor: .separator), lineWidth: 0.5))
    }

    private var lrvTimingTable: some View {
        VStack(spacing: 0) {
            timingHeader("Block time", "Min rest")
            ForEach(RestTimings.lrvRegulatory) { row in
                timingRow(row.blockTime, row.duration,
                          highlight: isCurrentBlockTime(row))
            }
            Text("* Refer to OM-A section 7E for LRV flights under 14 hrs")
                .font(.system(size: 11)).foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 6)
        }
    }

    private func isCurrentBlockTime(_ row: RestTimings.Row) -> Bool {
        let m = state.flightMin
        switch row.blockTime {
        case let s where s.contains("Under 14"):    return m < 14 * 60
        case let s where s.contains("14 hr –"):     return m >= 14 * 60 && m < 15 * 60
        case let s where s.contains("15 hr –"):     return m >= 15 * 60 && m < 16 * 60
        case let s where s.contains("16"):           return m >= 16 * 60
        default: return false
        }
    }

    private var ccapTimingTable: some View {
        VStack(spacing: 0) {
            timingHeader("Sector", "Mandatory rest")
            ForEach(RestTimings.ccapSectors) { s in
                timingRow(s.sector, s.rest, highlight: false)
            }
            Text("CRC required. When CRC unavailable, refer to OM-A 7.7.1.2")
                .font(.system(size: 11)).foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 6)
        }
    }

    private var nonLRVTimingTable: some View {
        VStack(spacing: 0) {
            Text("Hard-Blocked Seats").font(.system(size: 13, weight: .semibold)).frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 4)
            timingHeader("Block time", "Rest")
            ForEach(RestTimings.nonRegHardBlocked) { row in
                timingRow(row.blockTime, row.duration, highlight: false)
            }

            Divider().padding(.vertical, 8)

            Text("Meal Break / Soft-Blocked").font(.system(size: 13, weight: .semibold)).frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 4)
            timingHeader("Block time", "Rest")
            ForEach(Array(RestTimings.nonRegMealBreak.enumerated()), id: \.offset) { _, item in
                timingRow(item.blockTime, item.duration, highlight: false)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("When CRC is available on 9:30 – 13:59, extend rest up to 30 min time permitting.")
                Text("If sector is below 9:29, adjust rest to 45 min – 1 hr.")
                Text("Soft-blocked: last two rows LHS or RHS aft YC. CRC can be used if fitted, time permitting.")
            }
            .font(.system(size: 11)).foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 6)
        }
    }

    private func timingHeader(_ left: String, _ right: String) -> some View {
        HStack {
            Text(left).font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary)
            Spacer()
            Text(right).font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(Color(uiColor: .secondarySystemBackground))
    }

    private func timingRow(_ left: String, _ right: String, highlight: Bool) -> some View {
        HStack {
            Text(left).font(.system(size: 14))
            Spacer()
            Text(right).font(.system(size: 14, weight: .medium, design: .monospaced))
        }
        .padding(.horizontal, 10).padding(.vertical, 7)
        .background(highlight ? CRTheme.ekRed.opacity(0.08) : Color.clear)
        .overlay(Rectangle().fill(Color(uiColor: .separator).opacity(0.3)).frame(height: 0.5), alignment: .bottom)
    }

    // MARK: - Strategy Card

    private func strategyCard(_ strategy: GuideStrategy) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Image(systemName: "checkmark.shield.fill").foregroundStyle(CRTheme.ekRed)
                Text(strategy.title)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(3)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 10)], spacing: 10) {
                ForEach(strategy.groups) { group in
                    groupCard(group)
                }
            }

            if let fc = strategy.fcNote {
                fcBlock(fc)
            }

            ForEach(Array(strategy.notes.enumerated()), id: \.offset) { _, note in
                noteCallout(note)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(uiColor: .separator), lineWidth: 0.5))
    }

    private func groupCard(_ group: GuideGroup) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(group.name).font(.system(size: 14, weight: .semibold))
                Spacer()
                if group.crewCount > 0 {
                    Text("\(group.crewCount) crew")
                        .font(.system(size: 12)).foregroundStyle(.secondary).monospacedDigit()
                }
            }
            .padding(.bottom, 4)
            .overlay(Rectangle().fill(Color(uiColor: .separator).opacity(0.5)).frame(height: 0.5), alignment: .bottom)

            ForEach(Array(group.lines.enumerated()), id: \.offset) { _, line in
                crewLine(line)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(uiColor: .separator), lineWidth: 0.5))
    }

    private func crewLine(_ line: String) -> some View {
        HStack(spacing: 6) {
            if let cls = extractClass(line) {
                classBadge(cls)
            }
            Text(line)
                .font(.system(size: 13, design: .monospaced))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 3)
    }

    private func extractClass(_ line: String) -> String? {
        let l = line.uppercased()
        if l.hasPrefix("F ") || l.hasPrefix("F CLASS") { return "F" }
        if l.hasPrefix("J ") || l.hasPrefix("J CLASS") { return "J" }
        if l.hasPrefix("W ") || l.hasPrefix("W CLASS") { return "W" }
        if l.hasPrefix("Y ") || l.hasPrefix("Y CLASS") { return "Y" }
        if l.hasPrefix("PURSER") { return "P" }
        if l.hasPrefix("CSA") { return "S" }
        return nil
    }

    private func classBadge(_ cls: String) -> some View {
        let (fg, bg) = classColors(cls)
        return Text(cls == "S" ? "·" : cls)
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .frame(width: 24, height: 18)
            .background(bg).foregroundStyle(fg)
            .clipShape(RoundedRectangle(cornerRadius: 3))
    }

    private func classColors(_ cls: String) -> (Color, Color) {
        switch cls {
        case "F": return (Color(red: 0x92/255, green: 0x40/255, blue: 0x0E/255), Color(red: 0xFE/255, green: 0xF3/255, blue: 0xC7/255))
        case "J": return (Color(red: 0x1E/255, green: 0x3A/255, blue: 0x8A/255), Color(red: 0xDB/255, green: 0xEA/255, blue: 0xFE/255))
        case "W": return (Color(red: 0x5B/255, green: 0x21/255, blue: 0xB6/255), Color(red: 0xE9/255, green: 0xD5/255, blue: 0xFF/255))
        case "Y": return (Color(red: 0x16/255, green: 0x65/255, blue: 0x34/255), Color(red: 0xDC/255, green: 0xFC/255, blue: 0xE7/255))
        case "P": return (.white, CRTheme.ekRed)
        default:  return (Color(red: 0x3C/255, green: 0x3C/255, blue: 0x43/255), Color(red: 0xE5/255, green: 0xE5/255, blue: 0xEA/255))
        }
    }

    private func fcBlock(_ text: String) -> some View {
        let cF = Color(red: 0x92/255, green: 0x40/255, blue: 0x0E/255)
        let bg = Color(red: 0xFE/255, green: 0xD7/255, blue: 0xAA/255)
        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                classBadge("F")
                Text("First Class – independent rest").font(.system(size: 14, weight: .semibold)).foregroundStyle(cF)
            }
            Text(text).font(.system(size: 13)).foregroundStyle(cF.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(bg)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func noteCallout(_ message: String) -> some View {
        let amber = Color(red: 0xF5/255, green: 0x9E/255, blue: 0x0B/255)
        let amberBg = Color(red: 0xFE/255, green: 0xF3/255, blue: 0xC7/255)
        let amberText = Color(red: 0x78/255, green: 0x35/255, blue: 0x0F/255)
        return Text(message)
            .font(.system(size: 13)).foregroundStyle(amberText)
            .fixedSize(horizontal: false, vertical: true)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(amberBg)
            .overlay(Rectangle().fill(amber).frame(width: 3), alignment: .leading)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "questionmark.diamond").font(.system(size: 32)).foregroundStyle(.secondary)
            Text("Enter a registration in the calculator to see the crew rest strategy.")
                .font(.system(size: 15)).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Guidance

    private var guidanceCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("GENERAL GUIDANCE").font(.system(size: 12, weight: .bold)).tracking(0.6).foregroundStyle(.primary.opacity(0.7))

            bulletPoint("Regulatory (LRV): applicable on sectors with block time above 14 hrs at any time of year (OM-A 7.5) and/or specified in OM-A 7.E. Rest must be taken in the CRC.")
            bulletPoint("Both outbound and inbound sectors are classified as LRV even if block time is less than 14 hrs in one direction.")
            bulletPoint("Non-regulatory (Non-LRV): company policy to provide a break from tasks, time permitting. Single sector scheduled block time 4 hr to LRV qualified sectors (OM-A 7.E.1).")
            bulletPoint("On the day of operation, the crew rest is adjusted by the Operating Purser based on the estimated flight time.")
            bulletPoint("Rest duration can be extended at the Operating Purser's discretion (max 1 hr per group on top of the predicted range).")
            bulletPoint("All crew must have an equal amount of rest.")
            bulletPoint("Refer to OM-A 7.21.8 for Cabin Crew Augmentation Policy.")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(uiColor: .separator), lineWidth: 0.5))
    }

    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("·").font(.system(size: 16, weight: .bold)).foregroundStyle(.secondary)
            Text(text).font(.system(size: 13)).foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Footer

    private var sourceFooter: some View {
        Text("Source: Onboard Crew Rest Strategies v18.1, April 2026.\nAlways verify with the official document. OM-A 7.E, 7.5, 7.7.1.2, 7.21.8.")
            .font(.system(size: 12, design: .monospaced))
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.top, 4)
    }
}
