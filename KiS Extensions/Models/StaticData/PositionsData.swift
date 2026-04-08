import Foundation

struct PositionsData {
    /// Returns the position map for a given operation type code
    static func positions(for operationType: Int) -> PositionMap? {
        return allPositions[operationType]
    }

    /// Deep copy of a position map (structs copy by value in Swift)
    static func clonedPositions(for operationType: Int) -> PositionMap? {
        return allPositions[operationType]
    }

    // MARK: - All position definitions by operation type

    private static let b773_3class: PositionMap = [
        "PUR":   GradePositions(galley: [], df: [], remain: [], only: ["PUR"]),
        "CSV":   GradePositions(galley: [], df: [], remain: [], only: ["L5", "R2A"]),
        "FG1":   GradePositions(galley: ["L1"], df: ["R1"], remain: [], only: []),
        "GR1":   GradePositions(galley: ["L2A"], df: ["L2"], remain: ["R2"], only: []),
        "GR2":   GradePositions(galley: ["R5", "L3"], df: ["R3"], remain: ["L4", "R4", "L5A"], only: []),
        "EXTRA": GradePositions(galley: [], df: [], remain: [], only: ["L1A", "R5A", "R5C"]),
    ]

    private static let b773_3class_ULR: PositionMap = [
        "PUR":   GradePositions(galley: [], df: [], remain: [], only: ["PUR"]),
        "CSV":   GradePositions(galley: [], df: [], remain: [], only: ["L5", "R2A"]),
        "FG1":   GradePositions(galley: ["L1"], df: ["R1"], remain: ["L1A"], only: []),
        "GR1":   GradePositions(galley: ["L2A"], df: ["L2"], remain: ["R2"], only: []),
        "GR2":   GradePositions(galley: ["R5", "L3"], df: ["R3"], remain: ["L4", "R4", "L5A"], only: []),
        "EXTRA": GradePositions(galley: [], df: [], remain: [], only: ["R5A", "R5C"]),
    ]

    private static let b772_2class: PositionMap = [
        "PUR":   GradePositions(galley: [], df: [], remain: [], only: ["PUR"]),
        "CSV":   GradePositions(galley: [], df: [], remain: [], only: ["L4"]),
        "GR1":   GradePositions(galley: ["L1A"], df: ["R1"], remain: ["L1", "R1A"], only: []),
        "GR2":   GradePositions(galley: ["R4", "L3"], df: ["L2"], remain: ["R2", "R3", "L4A"], only: []),
        "EXTRA": GradePositions(galley: [], df: [], remain: [], only: ["R4A", "R4C"]),
    ]

    private static let b772_2class_ULR: PositionMap = [
        "PUR":   GradePositions(galley: [], df: [], remain: [], only: ["PUR"]),
        "CSV":   GradePositions(galley: [], df: [], remain: [], only: ["L4", "R1A"]),
        "GR1":   GradePositions(galley: ["L1A"], df: ["R1"], remain: ["L1"], only: []),
        "GR2":   GradePositions(galley: ["R4", "L3"], df: ["L2"], remain: ["R2", "R3", "L4A"], only: []),
        "EXTRA": GradePositions(galley: [], df: [], remain: [], only: ["R4A", "R4C"]),
    ]

    private static let b773_2class: PositionMap = [
        "PUR":   GradePositions(galley: [], df: [], remain: [], only: ["PUR"]),
        "CSV":   GradePositions(galley: [], df: [], remain: [], only: ["L5"]),
        "GR1":   GradePositions(galley: ["L1A"], df: ["R1"], remain: ["L1", "R1A"], only: []),
        "GR2":   GradePositions(galley: ["R5", "L3"], df: ["L2"], remain: ["L4", "R4", "R3", "R2", "L5A"], only: []),
        "EXTRA": GradePositions(galley: [], df: [], remain: [], only: ["R5C"]),
    ]

    private static let a380_2class: PositionMap = [
        "PUR":   GradePositions(galley: [], df: [], remain: [], only: ["PUR"]),
        "CSV":   GradePositions(galley: [], df: [], remain: [], only: ["ML5", "UL1A", "ML1"]),
        "GR1":   GradePositions(galley: ["ML3A", "MR4A"], df: ["UL3"], remain: ["UR3", "UR2", "UL2", "UR1A"], only: []),
        "GR2":   GradePositions(galley: ["UC1", "ML2", "MR4"], df: ["MR5"], remain: ["UR1", "UL1", "MR1", "ML3", "ML4", "MR3", "MR2"], only: []),
        "EXTRA": GradePositions(galley: [], df: [], remain: [], only: ["MR3A", "MR2A", "ML4A", "ML2A"]),
    ]

    private static let a380_3class: PositionMap = [
        "PUR":   GradePositions(galley: [], df: [], remain: [], only: ["PUR"]),
        "CSV":   GradePositions(galley: [], df: [], remain: [], only: ["ML5", "UL1A"]),
        "FG1":   GradePositions(galley: ["MR2A"], df: ["UR1"], remain: ["UL1"], only: []),
        "GR1":   GradePositions(galley: ["ML3A", "MR4A"], df: ["UL3"], remain: ["ML4A", "UR2", "UR3", "UL2", "UR1A"], only: []),
        "GR2":   GradePositions(galley: ["ML2", "MR4"], df: ["MR5"], remain: ["MR1", "ML1", "ML3", "ML4", "MR3", "MR2"], only: []),
        "CSA":   GradePositions(galley: [], df: [], remain: [], only: ["CSA"]),
        "EXTRA": GradePositions(galley: [], df: [], remain: [], only: ["MR3A"]),
    ]

    private static let a380_3class_ULR: PositionMap = [
        "PUR":   GradePositions(galley: [], df: [], remain: [], only: ["PUR"]),
        "CSV":   GradePositions(galley: [], df: [], remain: [], only: ["ML5", "UL1A", "ML1"]),
        "FG1":   GradePositions(galley: ["MR2A"], df: ["UR1"], remain: ["UL1"], only: []),
        "GR1":   GradePositions(galley: ["ML3A", "MR4A"], df: ["UL3"], remain: ["ML4A", "UR2", "UR3", "UL2", "UR1A"], only: []),
        "GR2":   GradePositions(galley: ["ML2", "MR4"], df: ["MR5"], remain: ["MR1", "ML3", "ML4", "MR3", "MR2"], only: []),
        "CSA":   GradePositions(galley: [], df: [], remain: [], only: ["CSA"]),
        "EXTRA": GradePositions(galley: [], df: [], remain: [], only: ["MR3A"]),
    ]

    private static let a380_4class: PositionMap = [
        "PUR":   GradePositions(galley: [], df: [], remain: [], only: ["PUR"]),
        "CSV":   GradePositions(galley: [], df: [], remain: [], only: ["ML5", "UL1A", "ML1"]),
        "FG1":   GradePositions(galley: ["MR2A"], df: ["UR1"], remain: ["UL1"], only: []),
        "GR1":   GradePositions(galley: ["ML3A", "MR4A"], df: ["UL3"], remain: ["ML4A", "UR2", "UR3", "UL2", "UR1A"], only: []),
        "GR2":   GradePositions(galley: ["ML2", "MR4", "MR3A"], df: ["MR5"], remain: ["MR1", "MR2", "ML4", "MR3", "ML3"], only: []),
        "CSA":   GradePositions(galley: [], df: [], remain: [], only: ["CSA"]),
        "EXTRA": GradePositions(galley: [], df: [], remain: [], only: []),
    ]

    private static let b773_4class: PositionMap = [
        "PUR":   GradePositions(galley: [], df: [], remain: [], only: ["PUR"]),
        "CSV":   GradePositions(galley: [], df: [], remain: [], only: ["L5", "R2A"]),
        "FG1":   GradePositions(galley: ["L1"], df: ["R1"], remain: [], only: []),
        "GR1":   GradePositions(galley: ["L2A"], df: ["L2"], remain: ["R2"], only: []),
        "GR2":   GradePositions(galley: ["R5", "L3"], df: ["R5A"], remain: ["R3", "L4", "R4", "L5A"], only: []),
        "EXTRA": GradePositions(galley: [], df: [], remain: [], only: ["L1A", "R5C"]),
    ]

    private static let b773_4class_ULR: PositionMap = [
        "PUR":   GradePositions(galley: [], df: [], remain: [], only: ["PUR"]),
        "CSV":   GradePositions(galley: [], df: [], remain: [], only: ["L5", "R2A"]),
        "FG1":   GradePositions(galley: ["L1"], df: ["R1"], remain: ["L1A"], only: []),
        "GR1":   GradePositions(galley: ["L2A"], df: ["L2"], remain: ["R2"], only: []),
        "GR2":   GradePositions(galley: ["R5", "L3"], df: ["R5A"], remain: ["R3", "L4", "R4", "L5A"], only: []),
        "EXTRA": GradePositions(galley: [], df: [], remain: [], only: ["R5C"]),
    ]

    private static let a350_3class: PositionMap = [
        "PUR":   GradePositions(galley: [], df: [], remain: [], only: ["PUR"]),
        "CSV":   GradePositions(galley: [], df: [], remain: [], only: ["L4"]),
        "GR1":   GradePositions(galley: ["L1A"], df: ["R1"], remain: ["L1", "R2A"], only: []),
        "GR2":   GradePositions(galley: ["L3", "R4", "L2"], df: ["R3"], remain: ["R2", "L4A", "R4A"], only: []),
        "EXTRA": GradePositions(galley: [], df: [], remain: [], only: ["L2A"]),
    ]

    private static let a350_3class_CRC: PositionMap = [
        "PUR":   GradePositions(galley: [], df: [], remain: [], only: ["PUR"]),
        "CSV":   GradePositions(galley: [], df: [], remain: [], only: ["L4"]),
        "GR1":   GradePositions(galley: ["L1A"], df: ["R1"], remain: ["L1", "R2A"], only: []),
        "GR2":   GradePositions(galley: ["L3", "R4", "L2"], df: ["R3"], remain: ["R2", "L4A", "R4A"], only: []),
        "EXTRA": GradePositions(galley: [], df: [], remain: [], only: ["L2A"]),
    ]

    // MARK: - Type mapping

    static let allPositions: [Int: PositionMap] = [
        // B773 3 class (types 1, 2, 3, 6 share same positions)
        1: b773_3class,
        2: b773_3class,
        3: b773_3class,
        6: b773_3class,
        901: b773_3class_ULR,

        // B772 2 class
        4: b772_2class,
        904: b772_2class_ULR,

        // B773 2 class
        5: b773_2class,

        // A380 2 class
        7: a380_2class,

        // A380 3 class (types 8, 9, 11 share same positions)
        8: a380_3class,
        9: a380_3class,
        11: a380_3class,
        12: b773_4class, // B773 4 class Game changer
        908: a380_3class_ULR,

        // A380 4 class (types 10, 14, 15)
        10: a380_4class,
        14: a380_4class,
        15: a380_4class,

        // B773 4 class
        16: b773_4class,
        17: b773_4class,
        912: b773_4class_ULR,

        // A350
        13: a350_3class,
        18: a350_3class_CRC,
    ]
}
