import Foundation

// MARK: - We Care Calculator

enum WeCareCalculator {

    static let minimumFlightMinutes = 210

    // MARK: - Main Calculation

    static func calculate(state: WeCareState) -> WeCareResult {
        let flightMin = state.flightDurationMin

        guard flightMin >= minimumFlightMinutes else {
            return WeCareResult(
                isEligible: false,
                flightDurationMin: flightMin,
                cabinResults: [],
                servicePlacements: [],
                ineligibilityReason: "Flight must be longer than 3 hours 30 minutes"
            )
        }

        guard state.numberOfServices >= 1 else {
            return WeCareResult(
                isEligible: false,
                flightDurationMin: flightMin,
                cabinResults: [],
                servicePlacements: [],
                ineligibilityReason: "At least one service is required"
            )
        }

        let placements = servicePlacements(for: state)

        var cabinResults: [CabinWeCareResult] = []
        for cabin in state.enabledCabins {
            cabinResults.append(cabinCycles(cabin: cabin, placements: placements, state: state))
        }

        return WeCareResult(
            isEligible: true,
            flightDurationMin: flightMin,
            cabinResults: cabinResults,
            servicePlacements: placements,
            ineligibilityReason: nil
        )
    }

    // MARK: - Service Placements

    static func servicePlacements(for state: WeCareState) -> [WeCareServicePlacement] {
        if state.serviceStartMins.count >= state.numberOfServices {
            return (0..<state.numberOfServices).map { i in
                WeCareServicePlacement(
                    serviceNumber: i + 1,
                    startMin: state.serviceStartMins[i],
                    durationJC: state.serviceDurationsJC[i],
                    durationYC: state.serviceDurationsYC[i]
                )
            }
        }
        return autoComputePlacements(state: state)
    }

    // MARK: - Auto-Compute Placements

    private static func autoComputePlacements(state: WeCareState) -> [WeCareServicePlacement] {
        let T0 = state.takeoffMin
        let F = state.flightDurationMin
        let LAND = T0 + F
        let TWENTY = LAND - 50
        let isLong = F > 240
        let N = state.numberOfServices

        let firstStart = isLong ? T0 + 10 + state.settlingMin : T0 + 10

        let djc0 = state.serviceDurationsJC[0]
        let dyc0 = state.serviceDurationsYC[0]
        let djc1 = state.serviceDurationsJC[1]
        let dyc1 = state.serviceDurationsYC[1]
        let djc2 = state.serviceDurationsJC[2]
        let dyc2 = state.serviceDurationsYC[2]

        var placements: [WeCareServicePlacement] = []

        if N == 1 {
            placements.append(WeCareServicePlacement(
                serviceNumber: 1, startMin: firstStart,
                durationJC: djc0, durationYC: dyc0
            ))
        } else if N == 2 {
            placements.append(WeCareServicePlacement(
                serviceNumber: 1, startMin: firstStart,
                durationJC: djc0, durationYC: dyc0
            ))
            let lastDur = max(djc1, dyc1)
            let lastStart = TWENTY - lastDur
            placements.append(WeCareServicePlacement(
                serviceNumber: 2, startMin: lastStart,
                durationJC: djc1, durationYC: dyc1
            ))
        } else if N >= 3 {
            let maxDur0 = max(djc0, dyc0)
            let maxDur1 = max(djc1, dyc1)
            let maxDur2 = max(djc2, dyc2)
            let s1End = firstStart + maxDur0
            let s3Start = TWENTY - maxDur2
            let midSnap = snap5((s1End + s3Start) / 2)
            let s2Start = snap5(midSnap - maxDur1 / 2)

            placements.append(WeCareServicePlacement(
                serviceNumber: 1, startMin: firstStart,
                durationJC: djc0, durationYC: dyc0
            ))
            placements.append(WeCareServicePlacement(
                serviceNumber: 2, startMin: s2Start,
                durationJC: djc1, durationYC: dyc1
            ))
            placements.append(WeCareServicePlacement(
                serviceNumber: 3, startMin: s3Start,
                durationJC: djc2, durationYC: dyc2
            ))
        }

        return placements
    }

    // MARK: - Cabin Cycles

    private static func cabinCycles(
        cabin: WeCareCabin,
        placements: [WeCareServicePlacement],
        state: WeCareState
    ) -> CabinWeCareResult {
        let topOfDescent = state.topOfDescentMin
        let cycleDuration = cabin.cycleDurationMin
        let isPremium = cabin.usesPremiumTiming

        let relevant = placements.filter { svc in
            isPremium ? svc.durationJC > 0 : svc.durationYC > 0
        }

        var gaps: [WeCareGap] = []
        var globalCycleCounter = 0

        if relevant.isEmpty {
            let T0 = state.takeoffMin
            let isLong = state.flightDurationMin > 240
            let windowStart = isLong ? T0 + 10 + state.settlingMin : T0 + 10
            let available = topOfDescent - windowStart
            if available >= cycleDuration {
                let numCycles = available / cycleDuration
                var cycles: [WeCareCycle] = []
                for c in 0..<numCycles {
                    globalCycleCounter += 1
                    let cycleStart = windowStart + c * cycleDuration
                    cycles.append(WeCareCycle(
                        cabin: cabin, cycleNumber: globalCycleCounter,
                        gapIndex: 0, startMin: cycleStart,
                        endMin: cycleStart + cycleDuration, assignedCrew: []
                    ))
                }
                gaps.append(WeCareGap(
                    gapIndex: 0, afterService: 0,
                    startMin: windowStart, endMin: topOfDescent,
                    availableMin: available, cycles: cycles
                ))
            }
        } else {
            for (i, svc) in relevant.enumerated() {
                let serviceEnd = svc.endMin(premium: isPremium)

                let gapEnd: Int
                if i + 1 < relevant.count {
                    gapEnd = relevant[i + 1].startMin
                } else {
                    gapEnd = topOfDescent
                }

                let available = gapEnd - serviceEnd
                guard available >= cycleDuration else { continue }

                let numCycles = available / cycleDuration
                var cycles: [WeCareCycle] = []

                for c in 0..<numCycles {
                    globalCycleCounter += 1
                    let cycleStart = serviceEnd + c * cycleDuration
                    cycles.append(WeCareCycle(
                        cabin: cabin, cycleNumber: globalCycleCounter,
                        gapIndex: i, startMin: cycleStart,
                        endMin: cycleStart + cycleDuration, assignedCrew: []
                    ))
                }

                gaps.append(WeCareGap(
                    gapIndex: i, afterService: svc.serviceNumber,
                    startMin: serviceEnd, endMin: gapEnd,
                    availableMin: available, cycles: cycles
                ))
            }
        }

        return CabinWeCareResult(
            cabin: cabin,
            gaps: gaps,
            totalCycles: globalCycleCounter
        )
    }

    // MARK: - Available Cabins for Aircraft

    static func availableCabins(model: String, classes: Int) -> [WeCareCabin] {
        switch (model, classes) {
        case ("A350", _):
            return [.businessClass, .premiumEconomy, .economyClass]
        case (_, 2):
            return [.businessClass, .economyClass]
        case (_, 3):
            return [.firstClass, .businessClass, .economyClass]
        case (_, 4):
            return [.firstClass, .businessClass, .premiumEconomy, .economyClass]
        default:
            return [.businessClass, .economyClass]
        }
    }

    // MARK: - Helpers

    static func snap5(_ v: Int) -> Int {
        Int((Double(v) / 5.0).rounded()) * 5
    }

    static func formatMinutes(_ minutes: Int) -> String {
        let normalized = ((minutes % 1440) + 1440) % 1440
        let h = normalized / 60
        let m = normalized % 60
        return String(format: "%02d:%02d", h, m)
    }
}
