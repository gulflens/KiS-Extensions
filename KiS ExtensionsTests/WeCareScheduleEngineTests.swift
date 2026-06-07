import XCTest
@testable import KiS_Extensions

// MARK: - We Care Schedule Engine Tests (Stage 2)

final class WeCareScheduleEngineTests: XCTestCase {

    private let rules = WeCareRulesLoader.load()

    // A roomy window: take-off at 0, landing at 600 (10 h), 30 min before-landing buffer.
    private func context(
        aircraft: String = "A380",
        category: Int = 5,
        cabins: [WeCareCabinCode],
        takeoff: Int = 0,
        landing: Int = 600,
        meals: [WeCareMealBlock] = [],
        manual: [WeCareCabinCode: Int] = [:]
    ) -> WeCareFlightContext {
        WeCareFlightContext(
            aircraftKey: aircraft,
            flightCategory: category,
            operatingCabins: cabins,
            takeoffMinute: takeoff,
            landingMinute: landing,
            mealServiceBlocks: meals,
            beforeLandingBufferMinutes: 30,
            manualCrew: manual
        )
    }

    // MARK: JCL crew by aircraft

    func testJCLCrewA380VersusB777() throws {
        let a380 = try WeCareScheduleEngine.generate(context: context(aircraft: "A380", cabins: [.JCL]), rules: rules)
        XCTAssertEqual(a380.cabin(.JCL)?.crewCount, 4)

        let b777 = try WeCareScheduleEngine.generate(context: context(aircraft: "B777", cabins: [.JCL]), rules: rules)
        XCTAssertEqual(b777.cabin(.JCL)?.crewCount, 2)
    }

    // MARK: FCL cat 2 vs cat 6 (timing + duties)

    func testFCLCategory2IsBetweenServicesWithoutRefreshments() throws {
        let meals = [WeCareMealBlock(start: 60, end: 120)]
        let schedule = try WeCareScheduleEngine.generate(
            context: context(category: 2, cabins: [.FCL], meals: meals), rules: rules
        )
        let fcl = try XCTUnwrap(schedule.cabin(.FCL))
        XCTAssertEqual(fcl.timing, .betweenServices)
        XCTAssertEqual(fcl.crewCount, 1)
        let firstFull = try XCTUnwrap(fcl.cycles.first { !$0.isCleanlinessOnly })
        // Cat 1 to 2: Cleanliness + Customer Care only, no refreshments leg.
        XCTAssertEqual(firstFull.legs.map(\.kind), [.cleanliness, .customerCare])
        XCTAssertFalse(firstFull.eFormRequired)
        // betweenServices excludes the pre-first-service segment: no cycle starts before the first meal block.
        XCTAssertTrue(fcl.cycles.allSatisfy { $0.start >= 120 })
    }

    func testFCLCategory6IsOngoingWithRefreshments() throws {
        let meals = [WeCareMealBlock(start: 60, end: 120)]
        let schedule = try WeCareScheduleEngine.generate(
            context: context(category: 6, cabins: [.FCL], meals: meals), rules: rules
        )
        let fcl = try XCTUnwrap(schedule.cabin(.FCL))
        XCTAssertEqual(fcl.timing, .ongoingAfterTakeoff)
        let firstFull = try XCTUnwrap(fcl.cycles.first { !$0.isCleanlinessOnly })
        XCTAssertEqual(firstFull.legs.map(\.kind), [.cleanliness, .customerCare, .refreshments])
        XCTAssertTrue(firstFull.eFormRequired)
        // Ongoing keeps the leading segment: a cycle starts at take-off.
        XCTAssertEqual(fcl.cycles.first?.start, 0)
    }

    // MARK: YCL 45-minute spacing

    func testYCLCyclesAreSpaced45Minutes() throws {
        let schedule = try WeCareScheduleEngine.generate(
            context: context(category: 5, cabins: [.YCL], landing: 330, manual: [.YCL: 2]), rules: rules
        )
        let ycl = try XCTUnwrap(schedule.cabin(.YCL))
        let fullStarts = ycl.cycles.filter { !$0.isCleanlinessOnly }.map(\.start)
        XCTAssertGreaterThanOrEqual(fullStarts.count, 2)
        for i in 1..<fullStarts.count {
            XCTAssertEqual(fullStarts[i] - fullStarts[i - 1], 45)
        }
        // Each full YCL cycle spans 45 minutes (15 + 15 + 15).
        let firstFull = try XCTUnwrap(ycl.cycles.first { !$0.isCleanlinessOnly })
        XCTAssertEqual(firstFull.end - firstFull.start, 45)
        XCTAssertEqual(firstFull.legs.reduce(0) { $0 + $1.durationMinutes }, 45)
    }

    // MARK: Suspension across a mid-flight meal block

    func testCyclesSuspendAcrossMealBlock() throws {
        // Ongoing FCL so cycles run both before and after the mid block.
        let meals = [WeCareMealBlock(start: 90, end: 150)]
        let schedule = try WeCareScheduleEngine.generate(
            context: context(category: 6, cabins: [.FCL], landing: 360, meals: meals), rules: rules
        )
        let fcl = try XCTUnwrap(schedule.cabin(.FCL))
        // No cycle overlaps the meal block.
        for cycle in fcl.cycles {
            XCTAssertFalse(cycle.start < 150 && cycle.end > 90, "cycle \(cycle.index) overlaps the meal block")
        }
        XCTAssertTrue(fcl.cycles.contains { $0.end <= 90 }, "expected a cycle before the block")
        XCTAssertTrue(fcl.cycles.contains { $0.start >= 150 }, "expected a cycle after the block")
    }

    // MARK: Short-before-landing cleanliness-only

    func testShortBeforeLandingEmitsCleanlinessOnlyCycle() throws {
        // FCL ongoing, window chosen so the last segment has a 10 to 29 min tail.
        // Usable window = [0, landing-30]. Pick landing so usable length mod 30
        // leaves >= 10 (cleanliness) and < 30.
        // landing 130 -> usable [0,100] -> 3 full (0,30,60) end 90, tail 10 == cleanliness.
        let schedule = try WeCareScheduleEngine.generate(
            context: context(category: 6, cabins: [.FCL], landing: 130), rules: rules
        )
        let fcl = try XCTUnwrap(schedule.cabin(.FCL))
        let cleanliness = fcl.cycles.filter(\.isCleanlinessOnly)
        XCTAssertEqual(cleanliness.count, 1)
        let only = try XCTUnwrap(cleanliness.first)
        XCTAssertEqual(only.legs.map(\.kind), [.cleanliness])
        XCTAssertEqual(only.end - only.start, 10)
        XCTAssertEqual(only.start, 90)
        // It is the last cycle in the cabin.
        XCTAssertEqual(fcl.cycles.last?.index, only.index)
    }

    // MARK: Missing manual crew validation

    func testMissingYCLCrewThrows() {
        XCTAssertThrowsError(
            try WeCareScheduleEngine.generate(context: context(cabins: [.YCL]), rules: rules)
        ) { error in
            XCTAssertEqual(error as? WeCareScheduleError, .missingManualCrew(.YCL))
        }
    }

    func testManualCrewProvidedSucceeds() throws {
        let schedule = try WeCareScheduleEngine.generate(
            context: context(cabins: [.WCL], manual: [.WCL: 3]), rules: rules
        )
        XCTAssertEqual(schedule.cabin(.WCL)?.crewCount, 3)
    }

    // MARK: Invalid input

    func testInvalidCategoryThrows() {
        XCTAssertThrowsError(
            try WeCareScheduleEngine.generate(context: context(category: 9, cabins: [.FCL]), rules: rules)
        ) { error in
            XCTAssertEqual(error as? WeCareScheduleError, .invalidCategory(9))
        }
    }

    func testInvalidWindowThrows() {
        XCTAssertThrowsError(
            try WeCareScheduleEngine.generate(
                context: context(cabins: [.FCL], takeoff: 500, landing: 400), rules: rules
            )
        ) { error in
            XCTAssertEqual(error as? WeCareScheduleError, .invalidWindow)
        }
    }
}
