import Foundation

/// Main position allocation orchestrator.
/// Direct port of generate_positions.js generatePositions()
struct AllocationEngine {

    struct AllocationResult {
        var crewMembers: [CrewMember]
        var errors: [AllocationError]
    }

    struct AllocationError {
        let message: String
        let severity: Severity
        enum Severity { case error, warning, info }
    }

    /// Run the full allocation algorithm.
    /// - Parameters:
    ///   - crewData: Parsed crew members
    ///   - registration: Aircraft registration string
    ///   - isULR: Whether the flight is ultra-long-range
    ///   - numberOfDuties: Number of sectors to assign positions for
    ///   - hasBreaks: Per-sector flag indicating whether breaks apply
    /// - Returns: Updated crew members with positions/breaks assigned, and any errors
    static func allocate(
        crewData: [CrewMember],
        registration: String,
        isULR: Bool,
        numberOfDuties: Int,
        hasBreaks: [Bool]
    ) -> AllocationResult {
        var crew = crewData
        var errors: [AllocationError] = []

        // Load positions and breaks
        guard let loaded = OperationTypeResolver.loadPositions(
            crewData: crew,
            registration: registration,
            isULR: isULR,
            forTripsTableOnly: false
        ) else {
            errors.append(AllocationError(message: "Could not load positions for this aircraft", severity: .error))
            return AllocationResult(crewMembers: crew, errors: errors)
        }

        let positions = loaded.positions
        let breaks = loaded.breaks

        // Build language queues
        let languageQueues = LanguageQueueBuilder.build(from: crew)
        var mutableQueues = languageQueues

        // Determine aircraft model for DF count
        let aircraftModel: String = {
            guard let typeCode = FleetRegistry.fleet[registration],
                  let acType = AircraftTypes.types[typeCode] else { return "B773" }
            return acType.aircraftModel
        }()

        for i in 0..<numberOfDuties {
            // Deep copy positions for this sector (structs copy by value)
            var p = positions

            // === SELECT DF OPERATORS ===
            let numberOfRetailOperators = aircraftModel == "A380" ? 2 : 1
            var crewsWithRating = crew.filter { $0.ratingIR <= 20 && [.FG1, .GR1, .W, .GR2].contains($0.grade) }
                .sorted { $0.ratingIR < $1.ratingIR }

            // If not enough DF rated crew, supplement with junior GR1
            if crewsWithRating.count < numberOfRetailOperators {
                let candidates = crew.filter { $0.grade == .GR1 && !$0.outOfGrade && $0.ratingIR > 20 }
                    .sorted { $0.timeInGradeMonths < $1.timeInGradeMonths }
                var candidateIdx = 0
                while crewsWithRating.count < numberOfRetailOperators && candidateIdx < candidates.count {
                    crewsWithRating.append(candidates[candidateIdx])
                    candidateIdx += 1
                }
                if i == 0 {
                    if numberOfRetailOperators == 2 {
                        errors.append(AllocationError(message: "Not enough DF rating crew", severity: .error))
                    } else {
                        errors.append(AllocationError(message: "No DF rating crew", severity: .error))
                    }
                }
            }

            // Trim to required number
            while crewsWithRating.count > numberOfRetailOperators {
                crewsWithRating.removeLast()
            }

            // If A380 and both DF crew are same grade, shift a position
            if numberOfRetailOperators == 2 && crewsWithRating.count == 2 &&
               crewsWithRating[0].grade == crewsWithRating[1].grade {
                let grade = crewsWithRating[0].grade.rawValue
                if var gp = p[grade], !gp.remain.isEmpty {
                    let shifted = gp.remain.removeFirst()
                    gp.df.append(shifted)
                    p[grade] = gp
                } else if var gp = p[grade], !gp.galley.isEmpty {
                    let shifted = gp.galley.removeFirst()
                    gp.df.append(shifted)
                    p[grade] = gp
                }
            }

            // Assign DF positions
            for dfCrew in crewsWithRating {
                guard let crewIdx = crew.firstIndex(where: { $0.staffNumber == dfCrew.staffNumber }) else { continue }
                let grade = dfCrew.grade.rawValue
                if var gp = p[grade], !gp.df.isEmpty {
                    let position = gp.df.removeFirst()
                    crew[crewIdx].doingDF = true
                    crew[crewIdx].positions[i] = position
                    p[grade] = gp
                }
            }

            // Move unused DF positions to remain
            for grade in ["FG1", "GR1", "W", "GR2"] {
                if var gp = p[grade] {
                    gp.remain.append(contentsOf: gp.df)
                    gp.df = []
                    p[grade] = gp
                }
            }

            // === SELECT PAs ===
            for lang in mutableQueues.keys {
                guard let queue = mutableQueues[lang], let firstStaffNumber = queue.first else { continue }
                if let crewIdx = crew.firstIndex(where: { $0.staffNumber == firstStaffNumber }) {
                    if crew[crewIdx].doingPA[i] != nil {
                        crew[crewIdx].doingPA[i]!.append(lang)
                    } else {
                        crew[crewIdx].doingPA[i] = [lang]
                    }
                } else {
                    errors.append(AllocationError(message: "Not enough \(lang) language speakers", severity: .error))
                }
            }
            // Rotate queues
            for lang in mutableQueues.keys {
                if var queue = mutableQueues[lang], !queue.isEmpty {
                    let first = queue.removeFirst()
                    queue.append(first)
                    mutableQueues[lang] = queue
                }
            }

            // === SELECT POSITIONS ===
            for grade in p.keys.sorted() {
                guard let gp = p[grade] else { continue }

                if ["PUR", "CSV", "CSA"].contains(grade) {
                    // Assign "only" positions
                    for position in gp.only {
                        var candidateCrew = crew.filter { $0.grade.rawValue == grade && $0.positions[i] == nil }

                        if grade == "CSV" {
                            let newPosCandidates = candidateCrew.filter { !$0.lastPosition.contains(position) }
                            if !newPosCandidates.isEmpty { candidateCrew = newPosCandidates }
                        }

                        guard !candidateCrew.isEmpty else { continue }
                        let random = Int.random(in: 0..<candidateCrew.count)
                        let selected = candidateCrew[random]
                        guard let crewIdx = crew.firstIndex(where: { $0.staffNumber == selected.staffNumber }) else { continue }
                        crew[crewIdx].positions[i] = position
                        if !crew[crewIdx].lastPosition.isEmpty {
                            crew[crewIdx].lastPosition.removeFirst()
                        }
                        crew[crewIdx].lastPosition.append(position)
                    }
                } else if ["FG1", "GR1", "GR2", "W"].contains(grade) {
                    // Galley positions — prioritize crew > 6 months
                    for position in gp.galley {
                        var candidateCrew = crew.filter { $0.grade.rawValue == grade && $0.positions[i] == nil && $0.timeInGradeMonths > 6 }

                        if candidateCrew.count > 1 {
                            let newPosCandidates = candidateCrew.filter { !$0.lastPosition.contains(position) }
                            if !newPosCandidates.isEmpty { candidateCrew = newPosCandidates }
                        }

                        if candidateCrew.isEmpty {
                            // Fall back to most senior available
                            candidateCrew = crew.filter { $0.grade.rawValue == grade && $0.positions[i] == nil }
                                .sorted { $0.timeInGradeMonths > $1.timeInGradeMonths }
                            if i == 1 {
                                errors.append(AllocationError(message: "No senior crew for galley in grade: \(grade)", severity: .error))
                            }
                        }

                        guard !candidateCrew.isEmpty else { continue }
                        let idx = candidateCrew.count == 1 ? 0 : Int.random(in: 0..<candidateCrew.count)
                        let selected = candidateCrew[idx]
                        guard let crewIdx = crew.firstIndex(where: { $0.staffNumber == selected.staffNumber }) else { continue }
                        crew[crewIdx].positions[i] = position
                        if !crew[crewIdx].lastPosition.isEmpty {
                            crew[crewIdx].lastPosition.removeFirst()
                        }
                        crew[crewIdx].lastPosition.append(position)
                    }

                    // Remain positions — random assignment avoiding repetition
                    for position in gp.remain {
                        var candidateCrew = crew.filter { $0.grade.rawValue == grade && $0.positions[i] == nil }
                        let newPosCandidates = candidateCrew.filter { !$0.lastPosition.contains(position) }
                        if !newPosCandidates.isEmpty { candidateCrew = newPosCandidates }

                        guard !candidateCrew.isEmpty else { continue }
                        let random = Int.random(in: 0..<candidateCrew.count)
                        let selected = candidateCrew[random]
                        guard let crewIdx = crew.firstIndex(where: { $0.staffNumber == selected.staffNumber }) else { continue }
                        crew[crewIdx].positions[i] = position
                        if !crew[crewIdx].lastPosition.isEmpty {
                            crew[crewIdx].lastPosition.removeFirst()
                        }
                        crew[crewIdx].lastPosition.append(position)
                    }
                }
            }

            // === SELECT BREAKS ===
            if i < hasBreaks.count && hasBreaks[i] {
                for idx in crew.indices {
                    if let position = crew[idx].positions[i], let breakGroup = breaks[position] {
                        crew[idx].breaks[i] = breakGroup
                    }
                }
            }
        }

        return AllocationResult(crewMembers: crew, errors: errors)
    }
}
