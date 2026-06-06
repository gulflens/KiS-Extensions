import Foundation

// MARK: - We Care State

@Observable
class WeCareState {

    // MARK: - Flight Times (minutes from midnight)

    var takeoffMin: Int = 0
    var landingMin: Int = 0
    var settlingMin: Int = 20
    var useAutoTopOfDescent: Bool = true
    var manualTopOfDescentMin: Int = 0

    var flightDurationMin: Int {
        landingMin - takeoffMin
    }

    var topOfDescentMin: Int {
        useAutoTopOfDescent ? landingMin - 30 : manualTopOfDescentMin
    }

    // MARK: - Cabin Selection

    var enableFC: Bool = false
    var enableJC: Bool = true
    var enableWC: Bool = false
    var enableYC: Bool = true

    var enabledCabins: [WeCareCabin] {
        var cabins: [WeCareCabin] = []
        if enableFC { cabins.append(.firstClass) }
        if enableJC { cabins.append(.businessClass) }
        if enableWC { cabins.append(.premiumEconomy) }
        if enableYC { cabins.append(.economyClass) }
        return cabins
    }

    // MARK: - Services

    var numberOfServices: Int = 1
    var serviceDurationsJC: [Int] = [0, 0, 0]
    var serviceDurationsYC: [Int] = [0, 0, 0]

    /// Explicit service start times (minutes from midnight).
    /// When populated from a CalculationResult the calculator uses these directly.
    /// When empty the calculator auto-computes placements from the standard formula.
    var serviceStartMins: [Int] = []

    // MARK: - Crew Assignment

    var crewByCabin: [WeCareCabin: [WeCareCrewResolver.CrewEntry]] = [:]
    var breakEntries: [WeCareBreakEntry] = []

    // MARK: - Aircraft Info

    var operationType: Int = 0
    var aircraftModel: String = ""
    var numberOfClasses: Int = 2

    var availableCabins: [WeCareCabin] {
        WeCareCalculator.availableCabins(model: aircraftModel, classes: numberOfClasses)
    }

    // MARK: - Auto-configure Cabins

    func configureCabinsFromAircraft() {
        let available = availableCabins
        enableFC = available.contains(.firstClass)
        enableJC = available.contains(.businessClass)
        enableWC = available.contains(.premiumEconomy)
        enableYC = available.contains(.economyClass)
    }

    // MARK: - Load from PlannedSector

    func loadFromSector(_ sector: PlannedSector) {
        if let takeoff = sector.savedTakeOffTime {
            takeoffMin = parseHHmm(takeoff)
        }

        if let flightTime = sector.savedFlightTime {
            landingMin = takeoffMin + parseHHmm(flightTime)
        } else {
            var arr = parseHHmm(sector.arrivalTime)
            if arr < takeoffMin { arr += 1440 }
            landingMin = arr
        }

        if let numSvc = sector.savedNumberOfServices, numSvc > 0 {
            numberOfServices = numSvc
        }

        if let d = sector.savedService1JC { serviceDurationsJC[0] = d }
        if let d = sector.savedService1YC { serviceDurationsYC[0] = d }
        if let d = sector.savedService2JC { serviceDurationsJC[1] = d }
        if let d = sector.savedService2YC { serviceDurationsYC[1] = d }
        if let d = sector.savedService3JC { serviceDurationsJC[2] = d }
        if let d = sector.savedService3YC { serviceDurationsYC[2] = d }

        if let settling = sector.savedCrewRestSettlingMin {
            settlingMin = settling
        }

        loadAircraftFromRegistration(sector.registration)
    }

    // MARK: - Load from CalculationResult

    func loadFromCalculationResult(_ result: CalculationResult, sector: PlannedSector) {
        takeoffMin = result.T0
        landingMin = result.LAND

        serviceStartMins = result.services.map { $0.start }
        numberOfServices = result.services.count

        if let d = sector.savedService1JC { serviceDurationsJC[0] = d }
        if let d = sector.savedService1YC { serviceDurationsYC[0] = d }
        if let d = sector.savedService2JC { serviceDurationsJC[1] = d }
        if let d = sector.savedService2YC { serviceDurationsYC[1] = d }
        if let d = sector.savedService3JC { serviceDurationsJC[2] = d }
        if let d = sector.savedService3YC { serviceDurationsYC[2] = d }

        breakEntries = result.breaks.enumerated().map { i, block in
            WeCareBreakEntry(group: i + 1, startMin: block.start, endMin: block.end)
        }

        loadAircraftFromRegistration(sector.registration)
    }

    // MARK: - Load Crew

    func loadCrew(from sector: PlannedSector) {
        crewByCabin = WeCareCrewResolver.resolve(sector: sector, operationType: operationType)
    }

    // MARK: - Helpers

    private func loadAircraftFromRegistration(_ registration: String?) {
        guard let reg = registration else { return }
        let cleanReg = reg.replacingOccurrences(of: "-", with: "")
        guard let opType = FleetRegistry.fleet[cleanReg] else { return }
        operationType = opType
        guard let aircraft = AircraftTypes.types[opType] else { return }
        aircraftModel = aircraft.aircraftModel
        numberOfClasses = aircraft.classes
        configureCabinsFromAircraft()
    }

    private func parseHHmm(_ str: String) -> Int {
        let parts = str.split(separator: ":")
        guard parts.count == 2,
              let h = Int(parts[0]),
              let m = Int(parts[1]) else { return 0 }
        return h * 60 + m
    }
}
