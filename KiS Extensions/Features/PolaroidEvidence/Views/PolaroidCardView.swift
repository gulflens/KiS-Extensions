import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - PolaroidCardView

/// SwiftUI rendering of a polaroid card at Instax Wide proportions:
/// 300x239pt landscape card, 276x172pt image area, 53pt bottom caption strip.
struct PolaroidCardView: View {

    // MARK: Inputs

    let model: Model

    // MARK: Tunables

    private static let frameTint   = Color(red: 0xFC / 255.0, green: 0xFA / 255.0, blue: 0xF5 / 255.0)
    private static let frameStroke = Color(red: 0xE0 / 255.0, green: 0xE0 / 255.0, blue: 0xE0 / 255.0)
    private static let captionTint = Color(red: 0xFA / 255.0, green: 0xF7 / 255.0, blue: 0xF0 / 255.0)
    private static let cornerRadius: CGFloat = 8

    private static let cardSize  = CGSize(width: 300, height: 239)
    private static let photoSize = CGSize(width: 276, height: 172)
    private static let photoTopMargin: CGFloat = 14
    private static let captionStripHeight: CGFloat = 53

    // MARK: Body

    var body: some View {
        GeometryReader { geo in
            let scaleX = geo.size.width / Self.cardSize.width
            let scaleY = geo.size.height / Self.cardSize.height
            let scale = min(scaleX, scaleY)

            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: Self.cornerRadius * scale, style: .continuous)
                    .fill(Self.frameTint)
                    .overlay(
                        RoundedRectangle(cornerRadius: Self.cornerRadius * scale, style: .continuous)
                            .stroke(Self.frameStroke, lineWidth: 1)
                    )

                VStack(spacing: 0) {
                    photoArea(scale: scale)
                        .padding(.top, Self.photoTopMargin * scale)
                    Spacer(minLength: 0)
                    captionStrip(scale: scale)
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .aspectRatio(Self.cardSize.width / Self.cardSize.height, contentMode: .fit)
        .shadow(color: .black.opacity(0.10), radius: 12, x: 8, y: 10)
        .shadow(color: .black.opacity(0.20), radius: 6, x: 4, y: 6)
    }

    // MARK: Photo area

    @ViewBuilder
    private func photoArea(scale: CGFloat) -> some View {
        Group {
            #if canImport(UIKit)
            if let image = model.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color(white: 0.86)
            }
            #else
            Color(white: 0.86)
            #endif
        }
        .frame(width: Self.photoSize.width * scale, height: Self.photoSize.height * scale)
        .clipped()
    }

    // MARK: Caption strip

    @ViewBuilder
    private func captionStrip(scale: CGFloat) -> some View {
        GeometryReader { geo in
            let stripW = geo.size.width
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 2 * scale) {
                    Text(model.caption.isEmpty ? "(no caption)" : model.caption)
                        .font(.custom("Impact", size: 14 * scale))
                        .tracking(0.4 * scale)
                        .foregroundStyle(.black.opacity(0.85))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: stripW - 32 * scale)

                    Text(metadataLine)
                        .font(.system(size: 8 * scale, weight: .regular))
                        .foregroundStyle(.secondary.opacity(0.8))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Circle()
                    .fill(model.category.tintColor)
                    .frame(width: 18 * scale, height: 18 * scale)
                    .overlay {
                        Image(systemName: model.category.iconSymbol)
                            .font(.system(size: 9 * scale, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .padding(.top, 4 * scale)
                    .padding(.trailing, 6 * scale)
            }
        }
        .frame(height: Self.captionStripHeight * scale)
        .background(Self.captionTint)
        .clipShape(
            RoundedRectangle(cornerRadius: (Self.cornerRadius - 2) * scale, style: .continuous)
        )
        .padding(.horizontal, 1 * scale)
        .padding(.bottom, 1 * scale)
    }

    // MARK: Metadata helpers

    private var metadataLine: String {
        var parts: [String] = []
        if let flight = model.flight, !flight.isEmpty { parts.append(flight) }
        if let route = model.route, !route.isEmpty { parts.append(route) }
        if let seat = model.seat, !seat.isEmpty { parts.append(seat) }
        parts.append(Self.sharedDateFormatter.string(from: model.capturedAt))
        return parts.joined(separator: " \u{00B7} ")
    }

    private static let sharedDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd MMM yy"
        return f
    }()

    // MARK: Render to image

    #if canImport(UIKit)
    @MainActor
    static func renderToImage(model: Model, size: CGSize = CGSize(width: 600, height: 478)) -> UIImage? {
        let renderer = ImageRenderer(content:
            PolaroidCardView(model: model)
                .frame(width: size.width, height: size.height)
        )
        renderer.scale = 2.0
        return renderer.uiImage
    }
    #endif
}

// MARK: - Model

extension PolaroidCardView {

    struct Model {
        let caption: String
        let category: EvidenceCategory
        let flight: String?
        let route: String?
        let seat: String?
        let capturedAt: Date
        #if canImport(UIKit)
        let image: UIImage?
        #endif
    }
}

// MARK: - From PolaroidEvidence

extension PolaroidCardView.Model {
    init(polaroid: PolaroidEvidence) {
        self.caption = polaroid.caption
        self.category = polaroid.category
        self.flight = polaroid.flightNumber
        self.route = polaroid.route
        self.seat = polaroid.seatLocation
        self.capturedAt = polaroid.capturedAt
        #if canImport(UIKit)
        self.image = UIImage(data: polaroid.imageData)
        #endif
    }
}

// MARK: - From metadata + composer image

extension PolaroidCardView.Model {
    #if canImport(UIKit)
    init(metadata: PolaroidMetadata, image: UIImage?) {
        self.caption = metadata.caption
        self.category = metadata.category
        self.flight = metadata.flightNumber
        self.route = metadata.route
        self.seat = metadata.seatLocation
        self.capturedAt = metadata.capturedAt
        self.image = image
    }
    #endif
}
