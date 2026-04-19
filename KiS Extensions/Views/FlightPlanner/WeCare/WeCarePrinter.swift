import SwiftUI
import UIKit

// MARK: - We Care Printer

enum WeCarePrinter {

    @MainActor
    static func print(result: WeCareResult, state: WeCareState, sectorLabel: String) {
        let view = PrintableWeCare(result: result, state: state, sectorLabel: sectorLabel)
            .frame(width: 595, height: 842)

        let renderer = ImageRenderer(content: view)
        renderer.scale = 3

        guard let pageImage = renderer.uiImage else { return }

        let info = UIPrintInfo(dictionary: nil)
        info.jobName = "We Care Schedule"
        info.outputType = .grayscale

        let controller = UIPrintInteractionController.shared
        controller.printInfo = info
        controller.printingItem = pageImage
        controller.present(animated: true)
    }

    @MainActor
    static func sharePDF(result: WeCareResult, state: WeCareState, sectorLabel: String) -> URL? {
        let view = PrintableWeCare(result: result, state: state, sectorLabel: sectorLabel)
            .frame(width: 595, height: 842)

        let renderer = ImageRenderer(content: view)
        let safe = sectorLabel.replacingOccurrences(of: " ", with: "_")
        let filename = "WeCare_\(safe).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        renderer.render { size, renderToContext in
            var box = CGRect(origin: .zero, size: size)
            guard let pdf = CGContext(url as CFURL, mediaBox: &box, nil) else { return }
            pdf.beginPDFPage(nil)
            renderToContext(pdf)
            pdf.endPDFPage()
            pdf.closePDF()
        }

        return url
    }
}

// MARK: - Share Item

struct WeCareShareItem: Identifiable {
    let id = UUID()
    let url: URL
}

// MARK: - Share Sheet

struct WeCareShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Printable We Care

private struct PrintableWeCare: View {
    let result: WeCareResult
    let state: WeCareState
    let sectorLabel: String

    var body: some View {
        VStack(spacing: 0) {
            header
            Spacer().frame(height: 20)
            keyTimes
            Spacer().frame(height: 20)
            servicePlacements
            ForEach(result.cabinResults) { cabinResult in
                Spacer().frame(height: 20)
                cabinSection(cabinResult)
            }
            Spacer()
            footer
        }
        .padding(36)
        .frame(width: 595, height: 842)
        .background(Color.white)
        .foregroundStyle(.black)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 6) {
            HStack {
                Text("We Care Schedule")
                    .font(.system(size: 20, weight: .bold))
                Spacer()
                Text(dateString)
                    .font(.system(size: 11))
                    .foregroundStyle(.gray)
            }

            Rectangle().fill(.black).frame(height: 1.5)

            HStack(spacing: 16) {
                if !sectorLabel.isEmpty {
                    headerTag("Sector", sectorLabel)
                }
                if !state.aircraftModel.isEmpty {
                    headerTag("Aircraft", "\(state.aircraftModel) \(state.numberOfClasses)-class")
                }
                headerTag("Flight time", flightDuration)
                headerTag("Services", "\(state.numberOfServices)")
                Spacer()
            }
            .padding(.top, 2)
        }
    }

    private func headerTag(_ label: String, _ value: String) -> some View {
        HStack(spacing: 4) {
            Text("\(label):")
                .font(.system(size: 10))
                .foregroundStyle(.gray)
            Text(value)
                .font(.system(size: 10, weight: .semibold))
        }
        .lineLimit(1)
        .fixedSize()
    }

    private var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "dd MMM yyyy  HH:mm"
        return f.string(from: Date())
    }

    private var flightDuration: String {
        let h = state.flightDurationMin / 60
        let m = state.flightDurationMin % 60
        if m == 0 { return "\(h)h" }
        return "\(h)h \(m)m"
    }

    // MARK: - Key Times

    private var keyTimes: some View {
        VStack(spacing: 0) {
            sectionTitle("Key times")

            HStack(spacing: 0) {
                keyTimeCell("Takeoff", WeCareCalculator.formatMinutes(state.takeoffMin))
                keyTimeCell("Landing", WeCareCalculator.formatMinutes(state.landingMin))
                keyTimeCell("Top of descent", WeCareCalculator.formatMinutes(state.topOfDescentMin))
                keyTimeCell("Duration", flightDuration)
            }
            .overlay(Rectangle().stroke(.black, lineWidth: 1))
        }
    }

    private func keyTimeCell(_ label: String, _ value: String) -> some View {
        VStack(spacing: 3) {
            Text(label.uppercased())
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(.gray)
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .overlay(Rectangle().stroke(.black, lineWidth: 1))
    }

    // MARK: - Service Placements

    private var servicePlacements: some View {
        VStack(spacing: 0) {
            sectionTitle("Service placements")

            serviceHeader

            ForEach(Array(result.servicePlacements.enumerated()), id: \.offset) { idx, svc in
                serviceRow(svc, isEven: idx % 2 == 0)
            }
        }
    }

    private var serviceHeader: some View {
        HStack(spacing: 0) {
            Text("SERVICE")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 6)
                .overlay(alignment: .trailing) { cellBorder }
            Text("START")
                .frame(width: 70, alignment: .center)
                .overlay(alignment: .trailing) { cellBorder }
            Text("END (JC)")
                .frame(width: 70, alignment: .center)
                .overlay(alignment: .trailing) { cellBorder }
            Text("END (YC)")
                .frame(width: 70, alignment: .center)
        }
        .font(.system(size: 8, weight: .bold))
        .foregroundStyle(.gray)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.black.opacity(0.08))
        .overlay(Rectangle().stroke(.black, lineWidth: 1))
    }

    private func serviceRow(_ svc: WeCareServicePlacement, isEven: Bool) -> some View {
        HStack(spacing: 0) {
            Text(serviceName(svc.serviceNumber))
                .font(.system(size: 10, weight: .medium))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 6)
                .overlay(alignment: .trailing) { cellBorder }
            Text(WeCareCalculator.formatMinutes(svc.startMin))
                .font(.system(size: 10, design: .monospaced))
                .frame(width: 70, alignment: .center)
                .overlay(alignment: .trailing) { cellBorder }
            Text(svc.durationJC > 0 ? WeCareCalculator.formatMinutes(svc.startMin + svc.durationJC) : "\u{2014}")
                .font(.system(size: 10, design: .monospaced))
                .frame(width: 70, alignment: .center)
                .overlay(alignment: .trailing) { cellBorder }
            Text(svc.durationYC > 0 ? WeCareCalculator.formatMinutes(svc.startMin + svc.durationYC) : "\u{2014}")
                .font(.system(size: 10, design: .monospaced))
                .frame(width: 70, alignment: .center)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(isEven ? Color.black.opacity(0.03) : Color.white)
        .overlay(Rectangle().stroke(.black, lineWidth: 1))
    }

    // MARK: - Cabin Section

    private func cabinSection(_ cabinResult: CabinWeCareResult) -> some View {
        VStack(spacing: 0) {
            sectionTitle("\(cabinResult.cabin.rawValue) (\(cabinResult.cabin.cycleDurationMin)-min cycles) — \(cabinResult.totalCycles) total")

            cycleHeader

            let allCycles = cabinResult.gaps.flatMap { gap in
                gap.cycles.map { (cycle: $0, afterService: gap.afterService) }
            }

            ForEach(Array(allCycles.enumerated()), id: \.offset) { idx, item in
                cycleRow(item.cycle, afterService: item.afterService, isEven: idx % 2 == 0)
            }

            if cabinResult.gaps.isEmpty {
                HStack {
                    Text("No We Care gaps available")
                        .font(.system(size: 10))
                        .foregroundStyle(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .overlay(Rectangle().stroke(.black, lineWidth: 1))
            }
        }
    }

    private var cycleHeader: some View {
        HStack(spacing: 0) {
            Text("CYCLE")
                .frame(width: 50, alignment: .center)
                .overlay(alignment: .trailing) { cellBorder }
            Text("START")
                .frame(width: 70, alignment: .center)
                .overlay(alignment: .trailing) { cellBorder }
            Text("END")
                .frame(width: 70, alignment: .center)
                .overlay(alignment: .trailing) { cellBorder }
            Text("AFTER SERVICE")
                .frame(width: 90, alignment: .center)
                .overlay(alignment: .trailing) { cellBorder }
            Text("CREW")
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .font(.system(size: 8, weight: .bold))
        .foregroundStyle(.gray)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.black.opacity(0.08))
        .overlay(Rectangle().stroke(.black, lineWidth: 1))
    }

    private func cycleRow(_ cycle: WeCareCycle, afterService: Int, isEven: Bool) -> some View {
        HStack(spacing: 0) {
            Text("\(cycle.cycleNumber)")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .frame(width: 50, alignment: .center)
                .overlay(alignment: .trailing) { cellBorder }
            Text(WeCareCalculator.formatMinutes(cycle.startMin))
                .font(.system(size: 10, design: .monospaced))
                .frame(width: 70, alignment: .center)
                .overlay(alignment: .trailing) { cellBorder }
            Text(WeCareCalculator.formatMinutes(cycle.endMin))
                .font(.system(size: 10, design: .monospaced))
                .frame(width: 70, alignment: .center)
                .overlay(alignment: .trailing) { cellBorder }
            Text(afterService > 0 ? "Service \(afterService)" : "\u{2014}")
                .font(.system(size: 10))
                .frame(width: 90, alignment: .center)
                .overlay(alignment: .trailing) { cellBorder }
            Text(cycle.assignedCrew.joined(separator: ", "))
                .font(.system(size: 10))
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isEven ? Color.black.opacity(0.03) : Color.white)
        .overlay(Rectangle().stroke(.black, lineWidth: 1))
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 4) {
            Rectangle().fill(.black).frame(height: 1)
            HStack {
                Text("Generated by KiS Extensions")
                    .font(.system(size: 8))
                    .foregroundStyle(.gray)
                Spacer()
                Text("Verify with official EK documentation")
                    .font(.system(size: 8))
                    .foregroundStyle(.gray)
            }
        }
    }

    // MARK: - Helpers

    private var cellBorder: some View {
        Rectangle().fill(.black).frame(width: 1)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .bold))
            .tracking(0.8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 6)
    }

    private func serviceName(_ number: Int) -> String {
        let total = state.numberOfServices
        if total == 1 { return "Service" }
        switch number {
        case 1: return "First service"
        case _ where number == total: return "Last service"
        default: return "Middle service"
        }
    }
}
