import Foundation
import PDFKit
import UIKit

// MARK: - Flight Crew Checklist PDF Exporter

/// Builds a fillable PDF with interactive checkbox widgets next to each
/// scheduled call. Receiver can tap checkboxes in Apple's Files/Preview/Books
/// on iPhone/iPad and the state saves into the PDF.
enum FlightCrewChecklistPDFExporter {

    struct CrewRow {
        let role: String
        let name: String
        let assignment: String
    }

    struct ScheduleRow {
        let time: Date
        let note: String
    }

    // iPhone 14 logical screen size — page fits the screen exactly in portrait.
    private static let pageSize = CGSize(width: 390, height: 844)
    private static let margin: CGFloat = 14
    private static let scheduleRowHeight: CGFloat = 28
    private static let checkboxSize: CGFloat = 18
    private static let checkboxColor = UIColor(red: 0.10, green: 0.55, blue: 0.20, alpha: 1.0)

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    private static let stampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd MMM yyyy  HH:mm"
        return f
    }()

    /// Per-row layout for annotation placement. UIKit Y, column X offset,
    /// time/notes/done column widths within that column.
    private struct RowLayout {
        let uiY: CGFloat
        let columnX: CGFloat
        let timeW: CGFloat
        let doneW: CGFloat
        let columnWidth: CGFloat
    }

    @MainActor
    static func makePDF(
        takeoff: Date,
        landing: Date,
        topOfDescent: Date,
        twentyToTop: Date,
        durationMinutes: Int,
        crew: [CrewRow],
        schedule: [ScheduleRow],
        sectorLabel: String
    ) -> URL? {
        var rowLayouts: [RowLayout] = []

        let bounds = CGRect(origin: .zero, size: pageSize)
        let renderer = UIGraphicsPDFRenderer(bounds: bounds)

        let data = renderer.pdfData { ctx in
            ctx.beginPage()
            var y: CGFloat = margin

            // Title + timestamp (compact)
            "Flight Crew Checklist".draw(at: CGPoint(x: margin, y: y), withAttributes: [
                .font: UIFont.boldSystemFont(ofSize: 14),
                .foregroundColor: UIColor.black
            ])
            let stamp = stampFormatter.string(from: Date())
            let stampSize = (stamp as NSString).size(withAttributes: [
                .font: UIFont.systemFont(ofSize: 8)
            ])
            stamp.draw(
                at: CGPoint(x: pageSize.width - margin - stampSize.width, y: y + 4),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 8),
                    .foregroundColor: UIColor.gray
                ]
            )
            y += 20

            UIColor.black.setStroke()
            let div = UIBezierPath()
            div.move(to: CGPoint(x: margin, y: y))
            div.addLine(to: CGPoint(x: pageSize.width - margin, y: y))
            div.lineWidth = 1
            div.stroke()
            y += 6

            if !sectorLabel.isEmpty {
                "Sector: \(sectorLabel)".draw(at: CGPoint(x: margin, y: y), withAttributes: [
                    .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
                    .foregroundColor: UIColor.black
                ])
                y += 16
            }

            // MARK: Key Times — 5 narrow cells
            y = drawSectionTitle("Key times", at: y)
            let cellW = (pageSize.width - margin * 2) / 5
            let keyTimes: [(String, String)] = [
                ("Take off", timeFormatter.string(from: takeoff)),
                ("Duration", formatDuration(durationMinutes)),
                ("20 to top", timeFormatter.string(from: twentyToTop)),
                ("TOD", timeFormatter.string(from: topOfDescent)),
                ("Landing", timeFormatter.string(from: landing))
            ]
            let cellH: CGFloat = 30
            for (i, (label, value)) in keyTimes.enumerated() {
                let x = margin + CGFloat(i) * cellW
                let rect = CGRect(x: x, y: y, width: cellW, height: cellH)
                UIBezierPath(rect: rect).stroke()
                label.uppercased().draw(
                    at: CGPoint(x: x + 3, y: y + 3),
                    withAttributes: [
                        .font: UIFont.systemFont(ofSize: 6.5, weight: .semibold),
                        .foregroundColor: UIColor.gray
                    ]
                )
                value.draw(
                    at: CGPoint(x: x + 3, y: y + 14),
                    withAttributes: [
                        .font: UIFont.monospacedDigitSystemFont(ofSize: 11, weight: .bold),
                        .foregroundColor: UIColor.black
                    ]
                )
            }
            y += cellH + 12

            // MARK: Flight Crew
            y = drawSectionTitle("Flight crew", at: y)
            y = drawTableHeader(["ROLE", "NAME", "ASGN"], widths: [72, .infinity, 72], at: y)
            if crew.isEmpty {
                let rect = CGRect(x: margin, y: y, width: pageSize.width - margin * 2, height: 18)
                UIBezierPath(rect: rect).stroke()
                "No crew entered".draw(
                    at: CGPoint(x: margin + 4, y: y + 5),
                    withAttributes: [
                        .font: UIFont.systemFont(ofSize: 9),
                        .foregroundColor: UIColor.gray
                    ]
                )
                y += 18
            } else {
                let rowH: CGFloat = 18
                let nameX = margin + 72
                let assignmentX = pageSize.width - margin - 72
                for row in crew {
                    let rect = CGRect(x: margin, y: y, width: pageSize.width - margin * 2, height: rowH)
                    UIBezierPath(rect: rect).stroke()
                    drawVerticalSeparator(x: nameX, top: y, bottom: y + rowH)
                    drawVerticalSeparator(x: assignmentX, top: y, bottom: y + rowH)
                    row.role.draw(
                        at: CGPoint(x: margin + 4, y: y + 4),
                        withAttributes: [
                            .font: UIFont.systemFont(ofSize: 9, weight: .medium),
                            .foregroundColor: UIColor.black
                        ]
                    )
                    let name = row.name.isEmpty ? "—" : row.name
                    name.draw(
                        at: CGPoint(x: nameX + 4, y: y + 4),
                        withAttributes: [
                            .font: UIFont.systemFont(ofSize: 9),
                            .foregroundColor: UIColor.black
                        ]
                    )
                    row.assignment.draw(
                        at: CGPoint(x: assignmentX + 4, y: y + 4),
                        withAttributes: [
                            .font: UIFont.systemFont(ofSize: 9),
                            .foregroundColor: UIColor.black
                        ]
                    )
                    y += rowH
                }
            }
            y += 12

            // MARK: Call schedule (most prominent)
            y = drawSectionTitle("Call schedule  (tap a box to mark done)", at: y)

            // Decide layout: switch to 2 columns when single-column would overflow.
            let singleColRowLimit = 18
            let useTwoColumns = schedule.count > singleColRowLimit

            if useTwoColumns {
                let colGap: CGFloat = 6
                let columnWidth = (pageSize.width - margin * 2 - colGap) / 2
                let leftX = margin
                let rightX = margin + columnWidth + colGap
                let timeW: CGFloat = 50
                let doneW: CGFloat = 50

                // Draw two side-by-side headers
                let headerY = y
                drawNarrowScheduleHeader(at: headerY, x: leftX, columnWidth: columnWidth, timeW: timeW, doneW: doneW)
                drawNarrowScheduleHeader(at: headerY, x: rightX, columnWidth: columnWidth, timeW: timeW, doneW: doneW)
                y += 14

                let mid = (schedule.count + 1) / 2
                var y1 = y
                var y2 = y
                for (i, row) in schedule.enumerated() {
                    let isLeft = i < mid
                    let colX = isLeft ? leftX : rightX
                    let rowY = isLeft ? y1 : y2
                    drawNarrowScheduleRow(
                        row,
                        at: rowY,
                        x: colX,
                        columnWidth: columnWidth,
                        timeW: timeW,
                        doneW: doneW
                    )
                    rowLayouts.append(RowLayout(
                        uiY: rowY, columnX: colX,
                        timeW: timeW, doneW: doneW, columnWidth: columnWidth
                    ))
                    if isLeft { y1 += scheduleRowHeight } else { y2 += scheduleRowHeight }
                }
                y = max(y1, y2)
            } else {
                y = drawTableHeader(
                    ["TIME", "Notes / Informations / Requests", "DONE"],
                    widths: [72, .infinity, 72],
                    at: y
                )
                let fullWidth = pageSize.width - margin * 2
                let timeW: CGFloat = 72
                let doneW: CGFloat = 72
                let timeColumnEndX = margin + timeW
                let doneColumnStartX = pageSize.width - margin - doneW
                for row in schedule {
                    let rect = CGRect(x: margin, y: y, width: fullWidth, height: scheduleRowHeight)
                    UIBezierPath(rect: rect).stroke()
                    drawVerticalSeparator(x: timeColumnEndX, top: y, bottom: y + scheduleRowHeight)
                    drawVerticalSeparator(x: doneColumnStartX, top: y, bottom: y + scheduleRowHeight)
                    timeFormatter.string(from: row.time).draw(
                        at: CGPoint(x: margin + 4, y: y + 8),
                        withAttributes: [
                            .font: UIFont.monospacedDigitSystemFont(ofSize: 11, weight: .semibold),
                            .foregroundColor: UIColor.black
                        ]
                    )
                    // Modern rounded checkbox visual (subtle fill + green ring)
                    let cbX = doneColumnStartX + (doneW - checkboxSize) / 2
                    let cbY = y + (scheduleRowHeight - checkboxSize) / 2
                    drawCheckboxShape(x: cbX, y: cbY)
                    UIColor.black.setStroke()

                    rowLayouts.append(RowLayout(
                        uiY: y, columnX: margin,
                        timeW: timeW, doneW: doneW, columnWidth: fullWidth
                    ))
                    y += scheduleRowHeight
                }
            }

            // Hint under the schedule table
            y += 4
            let hintFont = UIFont.italicSystemFont(ofSize: 8)
            let iconPointSize: CGFloat = 8
            let iconConfig = UIImage.SymbolConfiguration(pointSize: iconPointSize, weight: .regular)
            let symbol = UIImage(systemName: "rectangle.and.pencil.and.ellipsis", withConfiguration: iconConfig)?
                .withTintColor(.darkGray, renderingMode: .alwaysOriginal)
            // Rasterize so the symbol embeds cleanly in the PDF.
            let rasterIcon: UIImage? = symbol.map { sym in
                UIGraphicsImageRenderer(size: sym.size).image { _ in
                    sym.draw(at: .zero)
                }
            }

            let attributed = NSMutableAttributedString()
            if let rasterIcon {
                let attachment = NSTextAttachment()
                attachment.image = rasterIcon
                // Center icon vertically against the text x-height by offsetting bounds.
                let yShift = (hintFont.capHeight - rasterIcon.size.height) / 2
                attachment.bounds = CGRect(
                    x: 0,
                    y: yShift,
                    width: rasterIcon.size.width,
                    height: rasterIcon.size.height
                )
                attributed.append(NSAttributedString(attachment: attachment))
                attributed.append(NSAttributedString(string: "  "))
            }
            attributed.append(NSAttributedString(
                string: "Don't Activate Autofill  /  Double tap the Notes Column to add a comment",
                attributes: [
                    .font: hintFont,
                    .foregroundColor: UIColor.darkGray
                ]
            ))
            attributed.draw(at: CGPoint(x: margin, y: y))

            // Footer
            let footerY = pageSize.height - margin - 10
            let footerLine = UIBezierPath()
            footerLine.move(to: CGPoint(x: margin, y: footerY - 2))
            footerLine.addLine(to: CGPoint(x: pageSize.width - margin, y: footerY - 2))
            footerLine.lineWidth = 0.5
            footerLine.stroke()
            "Generated by KiS Extensions".draw(
                at: CGPoint(x: margin, y: footerY + 2),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 7),
                    .foregroundColor: UIColor.gray
                ]
            )
            let disclaimer = "Verify with official EK documentation"
            let dSize = (disclaimer as NSString).size(withAttributes: [
                .font: UIFont.systemFont(ofSize: 7)
            ])
            disclaimer.draw(
                at: CGPoint(x: pageSize.width - margin - dSize.width, y: footerY + 2),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 7),
                    .foregroundColor: UIColor.gray
                ]
            )

            // MARK: - Page 2: Guidelines
            ctx.beginPage()
            drawGuidelinesPage()
        }

        // Add interactive checkbox annotations
        guard let document = PDFDocument(data: data),
              let page = document.page(at: 0) else { return nil }

        for (idx, layout) in rowLayouts.enumerated() {
            let columnRight = layout.columnX + layout.columnWidth
            let notesLeft = layout.columnX + layout.timeW + 2
            let notesRightEdge = columnRight - layout.doneW
            let notesWidth = notesRightEdge - notesLeft - 4

            // Notes — editable text field
            let notesPdfY = pageSize.height - layout.uiY - scheduleRowHeight + 2
            let notesRect = CGRect(
                x: notesLeft,
                y: notesPdfY,
                width: notesWidth,
                height: scheduleRowHeight - 4
            )
            let notesField = PDFAnnotation(bounds: notesRect, forType: .widget, withProperties: nil)
            notesField.widgetFieldType = .text
            notesField.fieldName = "note_\(idx)"
            notesField.font = UIFont.systemFont(ofSize: 9)
            notesField.fontColor = .black
            notesField.backgroundColor = .clear
            let seed = schedule[idx].note.trimmingCharacters(in: .whitespacesAndNewlines)
            if !seed.isEmpty {
                notesField.widgetStringValue = seed
            }
            page.addAnnotation(notesField)

            // Done — checkbox
            let checkboxColumnLeft = columnRight - layout.doneW + (layout.doneW - checkboxSize) / 2
            let pdfY = pageSize.height - layout.uiY - scheduleRowHeight + (scheduleRowHeight - checkboxSize) / 2
            let rect = CGRect(x: checkboxColumnLeft, y: pdfY, width: checkboxSize, height: checkboxSize)
            let annotation = PDFAnnotation(bounds: rect, forType: .widget, withProperties: nil)
            annotation.widgetFieldType = .button
            annotation.widgetControlType = .checkBoxControl
            annotation.fieldName = "call_\(idx)"
            annotation.backgroundColor = UIColor.clear
            annotation.color = Self.checkboxColor
            annotation.fontColor = Self.checkboxColor
            annotation.buttonWidgetState = .offState
            annotation.border = PDFBorder()
            annotation.border?.lineWidth = 0
            page.addAnnotation(annotation)
        }

        // Write to temp file
        let safeLabel = sectorLabel.replacingOccurrences(of: "/", with: "-")
        let filename = safeLabel.isEmpty
            ? "FD Checklist.pdf"
            : "FD Checklist \(safeLabel).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: url)
        if document.write(to: url) {
            return url
        }
        return nil
    }

    // MARK: Helpers

    private static func drawSectionTitle(_ title: String, at y: CGFloat) -> CGFloat {
        title.uppercased().draw(
            at: CGPoint(x: margin, y: y),
            withAttributes: [
                .font: UIFont.boldSystemFont(ofSize: 8.5),
                .foregroundColor: UIColor.black
            ]
        )
        return y + 13
    }

    /// Draws a grey table-header row with column labels. Returns the Y below it.
    private static func drawTableHeader(_ titles: [String], widths: [CGFloat], at y: CGFloat) -> CGFloat {
        let headerH: CGFloat = 14
        let fullW = pageSize.width - margin * 2
        let headerRect = CGRect(x: margin, y: y, width: fullW, height: headerH)
        UIColor(white: 0.92, alpha: 1).setFill()
        UIBezierPath(rect: headerRect).fill()
        UIColor.black.setStroke()
        UIBezierPath(rect: headerRect).stroke()

        // Vertical separators at fixed column boundaries (assumes
        // [leftFixed, flexible, rightFixed] layout).
        if widths.count == 3, widths[1] == .infinity {
            let leftSep = margin + widths[0]
            let rightSep = pageSize.width - margin - widths[2]
            drawVerticalSeparator(x: leftSep, top: y, bottom: y + headerH)
            drawVerticalSeparator(x: rightSep, top: y, bottom: y + headerH)
        }

        var x: CGFloat = margin + 4
        for (i, title) in titles.enumerated() {
            // Right-align the last column
            if i == titles.count - 1 {
                x = pageSize.width - margin - widths[i] + 4
            }
            title.draw(at: CGPoint(x: x, y: y + 3), withAttributes: [
                .font: UIFont.boldSystemFont(ofSize: 7),
                .foregroundColor: UIColor.gray
            ])
            if widths[i] != .infinity {
                x += widths[i]
            } else {
                x += 200
            }
        }
        return y + headerH
    }

    // MARK: - Guidelines page (page 2)

    private static func drawGuidelinesPage() {
        var y: CGFloat = margin

        // Header
        "Flight Crew Service Guidelines".draw(
            at: CGPoint(x: margin, y: y),
            withAttributes: [
                .font: UIFont.boldSystemFont(ofSize: 11),
                .foregroundColor: UIColor.black
            ]
        )
        y += 16
        UIColor.black.setStroke()
        let div = UIBezierPath()
        div.move(to: CGPoint(x: margin, y: y))
        div.addLine(to: CGPoint(x: pageSize.width - margin, y: y))
        div.lineWidth = 1
        div.stroke()
        y += 6

        // Responsible Crew table
        y = drawSectionTitle("Responsible crew", at: y)
        y = drawResponsibleCrewTable(at: y)
        // ML2 note
        let note = "On A380 2/3 Class, ML2 is responsible; remaining crew support as needed."
        note.draw(
            at: CGPoint(x: margin, y: y + 2),
            withAttributes: [
                .font: UIFont.italicSystemFont(ofSize: 6.5),
                .foregroundColor: UIColor.gray
            ]
        )
        y += 14

        y = drawBulletSection(
            "Communication",
            bullets: [
                "Note how each pilot wishes to be called (from briefing).",
                "Speak to captain first; wait before talking on flight deck.",
                "Hand-up = hold (they're receiving comms).",
                "Answer interphone calls immediately."
            ],
            at: y
        )
        y += 4
        y = drawBulletSection(
            "Do not serve",
            bullets: [
                "Shellfish, molluscs or crustaceans.",
                "Same appetiser/main/dessert for both pilots.",
                "First Class galley food incl. caviar.",
                "No alcohol in the flight deck."
            ],
            at: y
        )
        y += 4
        y = drawBulletSection(
            "Must do",
            bullets: [
                "Prevent contamination of flight-crew food.",
                "Serve heated meals promptly (avoid cold)."
            ],
            at: y
        )
        y += 4
        y = drawBulletSection(
            "Equipment",
            bullets: [
                "Paper cups + lids only; no glass/mugs in FD.",
                "If no FD cups, use other cabin (JCL/WCL) paper cups + lids."
            ],
            at: y
        )
        y += 4
        y = drawBulletSection(
            "Catering — Food",
            bullets: [
                "Crew Products container loaded on all flights (FD drawer).",
                "Snacks tray + bread box = 'Pilot' sticker.",
                "Hot meals labelled TCR, in foils — plating not required.",
                "Cat 1-2: 1 hot meal Ex-DXB. Cat 3-8: 2 hot meals Ex-DXB."
            ],
            at: y
        )
        y += 4
        y = drawBulletSection(
            "Drinks",
            bullets: [
                "Cat 1: ask small/large water. Cat 2-8: large bottle.",
                "Hand water bottle directly. No drinks over centre console."
            ],
            at: y
        )
        y += 6
        y = drawSectionTitle("Cabin crew duties", at: y)
        y = drawBulletSection(
            "Before departure",
            bullets: [
                "Introduce yourself; take drink order.",
                "Deliver drinks, water, wrapped snacks, tissue box, waste bag.",
                "Don't bag flight-deck food foils.",
                "Before last door close: remove food/drinks (keep water).",
                "Turnarounds: flight crew may eat on the ground."
            ],
            at: y
        )
        y += 3
        y = drawBulletSection(
            "After take-off",
            bullets: [
                "Ask purser when/how often to contact flight crew.",
                "Return collected food/drinks to the flight deck.",
                "Lavatory priority for flight crew — delay customers if needed."
            ],
            at: y
        )
        y += 3
        y = drawBulletSection(
            "Inflight — cruise",
            bullets: [
                "B777 2 Class: close curtains when FD exits; open on return.",
                "Tell flight crew what's available; when you'll take part in service.",
                "Arrange meal time; captain decides who eats first.",
                "Meal not ready before arranged time; offer drink + table linen."
            ],
            at: y
        )
        y += 3
        y = drawBulletSection(
            "Before / After landing",
            bullets: [
                "Before: remove food and drinks (keep water bottles).",
                "After: collect waste bag + used water bottles → bin near FD galley."
            ],
            at: y
        )
        y += 3
        y = drawBulletSection(
            "Aircraft waste",
            bullets: [
                "A380 / A350: 2 bar waste bags in pilot's individual bins (outboard).",
                "B777: hook + bar waste bag at the centre console."
            ],
            at: y
        )

        // Footer
        let footerY = pageSize.height - margin - 10
        let footerLine = UIBezierPath()
        footerLine.move(to: CGPoint(x: margin, y: footerY - 2))
        footerLine.addLine(to: CGPoint(x: pageSize.width - margin, y: footerY - 2))
        footerLine.lineWidth = 0.5
        footerLine.stroke()
        "Generated by KiS Extensions".draw(
            at: CGPoint(x: margin, y: footerY + 2),
            withAttributes: [
                .font: UIFont.systemFont(ofSize: 7),
                .foregroundColor: UIColor.gray
            ]
        )
        let disclaimer = "Verify with official EK documentation"
        let dSize = (disclaimer as NSString).size(withAttributes: [.font: UIFont.systemFont(ofSize: 7)])
        disclaimer.draw(
            at: CGPoint(x: pageSize.width - margin - dSize.width, y: footerY + 2),
            withAttributes: [
                .font: UIFont.systemFont(ofSize: 7),
                .foregroundColor: UIColor.gray
            ]
        )
    }

    private static func drawResponsibleCrewTable(at y: CGFloat) -> CGFloat {
        var cy = y
        let rows: [(String, String, String)] = [
            ("A380 4 Class", "MR3A", "ML5"),
            ("A380 3 Class", "ML2",  "ML5"),
            ("A380 2 Class", "ML2",  "ML5"),
            ("B777 3 Class", "L1",   "R1"),
            ("B777 2 Class", "L1A",  "R1")
        ]
        let primaryW: CGFloat = 90
        let onRestW: CGFloat = 90
        let aircraftW = pageSize.width - margin * 2 - primaryW - onRestW

        // Header row
        let headerH: CGFloat = 14
        let headerRect = CGRect(x: margin, y: cy, width: pageSize.width - margin * 2, height: headerH)
        UIColor(white: 0.92, alpha: 1).setFill()
        UIBezierPath(rect: headerRect).fill()
        UIColor.black.setStroke()
        UIBezierPath(rect: headerRect).stroke()
        drawVerticalSeparator(x: margin + aircraftW, top: cy, bottom: cy + headerH)
        drawVerticalSeparator(x: margin + aircraftW + primaryW, top: cy, bottom: cy + headerH)
        "AIRCRAFT".draw(at: CGPoint(x: margin + 4, y: cy + 3), withAttributes: [
            .font: UIFont.boldSystemFont(ofSize: 7), .foregroundColor: UIColor.gray
        ])
        "RESPONSIBLE".draw(at: CGPoint(x: margin + aircraftW + 4, y: cy + 3), withAttributes: [
            .font: UIFont.boldSystemFont(ofSize: 7), .foregroundColor: UIColor.gray
        ])
        "IF ON REST".draw(at: CGPoint(x: margin + aircraftW + primaryW + 4, y: cy + 3), withAttributes: [
            .font: UIFont.boldSystemFont(ofSize: 7), .foregroundColor: UIColor.gray
        ])
        cy += headerH

        // Data rows
        let rowH: CGFloat = 16
        for (aircraft, primary, onRest) in rows {
            let rowRect = CGRect(x: margin, y: cy, width: pageSize.width - margin * 2, height: rowH)
            UIBezierPath(rect: rowRect).stroke()
            drawVerticalSeparator(x: margin + aircraftW, top: cy, bottom: cy + rowH)
            drawVerticalSeparator(x: margin + aircraftW + primaryW, top: cy, bottom: cy + rowH)
            aircraft.draw(at: CGPoint(x: margin + 4, y: cy + 4), withAttributes: [
                .font: UIFont.systemFont(ofSize: 9), .foregroundColor: UIColor.black
            ])
            primary.draw(at: CGPoint(x: margin + aircraftW + 4, y: cy + 4), withAttributes: [
                .font: UIFont.monospacedDigitSystemFont(ofSize: 10, weight: .bold),
                .foregroundColor: UIColor.black
            ])
            onRest.draw(at: CGPoint(x: margin + aircraftW + primaryW + 4, y: cy + 4), withAttributes: [
                .font: UIFont.monospacedDigitSystemFont(ofSize: 10, weight: .bold),
                .foregroundColor: UIColor.black
            ])
            cy += rowH
        }
        return cy
    }

    private static func drawBulletSection(_ title: String, bullets: [String], at y: CGFloat) -> CGFloat {
        var cy = y
        title.draw(at: CGPoint(x: margin, y: cy), withAttributes: [
            .font: UIFont.boldSystemFont(ofSize: 8.5),
            .foregroundColor: UIColor.black
        ])
        cy += 12
        let textW = pageSize.width - margin * 2 - 10
        for bullet in bullets {
            "•".draw(at: CGPoint(x: margin + 2, y: cy), withAttributes: [
                .font: UIFont.systemFont(ofSize: 8),
                .foregroundColor: UIColor.darkGray
            ])
            let para = NSMutableParagraphStyle()
            para.lineBreakMode = .byWordWrapping
            let text = NSAttributedString(string: bullet, attributes: [
                .font: UIFont.systemFont(ofSize: 8),
                .foregroundColor: UIColor.darkGray,
                .paragraphStyle: para
            ])
            let bounds = text.boundingRect(
                with: CGSize(width: textW, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                context: nil
            )
            text.draw(in: CGRect(x: margin + 10, y: cy, width: textW, height: bounds.height))
            cy += max(bounds.height, 10) + 1
        }
        return cy
    }

    // MARK: - Narrow schedule (two-column mode)

    private static func drawNarrowScheduleHeader(at y: CGFloat, x: CGFloat, columnWidth: CGFloat, timeW: CGFloat, doneW: CGFloat) {
        let headerH: CGFloat = 14
        let rect = CGRect(x: x, y: y, width: columnWidth, height: headerH)
        UIColor(white: 0.92, alpha: 1).setFill()
        UIBezierPath(rect: rect).fill()
        UIColor.black.setStroke()
        UIBezierPath(rect: rect).stroke()
        let leftSep = x + timeW
        let rightSep = x + columnWidth - doneW
        drawVerticalSeparator(x: leftSep, top: y, bottom: y + headerH)
        drawVerticalSeparator(x: rightSep, top: y, bottom: y + headerH)

        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 7),
            .foregroundColor: UIColor.gray
        ]
        "TIME".draw(at: CGPoint(x: x + 3, y: y + 3), withAttributes: attrs)
        "NOTES".draw(at: CGPoint(x: leftSep + 3, y: y + 3), withAttributes: attrs)
        "DONE".draw(at: CGPoint(x: rightSep + 3, y: y + 3), withAttributes: attrs)
    }

    private static func drawNarrowScheduleRow(_ row: ScheduleRow, at y: CGFloat, x: CGFloat, columnWidth: CGFloat, timeW: CGFloat, doneW: CGFloat) {
        let rect = CGRect(x: x, y: y, width: columnWidth, height: scheduleRowHeight)
        UIBezierPath(rect: rect).stroke()
        let leftSep = x + timeW
        let rightSep = x + columnWidth - doneW
        drawVerticalSeparator(x: leftSep, top: y, bottom: y + scheduleRowHeight)
        drawVerticalSeparator(x: rightSep, top: y, bottom: y + scheduleRowHeight)
        timeFormatter.string(from: row.time).draw(
            at: CGPoint(x: x + 3, y: y + 8),
            withAttributes: [
                .font: UIFont.monospacedDigitSystemFont(ofSize: 10, weight: .semibold),
                .foregroundColor: UIColor.black
            ]
        )
        // Modern rounded checkbox visual (subtle fill + green ring).
        let cbX = x + columnWidth - doneW + (doneW - checkboxSize) / 2
        let cbY = y + (scheduleRowHeight - checkboxSize) / 2
        drawCheckboxShape(x: cbX, y: cbY)
        UIColor.black.setStroke()
    }

    private static func drawCheckboxShape(x: CGFloat, y: CGFloat) {
        let rect = CGRect(x: x, y: y, width: checkboxSize, height: checkboxSize)
        let path = UIBezierPath(rect: rect)
        path.lineWidth = 1.2
        checkboxColor.setStroke()
        path.stroke()
    }

    private static func drawVerticalSeparator(x: CGFloat, top: CGFloat, bottom: CGFloat) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: x, y: top))
        path.addLine(to: CGPoint(x: x, y: bottom))
        path.lineWidth = 0.5
        UIColor.black.setStroke()
        path.stroke()
    }

    private static func formatDuration(_ minutes: Int) -> String {
        let h = max(0, minutes) / 60
        let m = max(0, minutes) % 60
        return String(format: "%02d:%02d", h, m)
    }
}
