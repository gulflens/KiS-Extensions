import Foundation

/// Calculates the minimum required crew number for a flight.
/// Port of required_crew_number.js
struct RequiredCrewCalculator {
    static func calculate(crewData: [CrewMember], registration: String, isULR: Bool) -> Int {
        guard let result = OperationTypeResolver.loadPositions(
            crewData: crewData,
            registration: registration,
            isULR: isULR,
            forTripsTableOnly: true
        ) else {
            return 0
        }

        var count = 0
        for (key, gradePositions) in result.positions where key != "EXTRA" {
            count += gradePositions.allPositions.count
        }
        return count
    }
}
