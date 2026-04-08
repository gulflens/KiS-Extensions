import Foundation

/// A predefined incident template that seeds the composer with category path,
/// flight phase, and placeholder bullet prompts. Static library data — not persisted.
struct IncidentTemplate: Identifiable, Hashable {
    let id: String
    let displayName: String
    let iconName: String  // SF Symbol
    let suggestedCat1: KiSCategory1
    let suggestedCat2: String?
    let suggestedCat3: String?
    let suggestedCat4: String?
    let defaultPhase: FlightPhase
    let bulletPlaceholders: [String]  // placeholder hints, not content
    let suggestedPriority: String  // "Critical" / "Follow up required" / "Info only"
    let priorityReasoning: String

    /// The category path as a display string, e.g. "Catering > Food > Economy Class".
    var categoryDisplayPath: String {
        [suggestedCat1.rawValue, suggestedCat2, suggestedCat3, suggestedCat4]
            .compactMap { $0 }
            .joined(separator: " > ")
    }
}
