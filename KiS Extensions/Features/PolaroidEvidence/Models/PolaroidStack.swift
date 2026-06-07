import Foundation
import SwiftData
import CoreGraphics

// MARK: - PolaroidStack

@Model
final class PolaroidStack {

    // MARK: Stored

    var id: UUID = UUID()
    var kindRaw: String = Kind.autoCategory.rawValue
    var label: String?
    var categoryRaw: String?
    var canvasX: Double = 0
    var canvasY: Double = 0
    var createdAt: Date = Date()
    var libraryOrder: Int = 0

    // Stored optional for CloudKit; accessed through `polaroids` below.
    @Relationship(deleteRule: .cascade, inverse: \PolaroidEvidence.stack)
    private var polaroidsStore: [PolaroidEvidence]?

    var polaroids: [PolaroidEvidence] {
        get { polaroidsStore ?? [] }
        set { polaroidsStore = newValue }
    }

    // MARK: Kind

    enum Kind: String, Sendable {
        case autoCategory
    }

    // MARK: Init

    init(
        kind: Kind,
        category: EvidenceCategory? = nil,
        position: CGPoint = .zero,
        label: String? = nil
    ) {
        self.id = UUID()
        self.kindRaw = kind.rawValue
        self.label = label
        self.categoryRaw = category?.rawValue
        self.canvasX = Double(position.x)
        self.canvasY = Double(position.y)
        self.createdAt = Date()
    }

    // MARK: Computed

    var kind: Kind {
        get { Kind(rawValue: kindRaw) ?? .autoCategory }
        set { kindRaw = newValue.rawValue }
    }

    var category: EvidenceCategory? {
        get { categoryRaw.flatMap { EvidenceCategory(rawValue: $0) } }
        set { categoryRaw = newValue?.rawValue }
    }
}
