import Foundation

// MARK: - AspectMode

enum AspectMode: String, Codable, Sendable {
    case square
    case fullFrame
}

// MARK: - PolaroidMetadata

struct PolaroidMetadata: Equatable, Sendable {
    var caption: String = ""
    var category: EvidenceCategory = .cabinDefect
    var flightNumber: String? = nil
    var route: String? = nil
    var seatLocation: String? = nil
    var capturedAt: Date = Date()
    var aspectMode: AspectMode = .square

    // MARK: Derived

    var isReady: Bool { !caption.isEmpty }
}
