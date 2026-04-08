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
            existing.updateAllocations(from: trip)
            existing.registration = trip.registration
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
