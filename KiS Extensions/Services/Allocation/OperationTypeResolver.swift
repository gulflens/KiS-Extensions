import Foundation

/// Determines the operation type code from aircraft registration, ULR status, and crew composition.
/// Direct port of load_positions.js operationType logic.
struct OperationTypeResolver {

    /// Resolves the operation type code used to look up positions and breaks.
    /// Returns nil if registration is not in fleet.
    static func resolve(registration: String, isULR: Bool, crewData: [CrewMember]) -> Int? {
        guard let baseType = FleetRegistry.fleet[registration] else { return nil }

        let csvCount = crewData.filter { $0.grade == .CSV }.count
        let fg1Count = crewData.filter { $0.grade == .FG1 }.count

        // A380 3 class ULR logic
        if [11, 9, 8].contains(baseType) && isULR && csvCount < 3 {
            // For LR (nonULR) A380 with breaks but with 2 CSVs only
            return baseType
        }
        if [11, 9, 8].contains(baseType) && isULR {
            return 908
        }
        if [11, 9, 8].contains(baseType) && !isULR && csvCount > 2 {
            // A380 non-ULR but with 3 CSV and less than 9 GR2s
            let gr2Count = crewData.filter { $0.grade == .GR2 }.count
            if gr2Count < 9 {
                return 908
            }
        }

        // B773 3 class ULR
        if [1, 2, 3, 6].contains(baseType) && isULR && fg1Count > 2 {
            return 901
        }

        // B773 4 class ULR
        if [12, 16].contains(baseType) && fg1Count > 2 && isULR {
            return 912
        }

        // B772 2 class ULR
        if [4].contains(baseType) && isULR {
            return 904
        }

        return baseType
    }

    /// Loads positions and breaks for a given operation, applying temp rules and VCM/extra adjustments.
    /// Port of loadPositions() from load_positions.js
    static func loadPositions(
        crewData: [CrewMember],
        registration: String,
        isULR: Bool,
        forTripsTableOnly: Bool = false
    ) -> (positions: PositionMap, breaks: [String: Int])? {
        guard let operationType = resolve(registration: registration, isULR: isULR, crewData: crewData) else {
            return nil
        }

        guard var thisFlightPositions = PositionsData.clonedPositions(for: operationType) else {
            return nil
        }

        let thisFlightBreaks = BreaksData.clonedBreaks(for: operationType) ?? [:]

        let gr1Count = crewData.filter { $0.grade == .GR1 }.count
        let fg1Count = crewData.filter { $0.grade == .FG1 }.count

        // Temp rule: B773 4th Gr1 added in stages 2024
        if [1, 2, 3, 6, 12, 16, 17, 912, 901].contains(operationType) && gr1Count == 4 {
            if var extra = thisFlightPositions["EXTRA"],
               let idx = extra.only.firstIndex(of: "R5C") {
                extra.only.remove(at: idx)
                thisFlightPositions["EXTRA"] = extra
                if var gr1 = thisFlightPositions["GR1"] {
                    gr1.remain.append("R5C")
                    thisFlightPositions["GR1"] = gr1
                }
            }
        }

        // Temp rule: B773 3rd Fg1 added for full turnarounds 2024
        if [1, 2, 3, 6, 12, 16, 17].contains(operationType) && fg1Count == 3 {
            if var extra = thisFlightPositions["EXTRA"],
               let idx = extra.only.firstIndex(of: "L1A") {
                extra.only.remove(at: idx)
                thisFlightPositions["EXTRA"] = extra
                if var fg1 = thisFlightPositions["FG1"] {
                    fg1.remain.append("L1A")
                    thisFlightPositions["FG1"] = fg1
                }
            }
        }

        if forTripsTableOnly {
            return (thisFlightPositions, thisFlightBreaks)
        }

        // Calculate VCM
        let requiredCrew = RequiredCrewCalculator.calculate(crewData: crewData, registration: registration, isULR: isULR)
        let vcm = crewData.count - requiredCrew

        // Check VCM by grades
        let grades: [String] = ["PUR", "CSV", "FG1", "GR1", "GR2", "CSA"]
        var variations: [String: Int] = [:]

        for grade in grades {
            let positionCount: Int
            if let gradePositions = thisFlightPositions[grade] {
                positionCount = gradePositions.allPositions.count
            } else {
                positionCount = 0
            }
            let crewCount = crewData.filter { $0.grade.rawValue == grade }.count
            let difference = crewCount - positionCount
            if difference != 0 {
                variations[grade] = difference
            }
        }

        if !variations.isEmpty {
            if vcm < 0 {
                guard let baseType = FleetRegistry.fleet[registration] else {
                    return (thisFlightPositions, thisFlightBreaks)
                }
                thisFlightPositions = VCMRulesEngine.apply(vcm: vcm, positions: thisFlightPositions, aircraftType: baseType, isULR: isULR)
            } else {
                thisFlightPositions = ExtraRulesEngine.apply(positions: thisFlightPositions, variations: variations)
            }
        }

        return (thisFlightPositions, thisFlightBreaks)
    }
}
