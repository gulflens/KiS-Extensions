import Foundation

// MARK: - Fleet Loader

enum FleetLoader {
    static let shared = Loader()

    final class Loader {
        let entries: [String: FleetEntry]
        let version: String

        fileprivate init() {
            guard let url = Bundle.main.url(forResource: "ek_fleet_v110", withExtension: "json") else {
                fatalError("ek_fleet_v110.json missing from bundle")
            }
            do {
                let data = try Data(contentsOf: url)
                let payload = try JSONDecoder().decode(RawPayload.self, from: data)
                self.entries = payload.aircraft
                self.version = payload.version
            } catch {
                fatalError("Decode ek_fleet_v110.json: \(error)")
            }
        }

        func entry(forSuffix raw: String) -> FleetEntry? {
            let cleaned = raw
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .uppercased()
                .filter { $0.isLetter }
            guard cleaned.count == 3 else { return nil }
            return entries["A6-\(cleaned)"]
        }

        /// Suffix-prefix matches for autocomplete dropdown.
        func matches(prefix raw: String, limit: Int = 8) -> [(reg: String, entry: FleetEntry)] {
            let p = raw.uppercased().filter { $0.isLetter }
            guard !p.isEmpty, p.count < 3 else { return [] }
            let fullPrefix = "A6-\(p)"
            return entries
                .filter { $0.key.hasPrefix(fullPrefix) }
                .sorted { $0.key < $1.key }
                .prefix(limit)
                .map { (String($0.key.dropFirst(3)), $0.value) }
        }
    }

    private struct RawPayload: Decodable {
        let version: String
        let aircraft: [String: FleetEntry]
    }
}

// MARK: - Time Formatter

enum TimeFormatter {

    /// "14:30" — minutes since midnight as HH:MM.
    static func clock(_ min: Int) -> String {
        let h = (min / 60) % 24
        let m = ((min % 60) + 60) % 60
        return String(format: "%02d:%02d", h, m)
    }

    /// "1h 30m" / "45m" — duration in minutes (matches demo's fmtDur).
    static func dur(_ min: Int) -> String {
        let h = min / 60
        let m = min % 60
        if h == 0 { return "\(m)m" }
        if m == 0 { return "\(h)h" }
        return "\(h)h \(m)m"
    }

    /// Matches demo's fmtSlider — same shape.
    static func slider(_ min: Int) -> String { dur(min) }
}
