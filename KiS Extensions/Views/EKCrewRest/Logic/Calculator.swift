import Foundation

// MARK: - Calculator

/// Direct port of the demo HTML's `calc()` function.
/// Comments preserve the algorithm intent line-by-line so future changes
/// stay aligned with the JavaScript reference implementation.
enum Calculator {

    static func calc(_ s: CrewRestState) -> CalculationResult {
        let T0 = s.takeoffMin
        let F  = s.flightMin
        let LAND = T0 + F
        let TWENTY = LAND - 50
        let TOD = LAND - 30
        let isLong = F > 240

        // Settling-in window (only on long flights)
        var settlingStart: Int? = nil
        var settlingEnd:   Int? = nil
        let firstStart: Int
        if isLong {
            let ss = T0 + 10
            settlingStart = ss
            settlingEnd = ss + s.settlingMin
            firstStart = ss + s.settlingMin
        } else {
            firstStart = T0 + 10
        }

        // Service block placement
        let N = s.numServices
        let D = s.services
        func snap5(_ v: Int) -> Int { Int((Double(v) / 5.0).rounded()) * 5 }

        var services: [TimedBlock] = []
        if N == 1 {
            services.append(.init(label: "Service", start: firstStart, end: firstStart + D[0]))
        } else if N == 2 {
            services.append(.init(label: "First Service", start: firstStart, end: firstStart + D[0]))
            services.append(.init(label: "Last Service", start: TWENTY - D[1], end: TWENTY))
        } else {
            let s1End = firstStart + D[0]
            let s3Start = TWENTY - D[2]
            let midSnap = snap5((s1End + s3Start) / 2)
            let s2Start = snap5(midSnap - D[1] / 2)
            services.append(.init(label: "First Service", start: firstStart, end: s1End))
            services.append(.init(label: "Middle Service", start: s2Start, end: s2Start + D[1]))
            services.append(.init(label: "Last Service", start: s3Start, end: TWENTY))
        }

        // Compute rest windows between services
        func computeWindows(_ svcs: [TimedBlock]) -> [(start: Int, end: Int)] {
            var wins: [(Int, Int)] = []
            if N == 1 {
                wins.append((svcs[0].end, TWENTY))
            } else {
                for i in 0..<(N - 1) {
                    wins.append((svcs[i].end, svcs[i + 1].start))
                }
            }
            return wins
        }
        var restWindows = computeWindows(services)
        var totalRest = restWindows.reduce(0) { $0 + max(0, $1.end - $1.start) }

        // Number of breaks for this aircraft / facility
        let numBreaks = s.facility.numBreaks

        // Round break duration DOWN to nearest 5; leftover added to Service 1
        var breakDur = 0
        var leftover = 0
        var svc1Extension = 0
        if totalRest > 0 && numBreaks > 0 {
            breakDur = (totalRest / numBreaks / 5) * 5
            leftover = totalRest - breakDur * numBreaks
            if leftover > 0 {
                svc1Extension = leftover
                services[0] = .init(label: services[0].label,
                                    start: services[0].start,
                                    end: services[0].end + leftover)
                restWindows = computeWindows(services)
                totalRest = restWindows.reduce(0) { $0 + max(0, $1.end - $1.start) }
            }
        }

        // Place breaks back-to-back, all equal duration
        var breaks: [TimedBlock] = []
        if breakDur > 0 {
            if s.facility == .mdCrc && N == 3 && numBreaks == 3 && restWindows.count == 2 {
                // MD-CRC + 3 services: user picks the sequence
                let breaksInWindow0: Int
                switch s.mdCrcSequence {
                case .srsrrs: breaksInWindow0 = 1   // S R S RR S
                case .srrsrs: breaksInWindow0 = 2   // S RR S R S
                }
                let breaksInWindow1 = numBreaks - breaksInWindow0
                var cursor = restWindows[0].start
                for i in 0..<breaksInWindow0 {
                    breaks.append(.init(label: ordinalBreak(i + 1), start: cursor, end: cursor + breakDur))
                    cursor += breakDur
                }
                cursor = restWindows[1].start
                for i in 0..<breaksInWindow1 {
                    let idx = breaksInWindow0 + i
                    breaks.append(.init(label: ordinalBreak(idx + 1), start: cursor, end: cursor + breakDur))
                    cursor += breakDur
                }
            } else {
                var widx = 0
                var cursor = restWindows[0].start
                for i in 0..<numBreaks {
                    while widx < restWindows.count - 1 && cursor + breakDur > restWindows[widx].end {
                        widx += 1
                        cursor = restWindows[widx].start
                    }
                    breaks.append(.init(label: ordinalBreak(i + 1), start: cursor, end: cursor + breakDur))
                    cursor += breakDur
                }
            }
        }

        // Apply break start override — shift all breaks so the 1st starts at the user's chosen time
        if s.breakStartOverride && !breaks.isEmpty {
            let delta = s.breakStartMin - breaks[0].start
            breaks = breaks.map { .init(label: $0.label, start: $0.start + delta, end: $0.end + delta) }
        }

        // First Class crew schedule
        var fc: FCResult? = nil
        let fcApplies = s.hasFC && isLong && numBreaks == 2 && totalRest > 0

        if fcApplies {
            let fcStart = T0 + s.fcStartAfterTO
            let latestEnd = LAND - s.fcEndBuffer
            let window = latestEnd - fcStart
            var fcBreaks: [TimedBlock] = []
            var overlap = 0
            var dropped = 0

            func placeBreaks(_ n: Int, _ ovl: Int) -> [TimedBlock] {
                var out: [TimedBlock] = []
                for i in 0..<n {
                    let off = i < 2 ? i * breakDur : i * breakDur - ovl
                    out.append(.init(label: ordinalBreak(i + 1),
                                     start: fcStart + off,
                                     end:   fcStart + off + breakDur))
                }
                return out
            }

            // HARD RULE: last break end <= latestEnd. Never crossed.
            if breakDur > 0 && window > 0 {
                if s.fcAllowOverlap {
                    let need3 = 3 * breakDur
                    if need3 <= window {
                        fcBreaks = placeBreaks(3, 0)
                    } else {
                        let needOvl = need3 - window
                        let ovl = ((needOvl + 4) / 5) * 5     // ceil to 5
                        if ovl <= 30 && ovl < breakDur {
                            fcBreaks = placeBreaks(3, ovl)
                            overlap = ovl
                        } else {
                            // Drop a break
                            if 2 * breakDur <= window {
                                fcBreaks = placeBreaks(2, 0)
                                dropped = 1
                            } else if breakDur <= window {
                                fcBreaks = placeBreaks(1, 0)
                                dropped = 2
                            } else {
                                dropped = 3
                            }
                        }
                    }
                } else {
                    let fits = min(3, window / max(1, breakDur))
                    fcBreaks = placeBreaks(fits, 0)
                    dropped = 3 - fits
                }
            } else {
                dropped = 3
            }

            fc = FCResult(
                breaks: fcBreaks, overlap: overlap, dropped: dropped,
                breakDur: breakDur, allowOverlap: s.fcAllowOverlap,
                fcStart: fcStart, windowEnd: latestEnd,
                startAfterTO: s.fcStartAfterTO, endBuffer: s.fcEndBuffer
            )
        }

        return CalculationResult(
            T0: T0, LAND: LAND, TWENTY: TWENTY, TOD: TOD,
            isLong: isLong,
            settlingStart: settlingStart, settlingEnd: settlingEnd,
            services: services,
            breaks: breaks,
            numBreaks: numBreaks,
            totalRest: totalRest,
            flightMin: F,
            svc1Extension: svc1Extension,
            fc: fc, fcApplies: fcApplies,
            registration: s.registration,
            aircraft: s.aircraft,
            facility: s.facility,
            matchedFleet: s.matchedFleet
        )
    }

    private static func ordinalBreak(_ n: Int) -> String {
        let suffix: String
        switch n {
        case 1: suffix = "st"
        case 2: suffix = "nd"
        case 3: suffix = "rd"
        default: suffix = "th"
        }
        return "\(n)\(suffix) Break"
    }
}
