import Foundation

// MARK: - We Care Crew Resolver

enum WeCareCrewResolver {

    // MARK: - Crew Entry

    struct CrewEntry: Identifiable {
        let id: String
        let nickname: String
        let grade: String
        let position: String
        let breakGroup: Int
        let isUpperDeck: Bool
    }

    // MARK: - Resolve Available Crew

    static func resolve(
        sector: PlannedSector,
        operationType: Int
    ) -> [WeCareCabin: [CrewEntry]] {
        guard let data = sector.crewPositionsJSON,
              let positions = try? JSONDecoder().decode([SectorCrewPosition].self, from: data) else {
            return [:]
        }

        let positionMap = PositionsData.positions(for: operationType)
        var result: [WeCareCabin: [CrewEntry]] = [:]

        for crew in positions {
            guard let cabin = cabinForGrade(crew.grade) else { continue }
            if isGalleyPosition(crew.position, grade: crew.grade, positionMap: positionMap) { continue }

            let entry = CrewEntry(
                id: crew.staffNumber,
                nickname: crew.nickname,
                grade: crew.grade,
                position: crew.position,
                breakGroup: crew.breakGroup,
                isUpperDeck: crew.position.hasPrefix("U")
            )
            result[cabin, default: []].append(entry)
        }

        return result
    }

    // MARK: - Assign Crew to Cycles

    static func assignCrew(
        cabinResults: inout [CabinWeCareResult],
        crewByCabin: [WeCareCabin: [CrewEntry]],
        breakSchedule: [WeCareBreakEntry]
    ) {
        for i in cabinResults.indices {
            let cabin = cabinResults[i].cabin
            let crew = crewByCabin[cabin] ?? []
            guard !crew.isEmpty else { continue }

            var assignmentCounts: [String: Int] = [:]
            for c in crew { assignmentCounts[c.id] = 0 }

            for g in cabinResults[i].gaps.indices {
                for c in cabinResults[i].gaps[g].cycles.indices {
                    let cycle = cabinResults[i].gaps[g].cycles[c]

                    let available = crew.filter { entry in
                        !isOnBreak(entry, during: cycle, breakSchedule: breakSchedule)
                    }

                    let pool = available.isEmpty ? crew : available

                    let sorted = pool.sorted { a, b in
                        (assignmentCounts[a.id] ?? 0) < (assignmentCounts[b.id] ?? 0)
                    }

                    if let assigned = sorted.first {
                        cabinResults[i].gaps[g].cycles[c].assignedCrew = [assigned.nickname]
                        assignmentCounts[assigned.id, default: 0] += 1
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private static func cabinForGrade(_ grade: String) -> WeCareCabin? {
        switch grade {
        case "FG1": return .firstClass
        case "GR1": return .businessClass
        case "W":   return .premiumEconomy
        case "GR2": return .economyClass
        default:    return nil
        }
    }

    private static func isGalleyPosition(
        _ position: String,
        grade: String,
        positionMap: PositionMap?
    ) -> Bool {
        guard let map = positionMap, let gradePositions = map[grade] else { return false }
        return gradePositions.galley.contains(position)
    }

    private static func isOnBreak(
        _ crew: CrewEntry,
        during cycle: WeCareCycle,
        breakSchedule: [WeCareBreakEntry]
    ) -> Bool {
        guard crew.breakGroup > 0 else { return false }
        guard let schedule = breakSchedule.first(where: { $0.group == crew.breakGroup }) else {
            return false
        }
        return cycle.startMin < schedule.endMin && cycle.endMin > schedule.startMin
    }
}
