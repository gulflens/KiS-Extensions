import Foundation
import FoundationModels

// MARK: - Flight Phase

@Generable(description: "The phase of flight during which the event occurred")
enum FlightPhase: String, CaseIterable, Codable {
    case boarding
    case taxi
    case takeoff
    case climb
    case cruise
    case service
    case topOfDescent
    case landing
    case disembarkation
    case layover
}

// MARK: - Action Section

@Generable(description: "Describes the actions taken in response to a KiS event, including findings, customer management steps, service recovery, follow-up items, and optional root cause analysis")
struct ActionSection: Codable {
    @Guide(description: "Factual bullet points describing what was observed or discovered during the event. Use crew's own words in double quotes where available. Each finding should be a single clear statement.")
    var findings: [String]

    @Guide(description: "Steps taken to manage the customer during the event. Describe what was communicated, how the customer was reassured or accommodated, and any immediate actions taken on their behalf.")
    var customerManagement: String

    @Guide(description: "Service recovery actions performed after the initial response. Includes compensation offered, alternative arrangements made, or goodwill gestures provided to restore customer satisfaction.")
    var serviceRecovery: String

    @Guide(description: "Outstanding items that require action after the flight. Includes referrals to ground staff, reports to be filed, items to be replenished, or notifications to be sent.")
    var followUp: String

    @Guide(description: "The underlying cause of the event if it can be determined. State the root cause factually. Omit if the cause is unknown or speculative.")
    var rootCause: String?
}

// MARK: - Priority Suggestion

@Generable(description: "The suggested priority level for the KiS report, indicating how urgently it should be reviewed by management")
struct PrioritySuggestion: Codable {
    @Guide(
        description: "The priority level for the report. Critical means safety, security, or regulatory issues requiring immediate management attention. Follow up required means service failures or operational issues that need action within 48 hours. Info only means routine observations logged for record-keeping.",
        .anyOf(["Critical", "Follow up required", "Info only"])
    )
    var level: String

    @Guide(description: "A one-to-two sentence explanation of why this priority level was selected, referencing the specific facts of the event")
    var reasoning: String

    @Guide(description: "Whether the report contains sensitive information such as crew names involved in disciplinary matters, passenger medical details, or security incidents that should be restricted to management view only")
    var confidential: Bool
}

// MARK: - Category Pick

@Generable(description: "A single category selection with a confidence score indicating how well the category matches the described event")
struct CategoryPick {
    @Guide(description: "The selected category from the allowed choices. Must be exactly one of the provided options.")
    var category: String

    @Guide(description: "Confidence score from 0.0 to 1.0 indicating how well the category matches. Use 0.9+ only when the match is unambiguous.")
    var confidence: Double
}

// MARK: - KiS Draft

@Generable(description: "A complete draft KiS report ready for crew review before submission. Contains the structured description, phase, location, actions taken, and priority assessment.")
struct KiSDraft: Codable {
    @Guide(description: "Bullet points describing the event in factual, third-person language suitable for the KiS report description field. Each bullet should be a single clear statement. Use crew's own words in double quotes where they add clarity.")
    var descriptionBullets: [String]

    @Guide(description: "The flight phase during which the event occurred")
    var phase: FlightPhase

    @Guide(description: "The physical location on the aircraft where the event occurred, e.g. galley 4R, seat 32A, door 2L, upper deck bar, crew rest area")
    var location: String

    @Guide(description: "The actions taken in response to the event")
    var actionTaken: ActionSection

    @Guide(description: "The suggested priority level and confidentiality for this report")
    var priority: PrioritySuggestion
}
