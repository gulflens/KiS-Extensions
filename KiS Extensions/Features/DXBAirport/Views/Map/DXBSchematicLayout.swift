import CoreGraphics
import Foundation

// MARK: - DXB Schematic Layout

/// Geometry engine for the DXB Airport schematic. Coordinates live on an
/// abstract 1600 x 1000 horizontal canvas that is rotated 25 degrees clockwise
/// at display time so the runways appear at their real 12/30 heading.
///
/// Geometry calibrated from Jeppesen ground charts (DXB-OMDB, 07-MAY-2026):
///   - B777/A350 Tempo AGC RWY 12L/30R (chart 3-08)
///   - A380 Operational Plan RWY 12L/30R (chart 3-10B)
///
/// Real DXB topology:
///   - Two parallel runways: 12L/30R (north) and 12R/30L (south)
///   - Concourse piers A, B, C (Terminal 3, Emirates) between the runways
///   - Concourse D (Terminal 1) between the runways, further east
///   - Terminal 3 main building south of 12R (landside)
///   - Terminal 2 / Concourse F north of 12L
///   - Support buildings and aprons around the periphery
struct DXBSchematicLayout {

    // MARK: - Canvas

    static let canvasSize = CGSize(width: 1600, height: 1000)

    /// Clockwise rotation applied at display time so runways appear at the
    /// real heading (~120 degrees / 300 degrees).
    static let rotationDegrees: CGFloat = 25

    /// Bounding box after rotation — used for fit-to-screen and pan clamping.
    static let displayedSize: CGSize = {
        let theta = rotationDegrees * .pi / 180
        let w = canvasSize.width
        let h = canvasSize.height
        return CGSize(
            width:  w * abs(cos(theta)) + h * abs(sin(theta)),
            height: w * abs(sin(theta)) + h * abs(cos(theta))
        )
    }()

    // MARK: - Runways
    //
    // 12L/30R is the NORTHERN runway. 12R/30L is the SOUTHERN runway.
    // All terminal infrastructure sits between them. Runway separation
    // matches Jeppesen chart proportions (~40% of total layout height).

    struct RunwayGeometry {
        let start: CGPoint
        let end: CGPoint
        let label: String
        let westThresholdLabel: String
        let eastThresholdLabel: String
    }

    static let runways: [RunwayGeometry] = [
        RunwayGeometry(
            start: CGPoint(x: 50, y: 115),
            end:   CGPoint(x: 1550, y: 115),
            label: "12L / 30R",
            westThresholdLabel: "12L",
            eastThresholdLabel: "30R"
        ),
        RunwayGeometry(
            start: CGPoint(x: 50, y: 520),
            end:   CGPoint(x: 1550, y: 520),
            label: "12R / 30L",
            westThresholdLabel: "12R",
            eastThresholdLabel: "30L"
        )
    ]

    // MARK: - Concourse piers (between the two runways)
    //
    //  West to East: A (T3 west), B (T3 centre), C (T3 east), D (T1)
    //  Each pier is a tall narrow rectangle with gates on its west and east faces.
    //  Pier tops sit below the M taxiway; bottoms sit above the K taxiway.

    static let concourseA = CGRect(x: 310, y: 185, width: 48, height: 290)
    static let concourseB = CGRect(x: 535, y: 185, width: 48, height: 292)
    static let concourseC = CGRect(x: 770, y: 188, width: 48, height: 265)
    static let concourseD = CGRect(x: 1095, y: 185, width: 48, height: 300)

    // MARK: - Terminal 3 (south of 12R, landside, connecting A/B/C)

    static let t3Main = CGRect(x: 230, y: 585, width: 650, height: 55)

    // MARK: - T1 / T2

    static let t1Main = CGRect(x: 1030, y: 470, width: 180, height: 48)
    static let t2Main = CGRect(x: 300, y: 22, width: 380, height: 28)
    static let concourseF = CGRect(x: 300, y: 52, width: 380, height: 22)

    // MARK: - Aprons / remote stand areas

    static let apronE = CGRect(x: 760, y: 30, width: 250, height: 55)
    static let apronQ = CGRect(x: 1060, y: 30, width: 200, height: 55)
    static let apronF = CGRect(x: 230, y: 660, width: 650, height: 60)
    static let apronG = CGRect(x: 1400, y: 140, width: 110, height: 120)
    static let apronS = CGRect(x: 1410, y: 280, width: 100, height: 230)
    static let apronH = CGRect(x: 1200, y: 790, width: 200, height: 55)

    // MARK: - Support buildings

    static let cargoTerminal   = CGRect(x: 30,   y: 310, width: 110, height: 65)
    static let ekTechCentre    = CGRect(x: 1300, y: 28,  width: 180, height: 55)
    static let fireStationWest = CGRect(x: 35,   y: 155, width: 55,  height: 22)
    static let fireStationEast = CGRect(x: 1260, y: 275, width: 55,  height: 22)
    static let emiratesHQ      = CGRect(x: 950,  y: 850, width: 180, height: 75)
    static let fuelFarm        = CGRect(x: 560,  y: 885, width: 130, height: 50)
    static let controlTower    = CGRect(x: 430,  y: 350, width: 22,  height: 22)

    static func rect(for concourse: Concourse) -> CGRect {
        switch concourse {
        case .A: return concourseA
        case .B: return concourseB
        case .C: return concourseC
        case .D: return concourseD
        case .F: return concourseF
        case .G: return apronG
        case .E: return apronE
        case .H: return apronH
        case .Q: return apronQ
        case .S: return apronS
        }
    }

    // MARK: - Apron tags

    struct ApronTag {
        let title: String
        let elevation: Int?
        let rect: CGRect
    }

    static let apronTags: [ApronTag] = [
        ApronTag(title: "Apron E", elevation: 13, rect: apronE),
        ApronTag(title: "Apron Q", elevation: nil, rect: apronQ),
        ApronTag(title: "Apron F", elevation: nil, rect: apronF),
        ApronTag(title: "Apron G", elevation: 16, rect: apronG),
        ApronTag(title: "Apron S", elevation: 34, rect: apronS),
        ApronTag(title: "Apron H", elevation: nil, rect: apronH)
    ]

    // MARK: - Taxiway network
    //
    // Main taxiways from the Jeppesen chart:
    //   M  — east-west, between 12L and pier tops
    //   K  — east-west, between pier bottoms and 12R
    //   J  — north-south, west of Concourse A
    //   N  — north-south, between A and B
    //   L  — north-south, between B and C
    //   P  — north-south, between C and D
    //   Unnamed feeders on the east side

    struct TaxiwayBand {
        enum Restriction { case none, limited, restricted }
        let start: CGPoint
        let end: CGPoint
        let restriction: Restriction
        let label: String?
    }

    static let taxiways: [TaxiwayBand] = [
        // M taxiway — horizontal, between north runway and pier tops
        TaxiwayBand(
            start: CGPoint(x: 60, y: 160),
            end:   CGPoint(x: 1540, y: 160),
            restriction: .none, label: "M"
        ),
        // K taxiway — horizontal, between pier bottoms and south runway
        TaxiwayBand(
            start: CGPoint(x: 200, y: 490),
            end:   CGPoint(x: 1350, y: 490),
            restriction: .none, label: "K"
        ),
        // J taxiway — north-south, west of Concourse A
        TaxiwayBand(
            start: CGPoint(x: 210, y: 160),
            end:   CGPoint(x: 210, y: 490),
            restriction: .none, label: "J"
        ),
        // N taxiway — north-south, between A and B piers
        TaxiwayBand(
            start: CGPoint(x: 430, y: 195),
            end:   CGPoint(x: 430, y: 485),
            restriction: .limited, label: "N"
        ),
        // L taxiway — north-south, between B and C piers
        TaxiwayBand(
            start: CGPoint(x: 660, y: 195),
            end:   CGPoint(x: 660, y: 485),
            restriction: .limited, label: "L"
        ),
        // P taxiway — north-south, between C and D piers
        TaxiwayBand(
            start: CGPoint(x: 940, y: 205),
            end:   CGPoint(x: 940, y: 470),
            restriction: .limited, label: "P"
        ),
        // East feeder — north-south, east of Concourse D
        TaxiwayBand(
            start: CGPoint(x: 1250, y: 160),
            end:   CGPoint(x: 1250, y: 490),
            restriction: .none, label: nil
        ),
        // Far east feeder — north-south
        TaxiwayBand(
            start: CGPoint(x: 1450, y: 160),
            end:   CGPoint(x: 1450, y: 520),
            restriction: .none, label: nil
        ),
        // Outer taxiway north of 12L/30R (T2 / Apron E / Q access)
        TaxiwayBand(
            start: CGPoint(x: 80, y: 75),
            end:   CGPoint(x: 1400, y: 75),
            restriction: .none, label: nil
        ),
        // South access taxiway (between 12R and Terminal 3)
        TaxiwayBand(
            start: CGPoint(x: 200, y: 560),
            end:   CGPoint(x: 1350, y: 560),
            restriction: .none, label: nil
        ),
        // Taxiway south of Terminal 3 / Apron F
        TaxiwayBand(
            start: CGPoint(x: 200, y: 740),
            end:   CGPoint(x: 1300, y: 740),
            restriction: .none, label: nil
        ),
        // Far south taxiway (Emirates HQ / Apron H access)
        TaxiwayBand(
            start: CGPoint(x: 200, y: 810),
            end:   CGPoint(x: 1400, y: 810),
            restriction: .none, label: nil
        )
    ]

    // MARK: - Graph node positions

    static let graphNodePositions: [String: CGPoint] = [
        "CONCOURSE_A_HUB":         CGPoint(x: 334, y: 325),
        "CONCOURSE_B_HUB":         CGPoint(x: 559, y: 333),
        "CONCOURSE_C_HUB":         CGPoint(x: 794, y: 318),
        "APM_CONCOURSE_A_STATION": CGPoint(x: 334, y: 440),
        "APM_T3_B_STATION":        CGPoint(x: 559, y: 590),
        "B_C_WALKWAY":             CGPoint(x: 660, y: 265),
        "T3_MAIN_DEPARTURES":      CGPoint(x: 559, y: 612)
    ]

    // MARK: - Connections

    struct Connection {
        let start: CGPoint
        let end: CGPoint
        let label: String?
        let icon: String?
        let isUnderground: Bool
    }

    static let trainConnections: [Connection] = [
        Connection(
            start: graphNodePositions["APM_CONCOURSE_A_STATION"]!,
            end:   graphNodePositions["APM_T3_B_STATION"]!,
            label: "APM ~4 min peak / ~6 min off-peak",
            icon: "tram.fill",
            isUnderground: true
        )
    ]

    static let walkConnections: [Connection] = [
        Connection(
            start: graphNodePositions["CONCOURSE_B_HUB"]!,
            end:   graphNodePositions["B_C_WALKWAY"]!,
            label: nil, icon: nil, isUnderground: false
        ),
        Connection(
            start: graphNodePositions["B_C_WALKWAY"]!,
            end:   graphNodePositions["CONCOURSE_C_HUB"]!,
            label: "~300m walkway",
            icon: "figure.walk",
            isUnderground: false
        )
    ]

    // MARK: - Computed positions

    let bayPositions: [String: CGPoint]
    let bayLabelOffsets: [String: CGSize]
    let bayFingerDirections: [String: CGSize]
    let loungePositions: [String: CGPoint]

    // MARK: - Gate ordering

    private static func gateOrder(_ bay: Bay) -> (Int, String, Int, String) {
        let remoteSort = bay.type == .remote ? 1 : 0
        let id = bay.gateId ?? bay.bayId
        var prefix = ""
        var digits = ""
        var suffix = ""
        var pastDigits = false
        for char in id {
            if char.isNumber && !pastDigits {
                digits.append(char)
            } else if !digits.isEmpty {
                pastDigits = true
                suffix.append(char)
            } else {
                prefix.append(char)
            }
        }
        return (remoteSort, prefix, Int(digits) ?? 0, suffix)
    }

    // MARK: - Init

    init(catalog: BayCatalog, lounges: [Lounge]) {
        var bayPos: [String: CGPoint] = [:]
        var labelOffsets: [String: CGSize] = [:]
        var fingerDirs: [String: CGSize] = [:]

        for concourse in Concourse.allCases {
            let rect = Self.rect(for: concourse)
            let bays = catalog.bays(in: concourse).sorted {
                Self.gateOrder($0) < Self.gateOrder($1)
            }
            guard !bays.isEmpty else { continue }

            let isVerticalPier = rect.height > rect.width * 2
            let isHorizontalPier = rect.width > rect.height * 2
            let isStub = !isVerticalPier && !isHorizontalPier

            if isVerticalPier {
                Self.placeBaysAlongVerticalPier(
                    bays: bays, in: rect,
                    bayPos: &bayPos,
                    labelOffsets: &labelOffsets,
                    fingerDirs: &fingerDirs
                )
            } else if isHorizontalPier {
                Self.placeBaysAlongHorizontalPier(
                    bays: bays, in: rect,
                    bayPos: &bayPos,
                    labelOffsets: &labelOffsets,
                    fingerDirs: &fingerDirs
                )
            } else if isStub {
                Self.placeBaysInGrid(
                    bays: bays, in: rect,
                    bayPos: &bayPos,
                    labelOffsets: &labelOffsets,
                    fingerDirs: &fingerDirs
                )
            }
        }
        self.bayPositions = bayPos
        self.bayLabelOffsets = labelOffsets
        self.bayFingerDirections = fingerDirs

        var loungePos: [String: CGPoint] = [:]
        for lounge in lounges {
            if let gate = lounge.nearestGate,
               let bay = catalog.find(query: gate),
               let anchor = bayPos[bay.bayId] {
                let offset = labelOffsets[bay.bayId] ?? CGSize(width: -22, height: 0)
                loungePos[lounge.id] = CGPoint(
                    x: anchor.x + offset.width * 1.6,
                    y: anchor.y + offset.height * 1.6
                )
            } else {
                let hubKey = "CONCOURSE_\(lounge.concourse.rawValue)_HUB"
                loungePos[lounge.id] = Self.graphNodePositions[hubKey] ?? .zero
            }
        }
        self.loungePositions = loungePos
    }

    // MARK: - Bay placement helpers

    private static func placeBaysAlongVerticalPier(
        bays: [Bay],
        in rect: CGRect,
        bayPos: inout [String: CGPoint],
        labelOffsets: inout [String: CGSize],
        fingerDirs: inout [String: CGSize]
    ) {
        let pairCount = (bays.count + 1) / 2
        let padding: CGFloat = 18
        let usableHeight = rect.height - 2 * padding
        for (index, bay) in bays.enumerated() {
            let onWest = (index % 2 == 0)
            let pairIndex = index / 2
            let fraction: CGFloat = pairCount > 1
                ? CGFloat(pairIndex) / CGFloat(pairCount - 1)
                : 0.5
            let x = onWest ? rect.minX : rect.maxX
            let y = rect.minY + padding + fraction * usableHeight
            bayPos[bay.bayId] = CGPoint(x: x, y: y)
            labelOffsets[bay.bayId] = CGSize(width: onWest ? -22 : 22, height: 0)
            fingerDirs[bay.bayId] = CGSize(width: onWest ? -1 : 1, height: 0)
        }
    }

    private static func placeBaysAlongHorizontalPier(
        bays: [Bay],
        in rect: CGRect,
        bayPos: inout [String: CGPoint],
        labelOffsets: inout [String: CGSize],
        fingerDirs: inout [String: CGSize]
    ) {
        let pairCount = (bays.count + 1) / 2
        let padding: CGFloat = 18
        let usableWidth = rect.width - 2 * padding
        for (index, bay) in bays.enumerated() {
            let onNorth = (index % 2 == 0)
            let pairIndex = index / 2
            let fraction: CGFloat = pairCount > 1
                ? CGFloat(pairIndex) / CGFloat(pairCount - 1)
                : 0.5
            let x = rect.minX + padding + fraction * usableWidth
            let y = onNorth ? rect.minY : rect.maxY
            bayPos[bay.bayId] = CGPoint(x: x, y: y)
            labelOffsets[bay.bayId] = CGSize(width: 0, height: onNorth ? -14 : 14)
            fingerDirs[bay.bayId] = CGSize(width: 0, height: onNorth ? -1 : 1)
        }
    }

    private static func placeBaysInGrid(
        bays: [Bay],
        in rect: CGRect,
        bayPos: inout [String: CGPoint],
        labelOffsets: inout [String: CGSize],
        fingerDirs: inout [String: CGSize]
    ) {
        let cols = max(1, Int((rect.width / 26).rounded(.down)))
        let rows = max(1, Int(ceil(Double(bays.count) / Double(cols))))
        let padding: CGFloat = 8
        let cellW = (rect.width - 2 * padding) / CGFloat(cols)
        let cellH = (rect.height - 2 * padding) / CGFloat(max(rows, 1))
        for (index, bay) in bays.enumerated() {
            let row = index / cols
            let col = index % cols
            let x = rect.minX + padding + cellW * (CGFloat(col) + 0.5)
            let y = rect.minY + padding + cellH * (CGFloat(row) + 0.5)
            bayPos[bay.bayId] = CGPoint(x: x, y: y)
            labelOffsets[bay.bayId] = CGSize(width: 0, height: -12)
            fingerDirs[bay.bayId] = CGSize(width: 0, height: 0)
        }
    }

    // MARK: - Lookup

    func position(forId id: String) -> CGPoint? {
        if let pos = bayPositions[id] { return pos }
        if let pos = Self.graphNodePositions[id] { return pos }
        return nil
    }
}
