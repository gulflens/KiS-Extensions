import Foundation

/// Handles surplus crew by assigning extra positions.
/// Direct port of extra_rules.js
struct ExtraRulesEngine {
    static func apply(positions: PositionMap, variations: [String: Int]) -> PositionMap {
        var p = positions
        var vars = variations

        for grade in vars.keys {
            while (vars[grade] ?? 0) > 0 {
                // Pop from EXTRA.only
                guard var extra = p["EXTRA"], !extra.only.isEmpty else { break }
                let extraPosition = extra.only.removeLast()
                p["EXTRA"] = extra

                if ["PUR", "CSV", "CSA"].contains(grade) {
                    if var gp = p[grade] {
                        gp.only.append(extraPosition)
                        p[grade] = gp
                    }
                } else {
                    if var gp = p[grade] {
                        gp.remain.append(extraPosition)
                        p[grade] = gp
                    }
                }
                vars[grade] = (vars[grade] ?? 0) - 1
            }
        }

        return p
    }
}
