import Foundation
import FoundationModels

/// The classified full category path for a KiS report.
struct ClassifiedPath: Sendable {
    let cat1: String
    let cat2: String?
    let cat3: String?
    let cat4: String?

    /// Human-readable path string, e.g. "Catering > Food > Business Class > Foreign Object"
    var displayPath: String {
        [cat1, cat2, cat3, cat4].compactMap { $0 }.joined(separator: " > ")
    }
}

@Observable
class KiSAgent {

    // MARK: - Availability

    var availability: SystemLanguageModel.Availability {
        SystemLanguageModel.default.availability
    }

    // MARK: - Prewarm

    /// Prewarms the on-device model so the first real call is faster.
    func prewarm() async {
        let session = LanguageModelSession()
        _ = try? await session.respond(to: "ping")
    }

    // MARK: - Single-level classifiers

    /// Classifies into a Cat1 top-level category.
    func classifyCat1(bullets: String) async throws -> CategoryPick {
        let schema = try Self.categoryPickSchema(
            description: "Pick the top-level KiS category (Cat1)",
            choices: KiSCategory1.allRawValues
        )
        return try await classify(bullets: bullets, schema: schema)
    }

    /// Classifies into a Cat2 sub-category under the given Cat1.
    func classifyCat2(bullets: String, cat1: KiSCategory1) async throws -> CategoryPick? {
        let choices = CategoryTree.cat2List(under: cat1)
        guard !choices.isEmpty else { return nil }
        let schema = try Self.categoryPickSchema(
            description: "Pick the Cat2 sub-category under \(cat1.rawValue)",
            choices: choices
        )
        return try await classify(bullets: bullets, schema: schema)
    }

    /// Classifies into a Cat3 sub-category under the given Cat1 > Cat2.
    func classifyCat3(bullets: String, cat1: KiSCategory1, cat2: String) async throws -> CategoryPick? {
        let choices = CategoryTree.cat3List(under: cat1, cat2: cat2)
        guard !choices.isEmpty else { return nil }
        let schema = try Self.categoryPickSchema(
            description: "Pick the Cat3 sub-category under \(cat1.rawValue) > \(cat2)",
            choices: choices
        )
        return try await classify(bullets: bullets, schema: schema)
    }

    /// Classifies into a Cat4 sub-category under the given Cat1 > Cat2 > Cat3.
    func classifyCat4(bullets: String, cat1: KiSCategory1, cat2: String, cat3: String) async throws -> CategoryPick? {
        let choices = CategoryTree.cat4List(under: cat1, cat2: cat2, cat3: cat3)
        guard !choices.isEmpty else { return nil }
        let schema = try Self.categoryPickSchema(
            description: "Pick the Cat4 sub-category under \(cat1.rawValue) > \(cat2) > \(cat3)",
            choices: choices
        )
        return try await classify(bullets: bullets, schema: schema)
    }

    // MARK: - Full classification

    /// Walks the entire category tree (Cat1 → Cat2 → Cat3 → Cat4) and returns the deepest path.
    func fullyClassify(bullets: String) async throws -> ClassifiedPath {
        let pick1 = try await classifyCat1(bullets: bullets)
        guard let cat1 = KiSCategory1(rawValue: pick1.category) else {
            return ClassifiedPath(cat1: pick1.category, cat2: nil, cat3: nil, cat4: nil)
        }

        guard let pick2 = try await classifyCat2(bullets: bullets, cat1: cat1) else {
            return ClassifiedPath(cat1: cat1.rawValue, cat2: nil, cat3: nil, cat4: nil)
        }

        guard let pick3 = try await classifyCat3(bullets: bullets, cat1: cat1, cat2: pick2.category) else {
            return ClassifiedPath(cat1: cat1.rawValue, cat2: pick2.category, cat3: nil, cat4: nil)
        }

        guard let pick4 = try await classifyCat4(bullets: bullets, cat1: cat1, cat2: pick2.category, cat3: pick3.category) else {
            return ClassifiedPath(cat1: cat1.rawValue, cat2: pick2.category, cat3: pick3.category, cat4: nil)
        }

        return ClassifiedPath(
            cat1: cat1.rawValue,
            cat2: pick2.category,
            cat3: pick3.category,
            cat4: pick4.category
        )
    }

    // MARK: - Report writing

    /// Generates a complete KiS draft report from bullet notes and classified path.
    func writeReport(bullets: String, path: ClassifiedPath) async throws -> KiSDraft {
        let session = LanguageModelSession(instructions: KiSPrompts.activeWriterInstructions)
        let prompt = """
        Category: \(path.displayPath)

        Crew notes:
        \(bullets)
        """
        let response = try await session.respond(to: prompt, generating: KiSDraft.self)
        return response.content
    }

    /// Streams a KiS draft report, yielding partial results as they become available.
    func streamReport(
        bullets: String,
        path: ClassifiedPath
    ) -> LanguageModelSession.ResponseStream<KiSDraft> {
        let session = LanguageModelSession(instructions: KiSPrompts.activeWriterInstructions)
        let prompt = """
        Category: \(path.displayPath)

        Crew notes:
        \(bullets)
        """
        return session.streamResponse(to: prompt, generating: KiSDraft.self)
    }

    // MARK: - Private helpers

    /// Builds a dynamic GenerationSchema that constrains `category` to the given choices.
    private static func categoryPickSchema(
        description: String,
        choices: [String]
    ) throws -> GenerationSchema {
        let root = DynamicGenerationSchema(
            name: "CategoryPick",
            description: description,
            properties: [
                DynamicGenerationSchema.Property(
                    name: "category",
                    description: "The selected category from the allowed choices",
                    schema: DynamicGenerationSchema(
                        name: "category",
                        anyOf: choices
                    )
                ),
                DynamicGenerationSchema.Property(
                    name: "confidence",
                    description: "Confidence score from 0.0 to 1.0",
                    schema: DynamicGenerationSchema(
                        type: Double.self
                    )
                )
            ]
        )
        return try GenerationSchema(root: root, dependencies: [])
    }

    /// Runs a single classification call against the on-device model.
    private func classify(bullets: String, schema: GenerationSchema) async throws -> CategoryPick {
        let session = LanguageModelSession(instructions: KiSPrompts.activeClassifierInstructions)
        let response = try await session.respond(to: bullets, schema: schema)
        let category: String = try response.content.value(forProperty: "category")
        let confidence: Double = try response.content.value(forProperty: "confidence")
        return CategoryPick(category: category, confidence: confidence)
    }
}
