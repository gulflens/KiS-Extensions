import Foundation
import SwiftData

struct TripStorageService {
    let modelContext: ModelContext

    /// Save a ParsedTrip. If a trip with the same key exists, update it instead.
    @discardableResult
    func save(_ trip: ParsedTrip) throws -> SavedTrip {
        // Check for existing trip with same key
        let key = trip.key
        var descriptor = FetchDescriptor<SavedTrip>(
            predicate: #Predicate { $0.tripKey == key }
        )
        descriptor.fetchLimit = 1

        if let existing = try modelContext.fetch(descriptor).first {
            let preservedNotes = existing.notes
            existing.flightNumber = trip.flightInfo.flightNumber
            existing.flightLegs = trip.flightInfo.flightLegs
            existing.flightDate = trip.flightInfo.flightDate
            existing.sectors = trip.flightInfo.sectors
            existing.durations = trip.flightInfo.durations
            existing.sectorsPerDuty = trip.flightInfo.sectorsPerDuty
            existing.aircraftTail = trip.flightData.aircraftTail
            existing.serviceType = trip.flightData.serviceType
            existing.registration = trip.registration
            existing.rawJSON = try? JSONEncoder().encode(trip.rawCrewData)
            existing.savedAt = Date()
            existing.notes = preservedNotes
            existing.updateAllocations(from: trip)
            try modelContext.save()
            return existing
        }

        let saved = SavedTrip(from: trip)
        modelContext.insert(saved)
        try modelContext.save()
        return saved
    }

    /// Delete a saved trip (crew allocations cascade-delete automatically)
    func delete(_ trip: SavedTrip) throws {
        modelContext.delete(trip)
        try modelContext.save()
    }

    /// Fetch all saved trips sorted by flight date (newest first)
    func fetchAll() -> [SavedTrip] {
        let descriptor = FetchDescriptor<SavedTrip>(
            sortBy: [SortDescriptor(\.flightDate, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Search saved trips by flight number, crew name, or staff number
    func fetch(matching query: String) -> [SavedTrip] {
        guard !query.isEmpty else { return fetchAll() }

        let lowered = query.lowercased()
        let all = fetchAll()

        return all.filter { trip in
            // Match flight number
            if trip.flightNumber.lowercased().contains(lowered) { return true }
            // Match route
            if trip.routeString.lowercased().contains(lowered) { return true }
            // Match crew
            if trip.crewAllocations.contains(where: {
                $0.fullname.lowercased().contains(lowered) ||
                $0.nickname.lowercased().contains(lowered) ||
                $0.staffNumber.lowercased().contains(lowered) ||
                $0.nationality.lowercased().contains(lowered)
            }) { return true }
            return false
        }
    }
}
