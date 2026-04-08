import Foundation

/// Builds language queues for PA (Personal Attendant) assignment.
/// Port of languages.js createLanguageQueues()
struct LanguageQueueBuilder {
    /// Builds a dictionary mapping language name to a queue of staff numbers who speak it.
    /// Always includes Arabic; includes third-party languages if set.
    static func build(from crew: [CrewMember], thirdLanguages: [String] = []) -> [String: [String]] {
        let allLanguages = thirdLanguages.isEmpty ? ["Arabic"] : thirdLanguages + ["Arabic"]
        var queues: [String: [String]] = [:]

        for language in allLanguages {
            queues[language] = crew
                .filter { $0.languages.contains(language) }
                .map { $0.staffNumber }
        }

        return queues
    }
}
