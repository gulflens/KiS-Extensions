import Foundation
import SwiftData
import SwiftUI
import CoreGraphics

#if canImport(UIKit)
import UIKit
#endif

// MARK: - PolaroidEvidenceStore

@Observable
@MainActor
final class PolaroidEvidenceStore {

    // MARK: Sort order

    enum SortOrder: Sendable {
        case byCategory
        case newestFirst
        case oldestFirst
        case byName
    }

    // MARK: Public state

    var polaroids: [PolaroidEvidence] = []
    var stacks: [PolaroidStack] = []
    var sortOrder: SortOrder = .newestFirst {
        didSet { applySort() }
    }

    // MARK: Dependencies

    private let context: ModelContext
    private let resolver = StackResolver()
    private let sector: PlannedSector?

    // MARK: Init

    init(context: ModelContext, sector: PlannedSector? = nil) {
        self.context = context
        self.sector = sector
    }

    var isSectorScoped: Bool { sector != nil }

    // MARK: Loading

    func loadAll() {
        let pDesc = FetchDescriptor<PolaroidEvidence>()
        let allPolaroids = (try? context.fetch(pDesc)) ?? []

        if let sector {
            polaroids = allPolaroids.filter { $0.sector?.id == sector.id }
            stacks = []
        } else {
            polaroids = allPolaroids.filter { $0.sector == nil }
            let sDesc = FetchDescriptor<PolaroidStack>()
            stacks = (try? context.fetch(sDesc)) ?? []
        }
        applySort()
    }

    // MARK: Mutations

    func add(metadata: PolaroidMetadata, imageData: Data, canvasPosition: CGPoint) {
        let polaroid = PolaroidEvidence(
            metadata: metadata,
            imageData: imageData,
            canvasPosition: canvasPosition
        )
        polaroid.sector = sector
        context.insert(polaroid)
        finaliseMutation()
    }

    /// Inserts a polaroid at the viewport center plus a small random offset so
    /// consecutive captures don't perfectly overlap. Returns the new ID so the
    /// caller can trigger a "land" animation against the freshly created node.
    @discardableResult
    func captureNewPolaroid(
        metadata: PolaroidMetadata,
        imageData: Data,
        viewportCenter: CGPoint
    ) -> UUID {
        let position = CGPoint(
            x: viewportCenter.x + .random(in: -100...100),
            y: viewportCenter.y + .random(in: -100...100)
        )
        let polaroid = PolaroidEvidence(
            metadata: metadata,
            imageData: imageData,
            canvasPosition: position
        )
        polaroid.sector = sector
        context.insert(polaroid)
        finaliseMutation()
        return polaroid.id
    }

    /// Updates only the metadata fields the edit form exposes. Photo, position,
    /// rotation, and stack membership are untouched.
    func updateMetadata(_ polaroid: PolaroidEvidence, metadata: PolaroidMetadata) {
        polaroid.caption = metadata.caption
        polaroid.category = metadata.category
        polaroid.flightNumber = metadata.flightNumber
        polaroid.route = metadata.route
        polaroid.seatLocation = metadata.seatLocation
        polaroid.aspectMode = metadata.aspectMode
        finaliseMutation()
    }

    func delete(_ polaroid: PolaroidEvidence) {
        context.delete(polaroid)
        finaliseMutation()
    }

    /// Deletes multiple polaroids and/or stacks in a single mutation pass so
    /// the resolver only runs once for the whole batch. Stacks cascade to
    /// their member polaroids via the SwiftData delete rule.
    func bulkDelete(polaroids: [PolaroidEvidence] = [], stacks: [PolaroidStack] = []) {
        for polaroid in polaroids {
            context.delete(polaroid)
        }
        for stack in stacks {
            context.delete(stack)
        }
        finaliseMutation()
    }

    /// Deep-copies metadata + imageData into a new polaroid placed at a
    /// small canvas offset from the source. Preserves the original
    /// `capturedAt` so the duplicate still records when the photo was taken.
    @discardableResult
    func duplicate(
        _ polaroid: PolaroidEvidence,
        offsetBy offset: CGVector = CGVector(dx: 30, dy: -30)
    ) -> UUID {
        let metadata = PolaroidMetadata(
            caption: polaroid.caption,
            category: polaroid.category,
            flightNumber: polaroid.flightNumber,
            route: polaroid.route,
            seatLocation: polaroid.seatLocation,
            capturedAt: polaroid.capturedAt,
            aspectMode: polaroid.aspectMode
        )
        let position = CGPoint(
            x: polaroid.canvasX + offset.dx,
            y: polaroid.canvasY + offset.dy
        )
        let copy = PolaroidEvidence(
            metadata: metadata,
            imageData: polaroid.imageData,
            canvasPosition: position
        )
        context.insert(copy)
        finaliseMutation()
        return copy.id
    }

    /// Bulk variant — single mutation pass, single resolver run.
    @discardableResult
    func bulkDuplicate(
        _ polaroids: [PolaroidEvidence],
        offsetBy offset: CGVector = CGVector(dx: 30, dy: -30)
    ) -> [UUID] {
        var newIDs: [UUID] = []
        for polaroid in polaroids {
            let metadata = PolaroidMetadata(
                caption: polaroid.caption,
                category: polaroid.category,
                flightNumber: polaroid.flightNumber,
                route: polaroid.route,
                seatLocation: polaroid.seatLocation,
                capturedAt: polaroid.capturedAt,
                aspectMode: polaroid.aspectMode
            )
            let position = CGPoint(
                x: polaroid.canvasX + offset.dx,
                y: polaroid.canvasY + offset.dy
            )
            let copy = PolaroidEvidence(
                metadata: metadata,
                imageData: polaroid.imageData,
                canvasPosition: position
            )
            context.insert(copy)
            newIDs.append(copy.id)
        }
        finaliseMutation()
        return newIDs
    }




    // MARK: Internal helpers

    private func finaliseMutation(skipResolver: Bool = false) {
        try? context.save()
        if !skipResolver && !isSectorScoped {
            try? resolver.resolveAutoStacks(in: context)
            try? context.save()
        }
        loadAll()
    }

    private func applySort() {
        switch sortOrder {
        case .newestFirst:
            polaroids.sort { $0.capturedAt > $1.capturedAt }
        case .oldestFirst:
            polaroids.sort { $0.capturedAt < $1.capturedAt }
        case .byCategory:
            polaroids.sort {
                if $0.categoryRaw == $1.categoryRaw {
                    return $0.capturedAt > $1.capturedAt
                }
                return $0.categoryRaw < $1.categoryRaw
            }
        case .byName:
            polaroids.sort {
                let lhs = $0.caption.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                let rhs = $1.caption.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                if lhs == rhs { return $0.capturedAt > $1.capturedAt }
                return lhs < rhs
            }
        }
    }


    // MARK: Debug seed

    #if DEBUG
    /// Inserts a fixed test scenario covering the cases described in
    /// STAGE1_TESTS.md: a 3-polaroid cabin-defect cluster (auto-stack
    /// expected), an isolated food-issue polaroid, and an isolated
    /// seat-defect polaroid.
    func seedTestData() {
        let placeholder = Self.placeholderImageData()

        let seeds: [(EvidenceCategory, CGPoint, String)] = [
            (.cabinDefect, CGPoint(x:    0, y:    0), "Torn seat pocket 1A"),
            (.cabinDefect, CGPoint(x:  220, y:   90), "Lavatory door hinge"),
            (.cabinDefect, CGPoint(x:   80, y:  240), "Galley curtain rail"),
            (.foodIssue,   CGPoint(x: 2000, y: 2000), "Cold meal tray"),
            (.seatDefect,  CGPoint(x:-1500, y:  800), "Recline broken 12C"),
        ]

        for (category, position, caption) in seeds {
            let metadata = PolaroidMetadata(
                caption: caption,
                category: category,
                flightNumber: "EK001",
                route: "DXB-LHR",
                seatLocation: nil,
                capturedAt: Date(),
                aspectMode: .square
            )
            let polaroid = PolaroidEvidence(
                metadata: metadata,
                imageData: placeholder,
                canvasPosition: position
            )
            context.insert(polaroid)
        }

        finaliseMutation()
    }

    private static func placeholderImageData() -> Data {
        #if canImport(UIKit)
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1))
        let image = renderer.image { ctx in
            UIColor.gray.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
        return image.pngData() ?? Data()
        #else
        return Data()
        #endif
    }
    #endif
}
