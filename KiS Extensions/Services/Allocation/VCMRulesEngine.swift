import Foundation

/// Cascading position removal when crew count is below minimum (VCM < 0).
/// Direct port of vcm_rules.js
struct VCMRulesEngine {

    static func apply(vcm: Int, positions: PositionMap, aircraftType: Int, isULR: Bool) -> PositionMap {
        var p = positions

        switch aircraftType {
        // B777-300 3 class
        case 1, 2, 3, 6:
            if vcm < 0 {
                removePosition(&p, grade: "GR2", from: .remain, position: "L5A")
            }
            if vcm < -1 {
                removePosition(&p, grade: "GR1", from: .galley, position: "L2A")
                removePosition(&p, grade: "GR2", from: .remain, position: "L4")
                addPosition(&p, grade: "GR1", to: .galley, position: "L4 (L2A)")
            } else { return p }
            if vcm < -2 {
                removePosition(&p, grade: "CSV", from: .only, position: "R2A")
                removePosition(&p, grade: "GR2", from: .remain, position: "R4")
                addPosition(&p, grade: "CSV", to: .only, position: "R4 (R2A)")
            } else { return p }
            if vcm < -3 && isULR {
                removePosition(&p, grade: "FG1", from: .remain, position: "L1A")
                removePosition(&p, grade: "GR2", from: .df, position: "R3")
                addPosition(&p, grade: "FG1", to: .remain, position: "R3 (L1A)")
            } else if vcm < -3 {
                removePosition(&p, grade: "FG1", from: .df, position: "R1")
                removePosition(&p, grade: "GR2", from: .df, position: "R3")
                removePosition(&p, grade: "PUR", from: .only, position: "PUR")
                addPosition(&p, grade: "FG1", to: .df, position: "R3 (R1)")
                addPosition(&p, grade: "PUR", to: .only, position: "L1 (PUR)")
            } else { return p }
            if vcm < -4 && isULR {
                removePosition(&p, grade: "FG1", from: .df, position: "R1")
                removePosition(&p, grade: "GR2", from: .galley, position: "L3")
                removePosition(&p, grade: "PUR", from: .only, position: "PUR")
                addPosition(&p, grade: "FG1", to: .df, position: "L3 (R1)")
                addPosition(&p, grade: "PUR", to: .only, position: "L1 (PUR)")
            } else { return p }

        // B777-200 2 class
        case 4:
            if vcm < 0 {
                removePosition(&p, grade: "GR2", from: .remain, position: "L4A")
            } else { return p }
            if vcm < -1 {
                removePosition(&p, grade: "GR1", from: .galley, position: "L1A")
                removePosition(&p, grade: "GR2", from: .df, position: "L2")
                addPosition(&p, grade: "GR1", to: .galley, position: "L2 (L1A)")
            } else { return p }
            if vcm < -2 {
                removePosition(&p, grade: "GR1", from: .remain, position: "R1A")
                removePosition(&p, grade: "GR2", from: .remain, position: "R2")
                addPosition(&p, grade: "GR1", to: .remain, position: "R2 (R1A)")
            } else { return p }
            if vcm < -3 {
                removePosition(&p, grade: "GR1", from: .remain, position: "L1")
                removePosition(&p, grade: "GR2", from: .remain, position: "R3")
                removePosition(&p, grade: "PUR", from: .only, position: "PUR")
                addPosition(&p, grade: "PUR", to: .only, position: "L1 (PUR)")
            } else { return p }

        // B777-300 2 class
        case 5:
            if vcm < 0 {
                removePosition(&p, grade: "GR2", from: .remain, position: "L5A")
            }
            if vcm < -1 {
                removePosition(&p, grade: "GR1", from: .df, position: "R1A")
                removePosition(&p, grade: "GR2", from: .remain, position: "R2")
                addPosition(&p, grade: "GR1", to: .df, position: "R2 (R1A)")
            } else { return p }
            if vcm < -2 {
                removePosition(&p, grade: "GR1", from: .galley, position: "L1A")
                removePosition(&p, grade: "GR2", from: .df, position: "L2")
                addPosition(&p, grade: "GR1", to: .galley, position: "L2 (L1A)")
            } else { return p }
            if vcm < -3 {
                removePosition(&p, grade: "GR1", from: .remain, position: "L1")
                removePosition(&p, grade: "GR2", from: .remain, position: "R3")
                removePosition(&p, grade: "PUR", from: .only, position: "PUR")
                addPosition(&p, grade: "GR1", to: .remain, position: "R3 (L1)")
                addPosition(&p, grade: "PUR", to: .only, position: "L1 (PUR)")
            } else { return p }

        // A380-800 2 class
        case 7:
            if vcm < 0 {
                removePosition(&p, grade: "GR2", from: .df, position: "MR5")
                removePosition(&p, grade: "GR1", from: .galley, position: "MR4A")
                addPosition(&p, grade: "GR1", to: .galley, position: "MR5 (MR4A)")
            } else { return p }
            if vcm < -1 {
                removePosition(&p, grade: "GR2", from: .remain, position: "ML3")
                removePosition(&p, grade: "GR1", from: .galley, position: "ML3A")
                addPosition(&p, grade: "GR1", to: .galley, position: "ML3 (ML3A)")
            } else { return p }
            if vcm < -2 && isULR {
                removePosition(&p, grade: "CSV", from: .only, position: "ML1")
                removePosition(&p, grade: "PUR", from: .only, position: "PUR")
                removePosition(&p, grade: "GR2", from: .remain, position: "MR1")
                addPosition(&p, grade: "PUR", to: .only, position: "ML1 (PUR)")
                addPosition(&p, grade: "CSV", to: .only, position: "MR1 (ML1)")
            } else if vcm < -2 {
                removePosition(&p, grade: "PUR", from: .only, position: "PUR")
                removePosition(&p, grade: "GR2", from: .remain, position: "ML1")
                addPosition(&p, grade: "PUR", to: .only, position: "ML1 (PUR)")
            } else { return p }

        // A380-800 3 class
        case 8, 9, 11:
            if vcm < 0 {
                removePosition(&p, grade: "GR2", from: .remain, position: "ML4")
                removePosition(&p, grade: "GR1", from: .df, position: "ML4A")
                addPosition(&p, grade: "GR1", to: .df, position: "ML4 (ML4A)")
            }
            if vcm < -1 {
                removePosition(&p, grade: "GR2", from: .df, position: "MR5")
                removePosition(&p, grade: "GR1", from: .galley, position: "MR4A")
                addPosition(&p, grade: "GR1", to: .galley, position: "MR5 (MR4A)")
            } else { return p }
            if vcm < -2 {
                removePosition(&p, grade: "GR2", from: .remain, position: "ML3")
                removePosition(&p, grade: "GR1", from: .galley, position: "ML3A")
                addPosition(&p, grade: "GR1", to: .galley, position: "ML3 (ML3A)")
            } else { return p }
            if vcm < -3 && isULR {
                removePosition(&p, grade: "CSV", from: .only, position: "ML1")
                removePosition(&p, grade: "PUR", from: .only, position: "PUR")
                removePosition(&p, grade: "GR2", from: .remain, position: "MR1")
                addPosition(&p, grade: "PUR", to: .only, position: "ML1 (PUR)")
                addPosition(&p, grade: "CSV", to: .only, position: "MR1 (ML1)")
            } else if vcm < -3 {
                removePosition(&p, grade: "PUR", from: .only, position: "PUR")
                removePosition(&p, grade: "GR2", from: .remain, position: "ML1")
                addPosition(&p, grade: "PUR", to: .only, position: "ML1 (PUR)")
            } else { return p }

        // A380-800 4 class (type 10)
        case 10:
            if vcm < 0 {
                removePosition(&p, grade: "GR2", from: .galley, position: "MR3A")
                removePosition(&p, grade: "GR2", from: .remain, position: "MR2")
                addPosition(&p, grade: "GR2", to: .galley, position: "MR2 (MR3A)")
            }
            if vcm < -1 {
                removePosition(&p, grade: "GR2", from: .remain, position: "ML4")
                removePosition(&p, grade: "GR1", from: .df, position: "ML4A")
                addPosition(&p, grade: "GR1", to: .df, position: "ML4 (ML4A)")
            } else { return p }
            if vcm < -2 {
                removePosition(&p, grade: "GR2", from: .remain, position: "MR5")
                removePosition(&p, grade: "GR1", from: .galley, position: "MR4A")
                addPosition(&p, grade: "GR1", to: .galley, position: "MR5 (MR4A)")
            } else { return p }
            if vcm < -3 {
                removePosition(&p, grade: "GR2", from: .remain, position: "ML3")
                removePosition(&p, grade: "GR1", from: .galley, position: "ML3A")
                addPosition(&p, grade: "GR1", to: .galley, position: "ML3 (ML3A)")
            } else { return p }
            if vcm < -4 {
                removePosition(&p, grade: "CSV", from: .only, position: "ML1")
                removePosition(&p, grade: "PUR", from: .only, position: "PUR")
                removePosition(&p, grade: "GR2", from: .remain, position: "MR1")
                addPosition(&p, grade: "PUR", to: .only, position: "ML1 (PUR)")
                addPosition(&p, grade: "CSV", to: .only, position: "MR1 (ML1)")
            } else { return p }

        // B773 4 class
        case 12, 16, 17:
            if vcm < 0 {
                removePosition(&p, grade: "GR2", from: .remain, position: "L5A")
            }
            if vcm < -1 {
                removePosition(&p, grade: "GR2", from: .df, position: "R5A")
                removePosition(&p, grade: "GR2", from: .remain, position: "R4")
                addPosition(&p, grade: "GR2", to: .df, position: "R4")
            } else { return p }
            if vcm < -2 {
                removePosition(&p, grade: "GR1", from: .galley, position: "L2A")
                removePosition(&p, grade: "GR2", from: .remain, position: "L4")
                addPosition(&p, grade: "GR1", to: .galley, position: "L4 (L2A)")
            } else { return p }
            if vcm < -3 {
                removePosition(&p, grade: "CSV", from: .only, position: "R2A")
                removePosition(&p, grade: "GR2", from: .df, position: "R4")
                addPosition(&p, grade: "CSV", to: .only, position: "R4 (R2A)")
            } else { return p }
            if vcm < -4 && isULR {
                removePosition(&p, grade: "FG1", from: .remain, position: "L1A")
                removePosition(&p, grade: "GR2", from: .remain, position: "R3")
                addPosition(&p, grade: "FG1", to: .remain, position: "R3 (L1A)")
            } else if vcm < -4 {
                removePosition(&p, grade: "FG1", from: .df, position: "R1")
                removePosition(&p, grade: "GR2", from: .remain, position: "R3")
                removePosition(&p, grade: "PUR", from: .only, position: "PUR")
                addPosition(&p, grade: "FG1", to: .df, position: "R3 (R1)")
                addPosition(&p, grade: "PUR", to: .only, position: "L1 (PUR)")
            } else { return p }
            if vcm < -5 && isULR {
                removePosition(&p, grade: "FG1", from: .df, position: "R1")
                removePosition(&p, grade: "GR2", from: .galley, position: "L3")
                removePosition(&p, grade: "PUR", from: .only, position: "PUR")
                addPosition(&p, grade: "FG1", to: .df, position: "L3 (R1)")
                addPosition(&p, grade: "PUR", to: .only, position: "L1 (PUR)")
            } else { return p }

        // A350 3 class
        case 13, 18:
            if vcm < 0 {
                removePosition(&p, grade: "GR2", from: .remain, position: "R4A")
            }
            if vcm < -1 {
                removePosition(&p, grade: "GR2", from: .remain, position: "L4A")
            } else { return p }
            if vcm < -2 {
                removePosition(&p, grade: "GR2", from: .df, position: "R3")
                removePosition(&p, grade: "GR1", from: .remain, position: "R2A")
                addPosition(&p, grade: "GR1", to: .remain, position: "R3 (R2A)")
            } else { return p }
            if vcm < -3 {
                removePosition(&p, grade: "GR2", from: .galley, position: "L3")
                removePosition(&p, grade: "GR1", from: .galley, position: "L1A")
                addPosition(&p, grade: "GR1", to: .galley, position: "L3 (L1A)")
            } else { return p }

        default:
            break
        }

        return p
    }

    // MARK: - Helpers

    private enum PositionSlot {
        case galley, df, remain, only
    }

    private static func removePosition(_ p: inout PositionMap, grade: String, from slot: PositionSlot, position: String) {
        guard var gp = p[grade] else { return }
        switch slot {
        case .galley: if let idx = gp.galley.firstIndex(of: position) { gp.galley.remove(at: idx) }
        case .df:     if let idx = gp.df.firstIndex(of: position) { gp.df.remove(at: idx) }
        case .remain: if let idx = gp.remain.firstIndex(of: position) { gp.remain.remove(at: idx) }
        case .only:   if let idx = gp.only.firstIndex(of: position) { gp.only.remove(at: idx) }
        }
        p[grade] = gp
    }

    private static func addPosition(_ p: inout PositionMap, grade: String, to slot: PositionSlot, position: String) {
        guard var gp = p[grade] else { return }
        switch slot {
        case .galley: gp.galley.append(position)
        case .df:     gp.df.append(position)
        case .remain: gp.remain.append(position)
        case .only:   gp.only.append(position)
        }
        p[grade] = gp
    }
}
