import Foundation
import SwiftData
import CoreGraphics

// MARK: - PolaroidEvidence

@Model
final class PolaroidEvidence {

    // MARK: Stored

    var id: UUID = UUID()
    var capturedAt: Date = Date()
    var caption: String = ""
    var categoryRaw: String = EvidenceCategory.other.rawValue
    var flightNumber: String?
    var route: String?
    var seatLocation: String?

    @Attribute(.externalStorage) var imageData: Data = Data()
    @Attribute(.externalStorage) var renderedData: Data?

    var aspectModeRaw: String = AspectMode.square.rawValue
    var canvasX: Double = 0
    var canvasY: Double = 0
    var rotation: Double = 0
    var stackOrder: Int = 0
    var libraryOrder: Int = 0

    @Relationship var stack: PolaroidStack?
    @Relationship var sector: PlannedSector?

    // MARK: Init

    init(
        metadata: PolaroidMetadata,
        imageData: Data,
        canvasPosition: CGPoint,
        rotation: Double = 0
    ) {
        self.id = UUID()
        self.capturedAt = metadata.capturedAt
        self.caption = metadata.caption
        self.categoryRaw = metadata.category.rawValue
        self.flightNumber = metadata.flightNumber
        self.route = metadata.route
        self.seatLocation = metadata.seatLocation
        self.imageData = imageData
        self.renderedData = nil
        self.aspectModeRaw = metadata.aspectMode.rawValue
        self.canvasX = Double(canvasPosition.x)
        self.canvasY = Double(canvasPosition.y)
        self.rotation = rotation == 0 ? Double.random(in: -0.07...0.07) : rotation
        self.stackOrder = 0
    }

    // MARK: Computed

    var category: EvidenceCategory {
        get { EvidenceCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var aspectMode: AspectMode {
        get { AspectMode(rawValue: aspectModeRaw) ?? .square }
        set { aspectModeRaw = newValue.rawValue }
    }
}
