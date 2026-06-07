import XCTest
@testable import KiS_Extensions

// MARK: - We Care Rules Tests (Stage 1)

final class WeCareRulesTests: XCTestCase {

    private func loadRules() -> WeCareRules {
        WeCareRulesLoader.load()
    }

    // MARK: Decode

    func testRuleBaseDecodes() {
        let rules = loadRules()
        XCTAssertEqual(rules.version, 1)
        XCTAssertEqual(rules.sourceVersion, "V1.30 (24APR2026)")
    }

    func testEveryCabinDecodes() {
        let rules = loadRules()
        for code in WeCareCabinCode.allCases {
            XCTAssertNotNil(rules.cabin(code), "Cabin \(code.rawValue) should decode from the rule base")
        }
        XCTAssertEqual(rules.cabins.count, WeCareCabinCode.allCases.count)
    }

    // MARK: Intervals & durations

    func testYCLIntervalIs45() {
        // Guards the documented source inconsistency: YCL is 45, not 30.
        let ycl = loadRules().cabin(.YCL)
        XCTAssertEqual(ycl?.cycleIntervalMinutes, 45)
        XCTAssertEqual(ycl?.duties.cleanliness, 15)
        XCTAssertEqual(ycl?.duties.customerCare, 15)
        XCTAssertEqual(ycl?.duties.refreshments, 15)
    }

    func testPremiumCabinsAre30With10MinuteDuties() {
        let rules = loadRules()
        for code in [WeCareCabinCode.WCL, .JCL, .FCL] {
            let cabin = rules.cabin(code)
            XCTAssertEqual(cabin?.cycleIntervalMinutes, 30, "\(code.rawValue) interval")
            XCTAssertEqual(cabin?.duties.cleanliness, 10)
            XCTAssertEqual(cabin?.duties.customerCare, 10)
            XCTAssertEqual(cabin?.duties.refreshments, 10)
        }
    }

    // MARK: Crew resolution

    func testJCLCrewByAircraft() {
        let jcl = loadRules().cabin(.JCL)
        XCTAssertEqual(jcl?.crew.mode, .fixed)
        XCTAssertEqual(jcl?.fixedCrew(forAircraft: "A380"), 4)
        XCTAssertEqual(jcl?.fixedCrew(forAircraft: "B773"), 2)
        XCTAssertEqual(jcl?.fixedCrew(forAircraft: "B772"), 2)
        XCTAssertEqual(jcl?.fixedCrew(forAircraft: "A350"), 2)
        XCTAssertNil(jcl?.fixedCrew(forAircraft: "A320"), "Unknown aircraft yields no fixed JCL crew")
    }

    func testFCLCrewIsFixedOne() {
        let fcl = loadRules().cabin(.FCL)
        XCTAssertEqual(fcl?.crew.mode, .fixed)
        XCTAssertEqual(fcl?.fixedCrew(forAircraft: "A380"), 1)
        XCTAssertEqual(fcl?.fixedCrew(forAircraft: "B777"), 1)
    }

    func testManualCabinsHaveNoFixedCrew() {
        let rules = loadRules()
        for code in [WeCareCabinCode.YCL, .WCL] {
            let cabin = rules.cabin(code)
            XCTAssertEqual(cabin?.crew.mode, .manual)
            XCTAssertNil(cabin?.fixedCrew(forAircraft: "A380"), "\(code.rawValue) is manual")
            XCTAssertNotNil(cabin?.crew.manualHint, "\(code.rawValue) should carry a manual hint")
        }
    }

    // MARK: Refreshment style & gating

    func testRefreshmentStyles() {
        let rules = loadRules()
        XCTAssertEqual(rules.cabin(.YCL)?.refreshmentStyle, .cart)
        XCTAssertEqual(rules.cabin(.WCL)?.refreshmentStyle, .tray)
    }

    func testRefreshmentsGateAtCategory3() {
        let rules = loadRules()
        for code in WeCareCabinCode.allCases {
            let cabin = rules.cabin(code)
            XCTAssertEqual(cabin?.refreshmentMinCategory, 3)
            XCTAssertEqual(cabin?.refreshmentsApply(category: 2), false)
            XCTAssertEqual(cabin?.refreshmentsApply(category: 3), true)
            XCTAssertEqual(cabin?.refreshmentsApply(category: 8), true)
        }
    }

    // MARK: Timing

    func testUniformTimingForNonFCL() {
        let rules = loadRules()
        for code in [WeCareCabinCode.YCL, .WCL, .JCL] {
            XCTAssertEqual(rules.cabin(code)?.timing.mode(for: 1), .betweenServices)
            XCTAssertEqual(rules.cabin(code)?.timing.mode(for: 8), .betweenServices)
        }
    }

    func testFCLTimingSplitsByCategory() {
        let fcl = loadRules().cabin(.FCL)
        XCTAssertEqual(fcl?.timing.mode(for: 1), .betweenServices)
        XCTAssertEqual(fcl?.timing.mode(for: 3), .betweenServices)
        XCTAssertEqual(fcl?.timing.mode(for: 4), .ongoingAfterTakeoff)
        XCTAssertEqual(fcl?.timing.mode(for: 8), .ongoingAfterTakeoff)
    }

    // MARK: e-form

    func testGovernanceRulesPresent() {
        let rules = loadRules()
        XCTAssertFalse(rules.governanceRules.isEmpty)
        XCTAssertGreaterThanOrEqual(rules.governanceRules.count, 6)
    }

    func testEFormRequiredCategories3To8() {
        let rules = loadRules()
        XCTAssertEqual(rules.eFormRequired(category: 2), false)
        XCTAssertEqual(rules.eFormRequired(category: 3), true)
        XCTAssertEqual(rules.eFormRequired(category: 8), true)
    }
}
