import SwiftUI

// MARK: - Concourses Layer

/// Static map background drawn via Canvas. Draws (bottom to top): taxiway
/// network, runway asphalt, support buildings, aprons, vertical concourse
/// piers, terminal buildings, stand fingers, transit connections, labels.
struct ConcoursesLayer: View {

    // MARK: - Palette

    private static let runwayAsphalt = Color(red: 0.18, green: 0.18, blue: 0.20)
    private static let taxiwayGreen = Color(red: 0x2E/255, green: 0x7D/255, blue: 0x32/255)
    private static let taxiwayYellow = Color(red: 0xF9/255, green: 0xA8/255, blue: 0x25/255)
    private static let taxiwayRed = Color(red: 0xC6/255, green: 0x28/255, blue: 0x28/255)
    private static let emiratesNavy = Color(red: 0x00/255, green: 0x22/255, blue: 0x4C/255)
    private static let neutralBuilding = Color(red: 0x55/255, green: 0x60/255, blue: 0x6E/255)
    private static let standFinger = Color(red: 0xD3/255, green: 0x2F/255, blue: 0x2F/255)
    private static let supportGrey = Color(red: 0x8E/255, green: 0x8E/255, blue: 0x93/255)

    @Environment(DXBDataStore.self) private var dataStore

    var body: some View {
        Canvas { context, _ in
            drawTaxiways(context: &context)
            drawRunways(context: &context)
            drawSupportBuildings(context: &context)
            drawAprons(context: &context)
            drawConcourses(context: &context)
            drawTerminals(context: &context)
            drawStandFingers(context: &context)
            drawConnections(context: &context)
            drawLabels(context: &context)
        }
        .frame(
            width: DXBSchematicLayout.canvasSize.width,
            height: DXBSchematicLayout.canvasSize.height
        )
    }

    // MARK: - Taxiways

    private func drawTaxiways(context: inout GraphicsContext) {
        for band in DXBSchematicLayout.taxiways {
            var path = Path()
            path.move(to: band.start)
            path.addLine(to: band.end)
            let tint: Color
            switch band.restriction {
            case .none:       tint = Self.taxiwayGreen
            case .limited:    tint = Self.taxiwayYellow
            case .restricted: tint = Self.taxiwayRed
            }
            context.stroke(
                path,
                with: .color(tint.opacity(0.85)),
                style: StrokeStyle(lineWidth: 14, lineCap: .round)
            )
        }
    }

    // MARK: - Runways

    private func drawRunways(context: inout GraphicsContext) {
        for runway in DXBSchematicLayout.runways {
            var asphalt = Path()
            asphalt.move(to: runway.start)
            asphalt.addLine(to: runway.end)
            context.stroke(
                asphalt,
                with: .color(Self.runwayAsphalt),
                style: StrokeStyle(lineWidth: 26, lineCap: .butt)
            )
            var centre = Path()
            centre.move(to: runway.start)
            centre.addLine(to: runway.end)
            context.stroke(
                centre,
                with: .color(Color.white.opacity(0.85)),
                style: StrokeStyle(lineWidth: 1.5, dash: [28, 18])
            )
        }
    }

    // MARK: - Support buildings

    private func drawSupportBuildings(context: inout GraphicsContext) {
        let buildings: [CGRect] = [
            DXBSchematicLayout.cargoTerminal,
            DXBSchematicLayout.ekTechCentre,
            DXBSchematicLayout.fireStationWest,
            DXBSchematicLayout.fireStationEast,
            DXBSchematicLayout.emiratesHQ,
            DXBSchematicLayout.fuelFarm,
            DXBSchematicLayout.controlTower
        ]
        for rect in buildings {
            let path = Path(roundedRect: rect, cornerRadius: 6)
            context.fill(path, with: .color(Self.supportGrey.opacity(0.30)))
            context.stroke(path, with: .color(Self.supportGrey.opacity(0.85)), lineWidth: 1.5)
        }
    }

    // MARK: - Aprons

    private func drawAprons(context: inout GraphicsContext) {
        let aprons: [CGRect] = [
            DXBSchematicLayout.apronQ,
            DXBSchematicLayout.apronE,
            DXBSchematicLayout.apronF,
            DXBSchematicLayout.apronG,
            DXBSchematicLayout.apronS,
            DXBSchematicLayout.apronH
        ]
        for rect in aprons {
            let path = Path(roundedRect: rect, cornerRadius: 6)
            context.fill(path, with: .color(Color(white: 0.78)))
            context.stroke(path, with: .color(Color(white: 0.55)), lineWidth: 1)
        }
    }

    // MARK: - Concourses (vertical piers)

    private func drawConcourses(context: inout GraphicsContext) {
        let piers: [(CGRect, Color)] = [
            (DXBSchematicLayout.concourseA, Self.emiratesNavy),
            (DXBSchematicLayout.concourseB, Self.emiratesNavy),
            (DXBSchematicLayout.concourseC, Self.emiratesNavy),
            (DXBSchematicLayout.concourseD, Self.neutralBuilding),
            (DXBSchematicLayout.concourseF, Self.neutralBuilding)
        ]
        for (rect, tint) in piers {
            let path = Path(roundedRect: rect, cornerRadius: 8)
            context.fill(path, with: .color(tint.opacity(0.85)))
            context.stroke(path, with: .color(tint), lineWidth: 1.5)
        }
    }

    // MARK: - Terminals

    private func drawTerminals(context: inout GraphicsContext) {
        let terminals: [(CGRect, Color)] = [
            (DXBSchematicLayout.t3Main, Self.emiratesNavy),
            (DXBSchematicLayout.t1Main, Self.neutralBuilding),
            (DXBSchematicLayout.t2Main, Self.neutralBuilding)
        ]
        for (rect, tint) in terminals {
            let path = Path(roundedRect: rect, cornerRadius: 10)
            context.fill(path, with: .color(tint.opacity(0.92)))
            context.stroke(path, with: .color(tint), lineWidth: 2)
        }
    }

    // MARK: - Stand fingers

    private func drawStandFingers(context: inout GraphicsContext) {
        for bay in dataStore.catalog.bays {
            guard let pos = dataStore.mapLayout.bayPositions[bay.bayId],
                  let dir = dataStore.mapLayout.bayFingerDirections[bay.bayId],
                  (dir.width != 0 || dir.height != 0) else { continue }

            let length: CGFloat = 14
            let width: CGFloat = 8
            let isHorizontal = dir.width != 0
            let rect: CGRect
            if isHorizontal {
                rect = CGRect(
                    x: dir.width < 0 ? pos.x - length : pos.x,
                    y: pos.y - width / 2,
                    width: length,
                    height: width
                )
            } else {
                rect = CGRect(
                    x: pos.x - width / 2,
                    y: dir.height < 0 ? pos.y - length : pos.y,
                    width: width,
                    height: length
                )
            }
            let path = Path(rect)
            context.fill(path, with: .color(Self.standFinger.opacity(0.85)))
            context.stroke(path, with: .color(Self.standFinger), lineWidth: 0.8)
        }
    }

    // MARK: - Connections

    private func drawConnections(context: inout GraphicsContext) {
        for connection in DXBSchematicLayout.trainConnections {
            var path = Path()
            path.move(to: connection.start)
            let mid = CGPoint(
                x: (connection.start.x + connection.end.x) / 2,
                y: max(connection.start.y, connection.end.y) + 60
            )
            path.addQuadCurve(to: connection.end, control: mid)
            context.stroke(
                path,
                with: .color(Self.emiratesNavy),
                style: StrokeStyle(
                    lineWidth: 4, lineCap: .round,
                    dash: connection.isUnderground ? [10, 6] : []
                )
            )
        }
        for connection in DXBSchematicLayout.walkConnections {
            var path = Path()
            path.move(to: connection.start)
            path.addLine(to: connection.end)
            context.stroke(
                path,
                with: .color(Color.gray),
                style: StrokeStyle(lineWidth: 4, lineCap: .round)
            )
        }
    }

    // MARK: - Labels

    private func drawLabels(context: inout GraphicsContext) {
        drawConcourseLabels(context: &context)
        drawTerminalLabels(context: &context)
        drawApronLabels(context: &context)
        drawSupportLabels(context: &context)
        drawTaxiwayLabels(context: &context)
        drawConnectionLabels(context: &context)
        drawRunwayLabels(context: &context)
    }

    private func drawConcourseLabels(context: inout GraphicsContext) {
        let labels: [(String, CGPoint)] = [
            ("A", CGPoint(
                x: DXBSchematicLayout.concourseA.midX,
                y: DXBSchematicLayout.concourseA.minY - 14
            )),
            ("B", CGPoint(
                x: DXBSchematicLayout.concourseB.midX,
                y: DXBSchematicLayout.concourseB.minY - 14
            )),
            ("C", CGPoint(
                x: DXBSchematicLayout.concourseC.midX,
                y: DXBSchematicLayout.concourseC.minY - 14
            )),
            ("D", CGPoint(
                x: DXBSchematicLayout.concourseD.midX,
                y: DXBSchematicLayout.concourseD.minY - 14
            )),
            ("F", CGPoint(
                x: DXBSchematicLayout.concourseF.midX,
                y: DXBSchematicLayout.concourseF.maxY + 10
            ))
        ]
        for (text, point) in labels {
            let resolved = context.resolve(
                Text(text)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            )
            context.draw(resolved, at: point, anchor: .center)
        }
    }

    private func drawTerminalLabels(context: inout GraphicsContext) {
        let labels: [(String, CGPoint)] = [
            ("Terminal 3", CGPoint(
                x: DXBSchematicLayout.t3Main.midX,
                y: DXBSchematicLayout.t3Main.midY
            )),
            ("Terminal 1", CGPoint(
                x: DXBSchematicLayout.t1Main.midX,
                y: DXBSchematicLayout.t1Main.midY
            )),
            ("Terminal 2", CGPoint(
                x: DXBSchematicLayout.t2Main.midX,
                y: DXBSchematicLayout.t2Main.midY
            ))
        ]
        for (text, point) in labels {
            let resolved = context.resolve(
                Text(text)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
            )
            context.draw(resolved, at: point, anchor: .center)
        }
    }

    private func drawApronLabels(context: inout GraphicsContext) {
        for tag in DXBSchematicLayout.apronTags {
            let title = context.resolve(
                Text(tag.title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(white: 0.20))
            )
            context.draw(
                title,
                at: CGPoint(x: tag.rect.midX, y: tag.rect.midY),
                anchor: .center
            )
        }
    }

    private func drawSupportLabels(context: inout GraphicsContext) {
        let labels: [(String, CGRect, CGFloat)] = [
            ("Cargo",              DXBSchematicLayout.cargoTerminal,  10),
            ("EK Tech Centre",     DXBSchematicLayout.ekTechCentre,   10),
            ("Fire",               DXBSchematicLayout.fireStationWest, 9),
            ("Fire",               DXBSchematicLayout.fireStationEast, 9),
            ("Emirates HQ",        DXBSchematicLayout.emiratesHQ,     11),
            ("Fuel Farm",          DXBSchematicLayout.fuelFarm,       10)
        ]
        for (text, rect, size) in labels {
            let resolved = context.resolve(
                Text(text)
                    .font(.system(size: size, weight: .medium))
                    .foregroundColor(Color(white: 0.95))
            )
            context.draw(
                resolved,
                at: CGPoint(x: rect.midX, y: rect.midY),
                anchor: .center
            )
        }
    }

    private func drawTaxiwayLabels(context: inout GraphicsContext) {
        for band in DXBSchematicLayout.taxiways {
            guard let label = band.label else { continue }
            let mid = CGPoint(
                x: (band.start.x + band.end.x) / 2,
                y: (band.start.y + band.end.y) / 2
            )
            let resolved = context.resolve(
                Text(label)
                    .font(.system(size: 11, weight: .heavy).monospaced())
                    .foregroundColor(.white)
            )
            context.draw(resolved, at: mid, anchor: .center)
        }
    }

    private func drawConnectionLabels(context: inout GraphicsContext) {
        if let apm = DXBSchematicLayout.trainConnections.first, let label = apm.label {
            let mid = CGPoint(
                x: (apm.start.x + apm.end.x) / 2,
                y: max(apm.start.y, apm.end.y) + 80
            )
            let resolved = context.resolve(
                Text(label).font(.system(size: 12, weight: .medium))
            )
            context.draw(resolved, at: mid, anchor: .center)
        }
        for connection in DXBSchematicLayout.walkConnections {
            guard let label = connection.label else { continue }
            let mid = CGPoint(
                x: (connection.start.x + connection.end.x) / 2,
                y: (connection.start.y + connection.end.y) / 2 - 12
            )
            let resolved = context.resolve(
                Text(label).font(.system(size: 11, weight: .medium))
            )
            context.draw(resolved, at: mid, anchor: .center)
        }
    }

    private func drawRunwayLabels(context: inout GraphicsContext) {
        for runway in DXBSchematicLayout.runways {
            let westLabel = context.resolve(
                Text(runway.westThresholdLabel)
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(.white)
            )
            context.draw(
                westLabel,
                at: CGPoint(x: runway.start.x + 22, y: runway.start.y),
                anchor: .center
            )
            let eastLabel = context.resolve(
                Text(runway.eastThresholdLabel)
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(.white)
            )
            context.draw(
                eastLabel,
                at: CGPoint(x: runway.end.x - 22, y: runway.end.y),
                anchor: .center
            )
            let designator = context.resolve(
                Text(runway.label)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.75))
            )
            context.draw(
                designator,
                at: CGPoint(
                    x: (runway.start.x + runway.end.x) / 2,
                    y: runway.start.y - 18
                ),
                anchor: .center
            )
        }
    }
}
