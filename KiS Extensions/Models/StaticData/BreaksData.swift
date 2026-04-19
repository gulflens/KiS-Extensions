import Foundation

struct BreaksData {
    /// Returns break map for a given operation type: position name -> break group number
    static func breaks(for operationType: Int) -> [String: Int]? {
        return allBreaks[operationType]
    }

    static func clonedBreaks(for operationType: Int) -> [String: Int]? {
        return allBreaks[operationType]
    }

    /// Returns the break map for crew seats (no CRC) based on the aircraft type and cabin class count.
    static func crewSeatsBreaks(for aircraftType: String, classes: Int) -> [String: Int]? {
        switch (aircraftType, classes) {
        case ("A380", _): return a380_4class_noCRC
        case ("B777", 4): return b773_4class_noCRC
        case ("B777", _): return b773_3class_noCRC
        case ("A350", _): return a350_3class
        default: return nil
        }
    }

    // MARK: - CRC / Crew Seat Capacity

    /// Per-break capacity for CRC configurations (bunk count).
    static func crcCapacity(for operationType: Int) -> Int? {
        switch operationType {
        case 1, 2, 3, 4, 5, 901, 904, 12, 16, 912: return 8   // B777 CRC
        case 9, 15: return 9                                     // A380 MD-CRC
        case 10, 11: return 12                                   // A380 LD-CRC
        default: return nil
        }
    }

    /// Per-break capacity for crew seats (no CRC) configurations.
    static func crewSeatsCapacity(for aircraftType: String) -> Int? {
        switch aircraftType {
        case "B777": return 4
        default: return nil
        }
    }

    // MARK: - Break definitions

    private static let a380_4class_LDCRC: [String: Int] = [
        "UL1": 1, "CSA": 1, "UL1A": 1, "UR3": 1, "ML4A": 1,
        "ML4 (ML4A)": 1, "MR4A": 1, "MR5 (MR4A)": 1, "UR2": 1,
        "ML1": 1, "MR1": 1, "MR4": 1, "ML3": 1, "ML4": 1,
        "PUR": 2, "MR2A": 2, "UL3": 2, "ML3A": 2,
        "ML3 (ML3A)": 2, "UR1A": 2, "UL2": 2, "MR3A": 2,
        "MR2 (MR3A)": 2, "ML5": 2, "MR5": 2, "ML2": 2, "MR2": 2, "MR3": 2,
        "UR1": 3,
    ]

    private static let a380_3class_ULR: [String: Int] = [
        "UR1": 1, "CSA": 1, "UL1A": 1, "UR3": 1, "MR1": 1,
        "MR2": 1, "MR4": 1, "ML3": 1, "ML4": 1,
        "PUR": 2, "MR2A": 2, "ML4A": 2, "ML4 (ML4A)": 2,
        "MR4A": 2, "MR5 (MR4A)": 2, "UR1A": 2, "UL2": 2,
        "UL1": 3, "ML3A": 3, "ML3 (ML3A)": 3, "UL3": 3,
        "UR2": 3, "ML1": 3, "ML5": 3, "ML2": 3, "MR5": 3, "MR3": 3,
        "MR3A": 2, "MR2 (MR3A)": 2,
    ]

    private static let b772_2class_ULR: [String: Int] = [
        "R1A": 1, "R2 (R1A)": 1, "L1": 1, "R4": 1, "L3": 1, "L2": 1,
        "PUR": 2, "R1": 2, "L1A": 2, "R2 (L1A)": 2, "L2 (L1A)": 2,
        "L4": 2, "L4A": 2, "R3": 2, "R2": 2,
    ]

    private static let b772_2class_nonULR: [String: Int] = [
        "R1A": 1, "R2 (R1A)": 1, "L1": 1, "L4": 1, "R4": 1, "L3": 1, "L2": 1,
        "PUR": 2, "R1": 2, "L1A": 2, "R2 (L1A)": 2, "L2 (L1A)": 2,
        "L4A": 2, "R3": 2, "R2": 2,
    ]

    private static let b773_3class: [String: Int] = [
        "L1": 1, "R2A": 1, "R4 (R2A)": 1, "R2": 1, "R5C": 1,
        "L3": 1, "R5": 1, "L4": 1,
        "R1": 2, "L2A": 2, "L4 (L2A)": 2, "L2": 2, "L5": 2,
        "R3": 2, "L5A": 2, "R4": 2,
        "PUR": 3, "L1A": 3, "R2 (L1A)": 3, "L2 (L1A)": 3, "R3 (L1A)": 3,
    ]

    private static let b773_4class: [String: Int] = [
        "L1": 1, "R2A": 1, "R4 (R2A)": 1, "R2": 1, "R5C": 1,
        "L3": 1, "R5": 1, "L4": 1, "R5A": 1,
        "R1": 2, "L2A": 2, "L4 (L2A)": 2, "L2": 2, "R3": 2,
        "L5": 2, "L5A": 2, "R4": 2,
        "PUR": 3, "L1A": 3, "R2 (L1A)": 3, "L2 (L1A)": 3, "R3 (L1A)": 3,
    ]

    private static let b773_2class: [String: Int] = [
        "L1A": 1, "R2 (L1A)": 1, "L2 (L1A)": 1, "R3": 1, "R2": 1,
        "L1": 2, "L5": 2, "L5A": 2, "L4": 2,
        "R1": 3, "R1A": 3, "R2 (R1A)": 3, "R5": 3, "L3": 3,
        "PUR": 4, "R4": 4, "L2": 4,
    ]

    private static let b773_3class_noCRC: [String: Int] = [
        "L1": 1, "R2": 1, "R5A": 1, "L4": 1,
        "R1": 2, "R2A": 2, "R4 (R2A)": 2, "R3": 2, "R5": 2,
        "L2A": 3, "L4 (L2A)": 3, "L5": 3, "L5A": 3, "R5C": 3,
        "PUR": 4, "L2": 4, "L3": 4, "R4": 4,
    ]

    private static let b773_4class_noCRC: [String: Int] = [
        "L1": 1, "R2": 1, "R5A": 1, "L4": 1,
        "R1": 2, "R2A": 2, "R4 (R2A)": 2, "R5": 2, "R5C": 2,
        "L2A": 3, "L4 (L2A)": 3, "L5": 3, "L5A": 3, "L3": 3,
        "PUR": 4, "L2": 4, "R4": 4, "R3": 4,
    ]

    private static let a380_4class_noCRC: [String: Int] = [
        "UR1": 1, "ML3": 1, "UR1A": 1, "MR4A": 1,
        "MR5 (MR4A)": 1, "ML1": 1, "ML4": 1,
        "MR2A": 2, "UL1A": 2, "UR3": 2, "ML4A": 2,
        "ML4 (ML4A)": 2, "ML2": 2, "MR4": 2,
        "UL1": 3, "ML3A": 3, "ML3 (ML3A)": 3, "UR2": 3,
        "ML5": 3, "MR5": 3, "MR3A": 3, "MR2 (MR3A)": 3,
        "PUR": 4, "UL3": 4, "UL2": 4, "MR1": 4,
        "MR2": 4, "MR3": 4, "CSA": 0,
    ]

    private static let a380_3class_MDCRC: [String: Int] = [
        "MR2A": 1, "CSA": 1, "UR1A": 1, "UL3": 1, "ML3A": 1,
        "ML3 (ML3A)": 1, "MR1": 1, "ML5": 1, "MR2": 1, "MR5": 1,
        "UL1": 2, "UL1A": 2, "ML4A": 2, "ML4 (ML4A)": 2,
        "UR3": 2, "MR3A": 2, "MR2 (MR3A)": 2, "MR4": 2, "ML2": 2,
        "PUR": 3, "UR1": 3, "MR4A": 3, "MR5 (MR4A)": 3,
        "UR2": 3, "UL2": 3, "ML1": 3, "ML4": 3, "MR3": 3,
        "ML3": 2,
    ]

    private static let a350_3class: [String: Int] = [
        "L3": 1, "R4": 1, "L1": 1,
        "L1A": 2, "L3 (L1A)": 2, "L4": 2, "L4A": 2, "L2": 2,
        "R2": 3, "R1": 3, "R2A": 3, "R3 (R2A)": 1,
        "PUR": 4, "R3": 4, "R4A": 4,
    ]

    private static let a350_3class_CRC: [String: Int] = [
        "L3": 1, "R4": 1, "L1": 1, "L1A": 1, "L3 (L1A)": 1,
        "L4": 1, "L4A": 1, "L2": 1,
        "R2": 2, "R1": 2, "R2A": 2, "R3 (R2A)": 2,
        "PUR": 2, "R3": 2, "R4A": 2,
    ]

    // MARK: - Type mapping

    static let allBreaks: [Int: [String: Int]] = [
        // B773 3 class (types 1, 2, 3, 901)
        1: b773_3class, 2: b773_3class, 3: b773_3class, 901: b773_3class,

        // B772 2 class
        4: b772_2class_nonULR, 904: b772_2class_ULR,

        // B773 2 class
        5: b773_2class,

        // B773 3 class no CRC (types 6, 17)
        6: b773_3class_noCRC, 17: b773_3class_noCRC,

        // A380 2 class no CRC
        7: a380_4class_noCRC,

        // A380 3 class no CRC
        8: a380_4class_noCRC,

        // A380 3 class MD-CRC (types 9, 15)
        9: a380_3class_MDCRC, 15: a380_3class_MDCRC,

        // A380 4 class LD-CRC (types 10, 11)
        10: a380_4class_LDCRC, 11: a380_4class_LDCRC,

        // A380 3 class ULR
        908: a380_3class_ULR,

        // B773 4 class (types 12, 16, 912)
        12: b773_4class, 16: b773_4class, 912: b773_4class,

        // A350
        13: a350_3class, 18: a350_3class_CRC,

        // A380 4 class no CRC
        14: a380_4class_noCRC,
    ]
}
