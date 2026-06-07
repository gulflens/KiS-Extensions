import Foundation
import SwiftData

// MARK: - Trip Type

enum TripType: String, Codable, CaseIterable {
    case turnaround = "Turnaround"
    case layover = "Layover"
    case transit = "Transit"
    case special = "Special"
}

// MARK: - Planned Flight

/// SwiftData model owned exclusively by the Flight Planner mini-app.
/// Not related to `SavedTrip`; the two mini-apps do not share persistence.
@Model
final class PlannedFlight {
    var id: UUID = UUID()
    var tripNumber: String = ""
    var tripTypeRaw: String = TripType.turnaround.rawValue
    var flightNumber: String = ""
    var flightDate: Date = Date()
    var departure: String = ""
    var arrival: String = ""
    var notes: String = ""
    var createdAt: Date = Date()

    var tripType: TripType {
        get {
            if tripTypeRaw == "Multi-Sector" { return .transit }
            return TripType(rawValue: tripTypeRaw) ?? .turnaround
        }
        set { tripTypeRaw = newValue.rawValue }
    }

    // Stored optional for CloudKit (relationships must be optional). Read and
    // written through the non-optional `sectors` accessor below.
    @Relationship(deleteRule: .cascade, inverse: \PlannedSector.parentTrip)
    private var sectorsStore: [PlannedSector]?

    var sectors: [PlannedSector] {
        get { sectorsStore ?? [] }
        set { sectorsStore = newValue }
    }

    /// Sorted sectors by index for display
    var sortedSectors: [PlannedSector] {
        sectors.sorted { $0.sectorIndex < $1.sectorIndex }
    }

    /// Route string derived from sectors (e.g. "DXB - LHR - DXB")
    var routeString: String {
        let sorted = sortedSectors
        guard let first = sorted.first else { return "\(departure) - \(arrival)" }
        var stations = [first.departureStation]
        for sector in sorted {
            stations.append(sector.arrivalStation)
        }
        return stations.joined(separator: " - ")
    }

    init(
        id: UUID = UUID(),
        tripNumber: String = "",
        tripType: TripType = .turnaround,
        flightNumber: String,
        flightDate: Date,
        departure: String,
        arrival: String,
        notes: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.tripNumber = tripNumber
        self.tripTypeRaw = tripType.rawValue
        self.flightNumber = flightNumber
        self.flightDate = flightDate
        self.departure = departure
        self.arrival = arrival
        self.notes = notes
        self.createdAt = createdAt
    }
}
