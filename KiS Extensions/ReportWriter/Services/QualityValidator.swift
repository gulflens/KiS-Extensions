import Foundation

// MARK: - Quality issue types

enum QualitySeverity: String, Hashable {
    case warning
    case info
}

struct QualityIssue: Identifiable, Hashable {
    let id = UUID()
    let ruleID: String
    let severity: QualitySeverity
    let message: String
    let fieldPath: String
}

// MARK: - Validator

enum QualityValidator {

    /// Validates a finalized KiSDraft and returns any issues found.
    static func validate(_ draft: KiSDraft) -> [QualityIssue] {
        var issues: [QualityIssue] = []

        // Collect all text fields with their paths
        var fields: [(String, String)] = []  // (text, fieldPath)

        for (i, bullet) in draft.descriptionBullets.enumerated() {
            fields.append((bullet, "description.bullet[\(i)]"))
        }
        for (i, finding) in draft.actionTaken.findings.enumerated() {
            fields.append((finding, "action.findings[\(i)]"))
        }
        fields.append((draft.actionTaken.customerManagement, "action.customerManagement"))
        fields.append((draft.actionTaken.serviceRecovery, "action.serviceRecovery"))
        fields.append((draft.actionTaken.followUp, "action.followUp"))
        if let rc = draft.actionTaken.rootCause {
            fields.append((rc, "action.rootCause"))
        }
        fields.append((draft.location, "location"))
        fields.append((draft.priority.reasoning, "priority.reasoning"))

        // Run strict rules on each field
        for (text, path) in fields {
            guard !text.isEmpty else { continue }
            issues.append(contentsOf: checkEmoji(text, fieldPath: path))
            issues.append(contentsOf: checkSpecialSymbols(text, fieldPath: path))
            issues.append(contentsOf: checkAllCaps(text, fieldPath: path))
            issues.append(contentsOf: checkFirstPerson(text, fieldPath: path))
        }

        // Quoted speech check — only on description bullets and findings
        let speechFields = draft.descriptionBullets.enumerated().map { (i, b) in (b, "description.bullet[\(i)]") }
            + draft.actionTaken.findings.enumerated().map { (i, f) in (f, "action.findings[\(i)]") }
        for (text, path) in speechFields {
            guard !text.isEmpty else { continue }
            issues.append(contentsOf: checkQuotedSpeech(text, fieldPath: path))
        }

        // Long paragraph check — only on description bullets
        for (i, bullet) in draft.descriptionBullets.enumerated() {
            issues.append(contentsOf: checkLongParagraph(bullet, fieldPath: "description.bullet[\(i)]"))
        }

        // Soft checks
        for (text, path) in fields {
            guard !text.isEmpty else { continue }
            issues.append(contentsOf: checkCrewWithoutStaffNumber(text, fieldPath: path))
        }

        if draft.phase == .cruise {
            issues.append(QualityIssue(
                ruleID: "missing_phase",
                severity: .info,
                message: "Flight phase is set to 'cruise' — confirm this is correct",
                fieldPath: "phase"
            ))
        }

        let allText = fields.map(\.0).joined(separator: " ")
        let wordCount = allText.split(whereSeparator: { $0.isWhitespace }).count
        if wordCount < 40 {
            issues.append(QualityIssue(
                ruleID: "very_short_report",
                severity: .info,
                message: "Report is very short (\(wordCount) words) — consider adding more detail",
                fieldPath: "report"
            ))
        }

        return issues
    }

    // MARK: - Strict rules

    private static func checkEmoji(_ text: String, fieldPath: String) -> [QualityIssue] {
        for scalar in text.unicodeScalars {
            if scalar.properties.isEmoji && scalar.properties.isEmojiPresentation {
                return [QualityIssue(
                    ruleID: "no_emoji",
                    severity: .warning,
                    message: "Remove emoji — KiS portal does not accept emoji characters",
                    fieldPath: fieldPath
                )]
            }
        }
        return []
    }

    private static let forbiddenSymbols: Set<Character> = ["#", "@", "*", "<", ">"]

    private static func checkSpecialSymbols(_ text: String, fieldPath: String) -> [QualityIssue] {
        for char in text {
            if forbiddenSymbols.contains(char) {
                return [QualityIssue(
                    ruleID: "no_special_symbols",
                    severity: .warning,
                    message: "Remove special symbol \"\(char)\" — use plain text only",
                    fieldPath: fieldPath
                )]
            }
        }
        return []
    }

    /// Known abbreviations that are legitimately all-caps.
    private static let capsExceptions: Set<String> = [
        // Aircraft types
        "A380", "A340", "A330", "B777", "B787",
        // Airport codes (common EK destinations)
        "DXB", "LHR", "AMS", "JFK", "SIN", "BKK", "MAN", "CDG", "SYD",
        "LAX", "SFO", "ORD", "IAD", "BOS", "ICN", "NRT", "HKG", "MEL",
        "PER", "BNE", "MLE", "CMB", "DAC", "KHI", "ISB", "DEL", "BOM",
        "MAA", "BLR", "HYD", "COK", "TRV", "CCJ", "GRU", "EZE", "MRU",
        // Airline / operational abbreviations
        "AVML", "VGML", "HNML", "BBML", "DBML", "MOML", "KSML", "VLML",
        "FPML", "GFML", "LFML", "NLML", "SFML", "BLML", "LSML", "NSML", "OBML",
        "EMK", "FAK", "SEMK", "UPK", "SCCM", "SFS", "IFE", "ROB", "SPML",
        "VCM", "MFP", "CSA", "KIS", "MOD", "IBDN", "WCH", "VVIP", "CIP",
        "USB", "LED", "LCD", "PSU", "PED", "MEL",
    ]

    private static let allCapsPattern = try! NSRegularExpression(pattern: "\\b[A-Z]{3,}\\b")
    private static let flightNumberPattern = try! NSRegularExpression(pattern: "^EK\\d+$")

    private static func checkAllCaps(_ text: String, fieldPath: String) -> [QualityIssue] {
        let range = NSRange(text.startIndex..., in: text)
        let matches = allCapsPattern.matches(in: text, range: range)

        for match in matches {
            guard let matchRange = Range(match.range, in: text) else { continue }
            let word = String(text[matchRange])

            // Skip known exceptions
            if capsExceptions.contains(word) { continue }

            // Skip flight numbers like EK388
            let wordNSRange = NSRange(word.startIndex..., in: word)
            if flightNumberPattern.firstMatch(in: word, range: wordNSRange) != nil { continue }

            return [QualityIssue(
                ruleID: "no_all_caps",
                severity: .warning,
                message: "Avoid ALL CAPS — use normal capitalisation (exception: aircraft/flight codes)",
                fieldPath: fieldPath
            )]
        }
        return []
    }

    /// First-person pronouns to flag. Case-sensitive for "I" variants, case-insensitive for others.
    private static let firstPersonPatternCaseSensitive = try! NSRegularExpression(
        pattern: "\\b(I|I'm|I've|I'd|I'll)\\b"
    )
    private static let firstPersonPatternCaseInsensitive = try! NSRegularExpression(
        pattern: "\\b(we|we're|we've|we'd|we'll|us|our|ours|my|mine)\\b",
        options: .caseInsensitive
    )

    private static func checkFirstPerson(_ text: String, fieldPath: String) -> [QualityIssue] {
        // Find all quoted regions to exclude
        let quotedRanges = findQuotedRanges(in: text)
        let nsRange = NSRange(text.startIndex..., in: text)

        for pattern in [firstPersonPatternCaseSensitive, firstPersonPatternCaseInsensitive] {
            let matches = pattern.matches(in: text, range: nsRange)
            for match in matches {
                // Skip if inside quotes
                let isQuoted = quotedRanges.contains { $0.contains(match.range.location) }
                if isQuoted { continue }

                guard let matchRange = Range(match.range, in: text) else { continue }
                let word = String(text[matchRange])

                return [QualityIssue(
                    ruleID: "no_first_person",
                    severity: .warning,
                    message: "Use third-person language — avoid \"\(word)\" outside of quoted speech",
                    fieldPath: fieldPath
                )]
            }
        }
        return []
    }

    private static let speechVerbPattern = try! NSRegularExpression(
        pattern: "\\b(said|stated|told|complained|asked|requested|mentioned)\\b\\s+(?!\")",
        options: .caseInsensitive
    )

    private static func checkQuotedSpeech(_ text: String, fieldPath: String) -> [QualityIssue] {
        let nsRange = NSRange(text.startIndex..., in: text)
        if speechVerbPattern.firstMatch(in: text, range: nsRange) != nil {
            return [QualityIssue(
                ruleID: "quoted_speech",
                severity: .warning,
                message: "Customer speech should be in double quotes",
                fieldPath: fieldPath
            )]
        }
        return []
    }

    private static func checkLongParagraph(_ text: String, fieldPath: String) -> [QualityIssue] {
        let sentenceEnders = text.filter { $0 == "." || $0 == "!" || $0 == "?" }
        if sentenceEnders.count >= 3 {
            return [QualityIssue(
                ruleID: "no_long_paragraphs",
                severity: .warning,
                message: "Keep bullets concise — split into separate points if longer than 2 sentences",
                fieldPath: fieldPath
            )]
        }
        return []
    }

    // MARK: - Soft checks

    private static let crewRolePattern = try! NSRegularExpression(
        pattern: "\\b(SFS|SCCM|purser|crew member|CSA)\\b",
        options: .caseInsensitive
    )
    private static let staffNumberPattern = try! NSRegularExpression(
        pattern: "[sS]\\d{5,6}"
    )

    private static func checkCrewWithoutStaffNumber(_ text: String, fieldPath: String) -> [QualityIssue] {
        let nsRange = NSRange(text.startIndex..., in: text)
        guard crewRolePattern.firstMatch(in: text, range: nsRange) != nil else { return [] }
        if staffNumberPattern.firstMatch(in: text, range: nsRange) != nil { return [] }

        return [QualityIssue(
            ruleID: "crew_without_staff_number",
            severity: .info,
            message: "Crew member referenced without staff number — consider adding for traceability",
            fieldPath: fieldPath
        )]
    }

    // MARK: - Helpers

    /// Finds ranges of double-quoted strings in text.
    private static func findQuotedRanges(in text: String) -> [NSRange] {
        var ranges: [NSRange] = []
        let nsText = text as NSString
        var searchStart = 0

        while searchStart < nsText.length {
            let openQuote = nsText.range(of: "\"", range: NSRange(location: searchStart, length: nsText.length - searchStart))
            guard openQuote.location != NSNotFound else { break }

            let afterOpen = openQuote.location + 1
            guard afterOpen < nsText.length else { break }

            let closeQuote = nsText.range(of: "\"", range: NSRange(location: afterOpen, length: nsText.length - afterOpen))
            guard closeQuote.location != NSNotFound else { break }

            ranges.append(NSRange(location: openQuote.location, length: closeQuote.location - openQuote.location + 1))
            searchStart = closeQuote.location + 1
        }

        return ranges
    }
}
