import Foundation
import SwiftData

// MARK: - KiS Report Record

/// A single persisted KiS report draft. Flat schema for migration ease.
@Model
final class KiSReportRecord {

    // MARK: - Identity

    @Attribute(.unique) var id: UUID

    // MARK: - Timestamps

    var createdAt: Date
    var updatedAt: Date

    // MARK: - Bullet input

    var rawBullets: String

    // MARK: - Classification

    var classificationPath: String?
    var classificationCat1Raw: String?
    var classificationCat2: String?
    var classificationCat3: String?
    var classificationCat4: String?

    // MARK: - Report

    var reportJSON: Data?
    var isComplete: Bool

    // MARK: - User notes

    var notes: String

    // MARK: - Init

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        updatedAt: Date = .now,
        rawBullets: String = "",
        classificationPath: String? = nil,
        classificationCat1Raw: String? = nil,
        classificationCat2: String? = nil,
        classificationCat3: String? = nil,
        classificationCat4: String? = nil,
        reportJSON: Data? = nil,
        isComplete: Bool = false,
        notes: String = ""
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.rawBullets = rawBullets
        self.classificationPath = classificationPath
        self.classificationCat1Raw = classificationCat1Raw
        self.classificationCat2 = classificationCat2
        self.classificationCat3 = classificationCat3
        self.classificationCat4 = classificationCat4
        self.reportJSON = reportJSON
        self.isComplete = isComplete
        self.notes = notes
    }

    // MARK: - Computed properties

    /// Display title based on classification or creation date.
    var displayTitle: String {
        if let path = classificationPath, !path.isEmpty {
            return path
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        return "Draft – \(formatter.string(from: createdAt))"
    }

    /// First 60 characters of rawBullets for list preview.
    var summary: String {
        if rawBullets.isEmpty { return "" }
        let trimmed = rawBullets.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count <= 60 { return trimmed }
        return String(trimmed.prefix(60)) + "…"
    }

    /// Lazily decodes reportJSON into a KiSDraft.
    var decodedDraft: KiSDraft? {
        guard let data = reportJSON else { return nil }
        return try? JSONDecoder().decode(KiSDraft.self, from: data)
    }

    // MARK: - Helper methods

    /// Encodes a KiSDraft to reportJSON and marks the record complete.
    func setDraft(_ draft: KiSDraft) {
        reportJSON = try? JSONEncoder().encode(draft)
        isComplete = true
        updatedAt = .now
    }

    /// Syncs this record from a ComposerModel snapshot.
    func update(from model: ComposerModel) {
        rawBullets = model.committedBullets.isEmpty ? model.rawBullets : model.committedBullets

        if let path = model.classifiedPath {
            classificationPath = path.displayPath
            classificationCat1Raw = path.cat1
            classificationCat2 = path.cat2
            classificationCat3 = path.cat3
            classificationCat4 = path.cat4
        } else {
            classificationPath = nil
            classificationCat1Raw = nil
            classificationCat2 = nil
            classificationCat3 = nil
            classificationCat4 = nil
        }

        if let draft = model.finalDraft {
            setDraft(draft)
        }

        updatedAt = .now
    }
}
