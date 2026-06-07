import SwiftUI
#if canImport(UIKit)
import UIKit

// MARK: - We Care Guideline Exporter (Stage 5)
//
// Renders the guideline document to a PDF file for sharing through the app's
// existing ShareSheet (UIActivityViewController). No new sharing mechanism.

enum WeCareGuidelineExporter {

    @MainActor
    static func makePDF(
        schedule: WeCareSchedule,
        sectorLabel: String,
        rules: WeCareRules = WeCareRulesLoader.shared
    ) -> URL? {
        let document = WeCareGuidelineDocument(
            schedule: schedule, sectorLabel: sectorLabel, rules: rules
        )
        let renderer = ImageRenderer(content: document)
        renderer.proposedSize = ProposedViewSize(width: 540, height: nil)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("We Care Guideline.pdf")

        var succeeded = false
        renderer.render { size, renderInContext in
            var box = CGRect(origin: .zero, size: size)
            guard let pdf = CGContext(url as CFURL, mediaBox: &box, nil) else { return }
            pdf.beginPDFPage(nil)
            renderInContext(pdf)
            pdf.endPDFPage()
            pdf.closePDF()
            succeeded = true
        }
        return succeeded ? url : nil
    }
}
#endif
