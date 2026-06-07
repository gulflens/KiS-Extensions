import Foundation

// MARK: - We Care Schedule Engine (Stage 2)
//
// Deterministic generation of We Care cycle windows and per-cabin duty lists
// from a `WeCareFlightContext` and the decoded rule base. Pure logic — no UI,
// no persistence, no clock access.

enum WeCareScheduleEngine {

    // MARK: - Public API

    static func generate(
        context: WeCareFlightContext,
        rules: WeCareRules = WeCareRulesLoader.shared
    ) throws -> WeCareSchedule {

        guard (1...8).contains(context.flightCategory) else {
            throw WeCareScheduleError.invalidCategory(context.flightCategory)
        }
        guard context.landingMinute > context.takeoffMinute else {
            throw WeCareScheduleError.invalidWindow
        }

        let usableStart = context.takeoffMinute
        let usableEnd = context.landingMinute - context.beforeLandingBufferMinutes

        var schedules: [WeCareCabinSchedule] = []
        // Preserve caller order, de-duplicated.
        var seen = Set<WeCareCabinCode>()
        for cabin in context.operatingCabins where seen.insert(cabin).inserted {
            guard let rule = rules.cabin(cabin) else {
                throw WeCareScheduleError.unknownCabinRule(cabin)
            }
            let crew = try crewCount(for: cabin, rule: rule, context: context)
            let timing = rule.timing.mode(for: context.flightCategory)

            let cycles = buildCycles(
                cabin: cabin,
                rule: rule,
                crew: crew,
                timing: timing,
                category: context.flightCategory,
                usableStart: usableStart,
                usableEnd: usableEnd,
                mealBlocks: context.mealServiceBlocks,
                rules: rules
            )

            schedules.append(
                WeCareCabinSchedule(cabin: cabin, crewCount: crew, timing: timing, cycles: cycles)
            )
        }

        return WeCareSchedule(cabins: schedules)
    }

    // MARK: - Crew Resolution

    static func crewCount(
        for cabin: WeCareCabinCode,
        rule: WeCareCabinRule,
        context: WeCareFlightContext
    ) throws -> Int {
        switch rule.crew.mode {
        case .fixed:
            guard let value = rule.fixedCrew(forAircraft: context.aircraftKey) else {
                throw WeCareScheduleError.noFixedCrewForAircraft(cabin, aircraft: context.aircraftKey)
            }
            return value
        case .manual:
            guard let value = context.manualCrew[cabin], value > 0 else {
                throw WeCareScheduleError.missingManualCrew(cabin)
            }
            return value
        }
    }

    // MARK: - Cycle Building

    private static func buildCycles(
        cabin: WeCareCabinCode,
        rule: WeCareCabinRule,
        crew: Int,
        timing: WeCareTimingMode,
        category: Int,
        usableStart: Int,
        usableEnd: Int,
        mealBlocks: [WeCareMealBlock],
        rules: WeCareRules
    ) -> [WeCareCycleWindow] {

        guard usableEnd > usableStart else { return [] }

        let interval = rule.cycleIntervalMinutes
        let segments = freeSegments(
            usableStart: usableStart,
            usableEnd: usableEnd,
            mealBlocks: mealBlocks,
            timing: timing
        )

        let eForm = rules.eFormRequired(category: category)
        let includeRefreshments = rule.refreshmentsApply(category: category)

        var fullLegs: [WeCareDutyLeg] = [
            WeCareDutyLeg(kind: .cleanliness, durationMinutes: rule.duties.cleanliness),
            WeCareDutyLeg(kind: .customerCare, durationMinutes: rule.duties.customerCare)
        ]
        if includeRefreshments {
            fullLegs.append(WeCareDutyLeg(kind: .refreshments, durationMinutes: rule.duties.refreshments))
        }

        var cycles: [WeCareCycleWindow] = []
        var index = 1

        for segment in segments {
            let length = segment.end - segment.start
            let fullCount = length / interval

            for k in 0..<fullCount {
                let start = segment.start + k * interval
                cycles.append(
                    WeCareCycleWindow(
                        cabin: cabin, index: index,
                        start: start, end: start + interval,
                        crewCount: crew, legs: fullLegs,
                        isCleanlinessOnly: false, eFormRequired: eForm
                    )
                )
                index += 1
            }

            // Short before landing: in the final usable segment only, if the
            // leftover is under one interval but still fits a Cleanliness leg,
            // run a single Cleanliness-only cycle, then stop.
            if segment.end == usableEnd {
                let leftoverStart = segment.start + fullCount * interval
                let leftover = segment.end - leftoverStart
                if leftover >= rule.duties.cleanliness {
                    cycles.append(
                        WeCareCycleWindow(
                            cabin: cabin, index: index,
                            start: leftoverStart, end: leftoverStart + rule.duties.cleanliness,
                            crewCount: crew,
                            legs: [WeCareDutyLeg(kind: .cleanliness, durationMinutes: rule.duties.cleanliness)],
                            isCleanlinessOnly: true, eFormRequired: eForm
                        )
                    )
                    index += 1
                }
            }
        }

        return cycles
    }

    // MARK: - Free Segments

    /// Time segments available for cycles within the usable window, with meal
    /// services removed. For `betweenServices`, the leading segment before the
    /// first service is excluded (cycles run between and after services). For
    /// `ongoingAfterTakeoff`, the leading segment is kept (rotation starts after
    /// take-off).
    static func freeSegments(
        usableStart: Int,
        usableEnd: Int,
        mealBlocks: [WeCareMealBlock],
        timing: WeCareTimingMode
    ) -> [(start: Int, end: Int)] {

        let blocks = mealBlocks
            .map { (start: max($0.start, usableStart), end: min($0.end, usableEnd)) }
            .filter { $0.start < $0.end }
            .sorted { $0.start < $1.start }

        var segments: [(start: Int, end: Int)] = []
        var cursor = usableStart
        for block in blocks {
            if block.start > cursor { segments.append((cursor, block.start)) }
            cursor = max(cursor, block.end)
        }
        if cursor < usableEnd { segments.append((cursor, usableEnd)) }

        if timing == .betweenServices, let firstEnd = blocks.first?.end {
            segments = segments.filter { $0.start >= firstEnd }
        }

        return segments
    }
}
