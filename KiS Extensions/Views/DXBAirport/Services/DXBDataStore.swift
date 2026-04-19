import Foundation
import Observation

// MARK: - DXB Data Store

/// Loads authoritative DXB Airport reference data (bays, gates) from the app
/// bundle once at launch. Read-only — never mutated at runtime.
@Observable
final class DXBDataStore {
    let catalog: BayCatalog
    let lookupIndex: [String: Bay]
    let lounges: [Lounge]
    let routeEngine: RouteEngine
    let mapLayout: DXBSchematicLayout

    init() {
        self.catalog = Self.loadCatalog()
        self.lookupIndex = catalog.buildLookupIndex()
        self.lounges = Self.loadLounges()
        self.routeEngine = RouteEngine()
        self.mapLayout = DXBSchematicLayout(catalog: catalog, lounges: lounges)
    }

    // MARK: - Loading

    private static func loadCatalog() -> BayCatalog {
        guard let url = Bundle.main.url(forResource: "bays", withExtension: "json") else {
            fatalError("DXBDataStore: bays.json missing from bundle Resources")
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(BayCatalog.self, from: data)
        } catch {
            fatalError("DXBDataStore: failed to decode bays.json — \(error)")
        }
    }

    private struct LoungesFile: Decodable {
        let lounges: [Lounge]
    }

    private static func loadLounges() -> [Lounge] {
        guard let url = Bundle.main.url(forResource: "lounges", withExtension: "json") else {
            fatalError("DXBDataStore: lounges.json missing from bundle Resources")
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(LoungesFile.self, from: data).lounges
        } catch {
            fatalError("DXBDataStore: failed to decode lounges.json — \(error)")
        }
    }

    // MARK: - Lounges

    /// Lounges grouped by concourse in A → B → C order.
    func loungesGrouped() -> [(concourse: Concourse, lounges: [Lounge])] {
        Concourse.allCases.compactMap { concourse in
            let matching = lounges.filter { $0.concourse == concourse }
            guard !matching.isEmpty else { return nil }
            return (concourse, matching.sorted { $0.name < $1.name })
        }
    }

    // MARK: - Search

    /// Returns every bay matching the query against bayId, gateId, or
    /// oldGateId. Match is case-insensitive substring, and also tolerant of
    /// leading-zero differences in the numeric portion — typing "G1" or
    /// "A6" matches "G01" and "A06" the same as the padded form would.
    /// Empty query returns all bays.
    func search(_ query: String) -> [Bay] {
        let raw = query.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !raw.isEmpty else { return catalog.bays }
        let canonicalQuery = Self.canonicalize(raw)

        func matches(_ id: String?) -> Bool {
            guard let id else { return false }
            let upper = id.uppercased()
            // Match either the literal query OR the zero-stripped canonical
            // form, so "G1" hits "G01" without false-firing on "A0" → "A01".
            return upper.contains(raw) || Self.canonicalize(upper).contains(canonicalQuery)
        }

        return catalog.bays.filter { bay in
            matches(bay.bayId) || matches(bay.gateId) || matches(bay.oldGateId)
        }
    }

    /// Strips leading zeros within numeric runs of an identifier so that
    /// "G01" and "G1" canonicalise to the same form. Letter prefixes are
    /// preserved. Multi-segment IDs (e.g. "REMOTE_A06") are normalised
    /// per-numeric-run. A run of all zeros collapses to a single "0".
    static func canonicalize(_ s: String) -> String {
        let upper = s.uppercased()
        var result = ""
        var i = upper.startIndex
        var prevWasNonDigit = true
        while i < upper.endIndex {
            let ch = upper[i]
            if ch.isNumber && prevWasNonDigit {
                // Beginning of a digit run — drop leading zeros.
                var ate = false
                while i < upper.endIndex, upper[i] == "0" {
                    i = upper.index(after: i)
                    ate = true
                }
                // If ALL digits in this run were zeros (e.g. "00"), keep one.
                if ate, i >= upper.endIndex || !upper[i].isNumber {
                    result.append("0")
                }
                prevWasNonDigit = false
                continue
            }
            result.append(ch)
            prevWasNonDigit = !ch.isNumber
            i = upper.index(after: i)
        }
        return result
    }

    // MARK: - Grouping

    /// Bays grouped by concourse, in A → B → C order.
    func grouped(_ bays: [Bay]) -> [(concourse: Concourse, bays: [Bay])] {
        Concourse.allCases.compactMap { concourse in
            let matching = bays.filter { $0.concourse == concourse }
            guard !matching.isEmpty else { return nil }
            return (concourse, matching.sorted { $0.bayId < $1.bayId })
        }
    }
}
