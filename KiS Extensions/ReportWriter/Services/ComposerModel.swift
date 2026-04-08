import Foundation
import SwiftData
import FoundationModels

/// Selectable export formats for the final report.
enum ExportFormat: String, CaseIterable, Identifiable {
    case plainText = "Plain Text"
    case markdown = "Markdown"
    case portalPaste = "Portal Paste"

    var id: Self { self }
}

/// The view-model that drives the KiS report composer UI.
/// Manages bullet input, AI classification, report streaming, and export.
@Observable
class ComposerModel {

    // MARK: - Bullet input

    var rawBullets: String = "" { didSet { scheduleSave() } }

    /// Snapshot of the user's input at the time they pressed send.
    /// Used for the chat bubble and for AI calls. Cleared on reset.
    private(set) var committedBullets: String = ""

    // MARK: - Classification

    private(set) var classifiedPath: ClassifiedPath?
    private(set) var isClassifying = false

    // MARK: - Report

    private(set) var partialDraft: KiSDraft.PartiallyGenerated?
    var finalDraft: KiSDraft? { didSet { scheduleSave() } }
    private(set) var isWriting = false

    // MARK: - Template

    /// The currently active template, if the composer was seeded from one.
    /// Cleared once the user starts typing bullets.
    private(set) var activeTemplate: IncidentTemplate?

    // MARK: - Error

    private(set) var lastError: String?

    // MARK: - Agent

    private let agent = KiSAgent()

    // MARK: - Persistence

    /// The SwiftData record backing this session. Created lazily on first meaningful edit.
    private(set) var currentRecord: KiSReportRecord?

    /// The model context used for persistence. Injected from the view layer.
    var modelContext: ModelContext?

    /// Pending autosave task, cancelled and recreated on each edit for debounce.
    private var saveTask: Task<Void, Never>?

    // MARK: - Computed

    var canClassify: Bool {
        !rawBullets.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isClassifying && !isWriting
    }

    var canWriteReport: Bool {
        classifiedPath != nil && !isWriting && !isClassifying
    }

    var hasReport: Bool {
        finalDraft != nil
    }

    /// True when the composer has no user content — show the template picker button.
    var isComposerEmpty: Bool {
        rawBullets.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && committedBullets.isEmpty
            && classifiedPath == nil
            && finalDraft == nil
    }

    // MARK: - Actions

    /// Seeds the composer from an incident template.
    /// Sets the classification path and flight phase but does NOT auto-run classify or write.
    func applyTemplate(_ template: IncidentTemplate) {
        activeTemplate = template

        // Seed classification path from template
        classifiedPath = ClassifiedPath(
            cat1: template.suggestedCat1.rawValue,
            cat2: template.suggestedCat2,
            cat3: template.suggestedCat3,
            cat4: template.suggestedCat4
        )

        // Clear any existing report state
        partialDraft = nil
        finalDraft = nil

        scheduleSave()
    }

    /// Runs full AI classification (Cat1 → Cat2 → Cat3 → Cat4).
    func classify() async {
        guard canClassify else { return }

        // Snapshot the input and clear the field
        committedBullets = rawBullets
        rawBullets = ""

        isClassifying = true
        lastError = nil
        // Clear any previous report when re-classifying
        partialDraft = nil
        finalDraft = nil

        do {
            let path = try await agent.fullyClassify(bullets: committedBullets)
            classifiedPath = path
            scheduleSave()
        } catch {
            lastError = error.localizedDescription
        }

        isClassifying = false
    }

    /// Overrides a specific category level and clears children.
    func overrideCategory(level: Int, value: String) {
        guard let current = classifiedPath else { return }
        // Clear report when category changes
        partialDraft = nil
        finalDraft = nil

        switch level {
        case 1:
            classifiedPath = ClassifiedPath(cat1: value, cat2: nil, cat3: nil, cat4: nil)
        case 2:
            classifiedPath = ClassifiedPath(cat1: current.cat1, cat2: value, cat3: nil, cat4: nil)
        case 3:
            classifiedPath = ClassifiedPath(cat1: current.cat1, cat2: current.cat2, cat3: value, cat4: nil)
        case 4:
            classifiedPath = ClassifiedPath(cat1: current.cat1, cat2: current.cat2, cat3: current.cat3, cat4: value)
        default:
            break
        }
        scheduleSave()
    }

    /// Streams a report from the AI agent, updating partialDraft as tokens arrive.
    func generateReport() async {
        guard canWriteReport, let path = classifiedPath else { return }
        isWriting = true
        lastError = nil
        partialDraft = nil
        finalDraft = nil

        do {
            let stream = agent.streamReport(
                bullets: committedBullets,
                path: path
            )

            for try await snapshot in stream {
                partialDraft = snapshot.content
            }

            // Stream finished — promote the last partial to final
            if let partial = partialDraft {
                let partialAction = partial.actionTaken
                let action = ActionSection(
                    findings: partialAction?.findings ?? [],
                    customerManagement: partialAction?.customerManagement ?? "",
                    serviceRecovery: partialAction?.serviceRecovery ?? "",
                    followUp: partialAction?.followUp ?? "",
                    rootCause: partialAction?.rootCause ?? nil
                )

                let partialPriority = partial.priority
                let priority = PrioritySuggestion(
                    level: partialPriority?.level ?? "Info only",
                    reasoning: partialPriority?.reasoning ?? "",
                    confidential: partialPriority?.confidential ?? false
                )

                finalDraft = KiSDraft(
                    descriptionBullets: partial.descriptionBullets ?? [],
                    phase: partial.phase ?? .cruise,
                    location: partial.location ?? "",
                    actionTaken: action,
                    priority: priority
                )
            }
        } catch {
            lastError = error.localizedDescription
        }

        isWriting = false
    }

    // MARK: - Export

    /// The currently selected export format.
    var exportFormat: ExportFormat = .plainText

    /// Exports the final draft in the currently selected format.
    func exportFormatted() -> String? {
        switch exportFormat {
        case .plainText: return exportAsPlainText()
        case .markdown:  return exportAsMarkdown()
        case .portalPaste: return exportAsPortalPaste()
        }
    }

    /// Plain text with section separators matching KiS portal conventions.
    private func exportAsPlainText() -> String? {
        guard let draft = finalDraft, let path = classifiedPath else { return nil }

        let separator = String(repeating: "\u{2500}", count: 30)
        var lines: [String] = []

        lines.append("CATEGORY: \(path.displayPath)")
        lines.append("PHASE: \(draft.phase.rawValue)")
        lines.append("LOCATION: \(draft.location)")
        lines.append("")
        lines.append(separator)
        lines.append("DESCRIPTION:")
        for bullet in draft.descriptionBullets {
            lines.append("• \(bullet)")
        }
        lines.append("")
        lines.append(separator)
        lines.append("ACTION TAKEN:")
        lines.append("Findings:")
        for finding in draft.actionTaken.findings {
            lines.append("• \(finding)")
        }
        lines.append("Customer Management: \(draft.actionTaken.customerManagement)")
        lines.append("Service Recovery: \(draft.actionTaken.serviceRecovery)")
        lines.append("Follow Up: \(draft.actionTaken.followUp)")
        if let rootCause = draft.actionTaken.rootCause {
            lines.append("Root Cause: \(rootCause)")
        }
        lines.append("")
        lines.append(separator)
        lines.append("PRIORITY: \(draft.priority.level)")
        lines.append("REASONING: \(draft.priority.reasoning)")
        lines.append("CONFIDENTIAL: \(draft.priority.confidential ? "Yes" : "No")")

        return lines.joined(separator: "\n")
    }

    /// Markdown with headers, suitable for email bodies or notes.
    private func exportAsMarkdown() -> String? {
        guard let draft = finalDraft, let path = classifiedPath else { return nil }

        var lines: [String] = []

        lines.append("# KiS Report")
        lines.append("")
        lines.append("**Category:** \(path.displayPath)")
        lines.append("**Phase:** \(draft.phase.rawValue) | **Location:** \(draft.location)")
        lines.append("")
        lines.append("## Description")
        for bullet in draft.descriptionBullets {
            lines.append("- \(bullet)")
        }
        lines.append("")
        lines.append("## Action Taken")
        lines.append("### Findings")
        for finding in draft.actionTaken.findings {
            lines.append("- \(finding)")
        }
        lines.append("")
        lines.append("**Customer Management:** \(draft.actionTaken.customerManagement)")
        lines.append("**Service Recovery:** \(draft.actionTaken.serviceRecovery)")
        lines.append("**Follow Up:** \(draft.actionTaken.followUp)")
        if let rootCause = draft.actionTaken.rootCause {
            lines.append("**Root Cause:** \(rootCause)")
        }
        lines.append("")
        lines.append("## Priority")
        lines.append("**Level:** \(draft.priority.level)")
        lines.append("**Reasoning:** \(draft.priority.reasoning)")
        lines.append("**Confidential:** \(draft.priority.confidential ? "Yes" : "No")")

        return lines.joined(separator: "\n")
    }

    /// Field-delimited format designed for pasting into the KiS portal's separate input fields.
    private func exportAsPortalPaste() -> String? {
        guard let draft = finalDraft else { return nil }

        var lines: [String] = []

        lines.append("[FIELD: Description]")
        for bullet in draft.descriptionBullets {
            lines.append("• \(bullet)")
        }
        lines.append("")
        lines.append("[FIELD: Action Taken - Findings]")
        for finding in draft.actionTaken.findings {
            lines.append("• \(finding)")
        }
        lines.append("")
        lines.append("[FIELD: Action Taken - Customer Management]")
        lines.append(draft.actionTaken.customerManagement)
        lines.append("")
        lines.append("[FIELD: Action Taken - Service Recovery]")
        lines.append(draft.actionTaken.serviceRecovery)
        lines.append("")
        lines.append("[FIELD: Action Taken - Follow Up]")
        lines.append(draft.actionTaken.followUp)

        if let rootCause = draft.actionTaken.rootCause {
            lines.append("")
            lines.append("[FIELD: Action Taken - Root Cause]")
            lines.append(rootCause)
        }

        return lines.joined(separator: "\n")
    }

    /// Dismisses the current error banner.
    func dismissError() {
        lastError = nil
    }

    /// Resets the composer to its initial empty state.
    /// The current record is kept in SwiftData (history) — only in-memory state is cleared.
    func reset() {
        saveTask?.cancel()
        saveTask = nil

        // Detach from the current record so history is preserved
        currentRecord = nil

        rawBullets = ""
        committedBullets = ""
        activeTemplate = nil
        classifiedPath = nil
        partialDraft = nil
        finalDraft = nil
        isClassifying = false
        isWriting = false
        lastError = nil
    }

    // MARK: - Persistence helpers

    /// Whether there is enough content to warrant creating a record.
    private var hasMeaningfulContent: Bool {
        !rawBullets.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !committedBullets.isEmpty
    }

    /// Schedules a debounced autosave (500 ms).
    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(500))
            guard let self, !Task.isCancelled else { return }
            await MainActor.run { self.persistNow() }
        }
    }

    /// Immediately persists the current state to SwiftData.
    private func persistNow() {
        guard let context = modelContext, hasMeaningfulContent else { return }

        if let record = currentRecord {
            // Update existing record
            record.update(from: self)
        } else {
            // Create new record on first meaningful edit
            let record = KiSReportRecord()
            record.update(from: self)
            context.insert(record)
            currentRecord = record
        }
    }

    /// Loads a saved record back into the composer for editing.
    func loadFrom(record: KiSReportRecord) {
        saveTask?.cancel()

        currentRecord = record
        committedBullets = record.rawBullets
        rawBullets = ""

        // Restore classification path if available
        if let cat1 = record.classificationCat1Raw {
            classifiedPath = ClassifiedPath(
                cat1: cat1,
                cat2: record.classificationCat2,
                cat3: record.classificationCat3,
                cat4: record.classificationCat4
            )
        } else {
            classifiedPath = nil
        }

        // Restore final draft if available
        finalDraft = record.decodedDraft
        partialDraft = nil

        isClassifying = false
        isWriting = false
        lastError = nil
    }
}
