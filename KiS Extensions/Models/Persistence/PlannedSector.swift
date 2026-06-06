import Foundation
import SwiftData

// MARK: - Planned Sector

/// A single sector (leg) within a PlannedFlight trip.
/// Times are stored as "HH:mm" strings representing local station time.
@Model
final class PlannedSector {
    var id: UUID = UUID()
    var sectorIndex: Int = 0
    var flightNumber: String = ""
    var date: Date = Date()
    var departureStation: String = ""
    var arrivalStation: String = ""
    var departureTime: String = "" // "HH:mm" local time
    var arrivalTime: String = ""   // "HH:mm" local time
    var registration: String? // e.g. "A6EWJ"
    var actualLandingTime: String? // "HH:mm" arrival station local — calculated landing time from detail view

    // MARK: - Persisted adjustable times (HH:mm strings, nil = use default)

    var savedPushBack: String?
    var savedTakeOffTime: String?
    var savedFlightTime: String?
    var savedNumberOfServices: Int?
    var savedService1JC: Int?
    var savedService1YC: Int?
    var savedService2JC: Int?
    var savedService2YC: Int?
    var savedService3JC: Int?
    var savedService3YC: Int?
    var savedService1WC: Int?
    var savedService2WC: Int?
    var savedService3WC: Int?

    // MARK: - Persisted actual times (HH:mm strings, nil = not yet set)

    var savedActualArriveAircraft: String?
    var savedActualCabinAppearance: String?
    var savedActualSafetyChecks: String?
    var savedActualAutoBoarding: String?
    var savedActualOffloadNoShow: String?
    var savedActualClosingDoor: String?
    var savedActualArmingDoor: String?

    // MARK: - Persisted Crew Rest inputs

    var savedCrewRestRegistration: String?
    var savedCrewRestAircraft: String?
    var savedCrewRestFacility: String?
    var savedCrewRestHasFC: Bool?
    var savedCrewRestSettlingMin: Int?

    // MARK: - Layover flag

    var savedIsLayover: Bool?

    // MARK: - Per-Sector Crew Positions

    var crewPositionsJSON: Data?

    // MARK: - Positions Annotation (PencilKit drawing)

    var positionsAnnotationData: Data?

    // MARK: - Text Annotations

    var textAnnotationsData: Data?

    // MARK: - Flight Crew Checklist (sector-scoped persistence)

    var flightCrewChecklistJSON: Data?

    @Relationship(deleteRule: .cascade, inverse: \PolaroidEvidence.sector)
    var evidencePhotos: [PolaroidEvidence] = []

    var parentTrip: PlannedFlight?

    init(
        id: UUID = UUID(),
        sectorIndex: Int,
        flightNumber: String,
        date: Date,
        departureStation: String,
        arrivalStation: String,
        departureTime: String,
        arrivalTime: String
    ) {
        self.id = id
        self.sectorIndex = sectorIndex
        self.flightNumber = flightNumber
        self.date = date
        self.departureStation = departureStation
        self.arrivalStation = arrivalStation
        self.departureTime = departureTime
        self.arrivalTime = arrivalTime
    }
}
