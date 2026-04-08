import SwiftUI
import FoundationModels

/// Displays the AI-generated report in chat-style assistant bubbles.
/// - During streaming: read-only Text views from `PartiallyGenerated`.
/// - After completion: editable TextFields/TextEditors bound to `finalDraft`.
struct ReportSection: View {
    @Bindable var model: ComposerModel
    @State private var showQualityDetails = false

    var body: some View {
        if model.isWriting, let partial = model.partialDraft {
            streamingView(partial)
        } else if let draft = model.finalDraft {
            qualityPanel(for: draft)
            editableView
        }
    }

    // MARK: - Quality checks panel

    @ViewBuilder
    private func qualityPanel(for draft: KiSDraft) -> some View {
        let issues = QualityValidator.validate(draft)
        if !issues.isEmpty {
            let warnings = issues.filter { $0.severity == .warning }
            let infos = issues.filter { $0.severity == .info }

            AssistantBubble {
                DisclosureGroup(isExpanded: $showQualityDetails) {
                    ForEach(issues) { issue in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: issue.severity == .warning ? "exclamationmark.triangle.fill" : "info.circle.fill")
                                .foregroundStyle(issue.severity == .warning ? .orange : .blue)
                                .font(.caption)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(issue.message)
                                    .font(.caption)
                                Text(issue.fieldPath)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.shield")
                            .foregroundStyle(warnings.isEmpty ? .blue : .orange)
                        Text("Quality checks")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        if !warnings.isEmpty {
                            Text("\(warnings.count) warning\(warnings.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                        if !infos.isEmpty {
                            Text("\(infos.count) info")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Streaming (read-only)

    @ViewBuilder
    private func streamingView(_ partial: KiSDraft.PartiallyGenerated) -> some View {
        AssistantBubble {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Generating report...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let bullets = partial.descriptionBullets, !bullets.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Description")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        ForEach(Array(bullets.enumerated()), id: \.offset) { _, bullet in
                            Label(bullet, systemImage: "circle.fill")
                                .font(.subheadline)
                                .labelStyle(BulletLabelStyle())
                        }
                    }
                }

                if let phase = partial.phase {
                    HStack(spacing: 4) {
                        Text("Phase:")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(phase.rawValue.capitalized)
                            .font(.subheadline)
                    }
                }

                if let location = partial.location, !location.isEmpty {
                    HStack(spacing: 4) {
                        Text("Location:")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(location)
                            .font(.subheadline)
                    }
                }

                if let action = partial.actionTaken {
                    streamingActionContent(action)
                }

                if let priority = partial.priority {
                    streamingPriorityContent(priority)
                }
            }
        }
    }

    @ViewBuilder
    private func streamingActionContent(_ action: ActionSection.PartiallyGenerated) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Action Taken")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            if let findings = action.findings, !findings.isEmpty {
                ForEach(Array(findings.enumerated()), id: \.offset) { _, finding in
                    Label(finding, systemImage: "circle.fill")
                        .font(.subheadline)
                        .labelStyle(BulletLabelStyle())
                }
            }

            if let cm = action.customerManagement, !cm.isEmpty {
                Text(cm).font(.subheadline)
            }

            if let sr = action.serviceRecovery, !sr.isEmpty {
                Text(sr).font(.subheadline)
            }

            if let fu = action.followUp, !fu.isEmpty {
                Text(fu).font(.subheadline)
            }

            if let rc = action.rootCause, !rc.isEmpty {
                Text(rc).font(.subheadline)
            }
        }
    }

    @ViewBuilder
    private func streamingPriorityContent(_ priority: PrioritySuggestion.PartiallyGenerated) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Priority")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            if let level = priority.level {
                Text(level)
                    .font(.subheadline.weight(.medium))
            }
            if let reasoning = priority.reasoning, !reasoning.isEmpty {
                Text(reasoning)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let confidential = priority.confidential, confidential {
                Label("Confidential", systemImage: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }

    // MARK: - Editable (post-stream)

    @ViewBuilder
    private var editableView: some View {
        // Two-column layout: Description | Action Taken
        HStack(alignment: .top, spacing: 12) {
            // Left column — Description + Phase/Location
            VStack(alignment: .leading, spacing: 12) {
                // Description
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Description")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(descriptionCharCount)/1500")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(descriptionCharCount > 1500 ? Color.red : Color.secondary)
                    }

                    if let draft = model.finalDraft {
                        ForEach(draft.descriptionBullets.indices, id: \.self) { index in
                            TextField("Bullet \(index + 1)", text: bulletBinding(at: index), axis: .vertical)
                                .lineLimit(1...4)
                                .font(.subheadline)
                        }
                    }
                }

                Divider()

                // Phase & Location
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Phase")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Picker("Phase", selection: phaseBinding) {
                            ForEach(FlightPhase.allCases, id: \.self) { phase in
                                Text(phase.rawValue.capitalized).tag(phase)
                            }
                        }
                        .labelsHidden()
                        .tint(.primary)
                    }

                    HStack(spacing: 4) {
                        Text("Location")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        TextField("e.g. galley 4R", text: locationBinding)
                            .font(.subheadline)
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white)
            )

            // Right column — Action Taken + Priority
            VStack(alignment: .leading, spacing: 12) {
                // Action Taken
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Action Taken")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(actionCharCount)/1500")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(actionCharCount > 1500 ? Color.red : Color.secondary)
                    }

                    editableActionFields
                }

                Divider()

                // Priority
                VStack(alignment: .leading, spacing: 8) {
                    Text("Priority")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Picker("Level", selection: priorityLevelBinding) {
                        Text("Critical").tag("Critical")
                        Text("Follow up required").tag("Follow up required")
                        Text("Info only").tag("Info only")
                    }
                    .pickerStyle(.segmented)

                    TextField("Reasoning", text: priorityReasoningBinding, axis: .vertical)
                        .lineLimit(2...5)
                        .font(.subheadline)

                    Toggle("Confidential", isOn: confidentialBinding)
                        .font(.subheadline)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white)
            )
        }
    }

    // MARK: - Editable action fields

    @ViewBuilder
    private var editableActionFields: some View {
        if let draft = model.finalDraft {
            // Findings
            Text("Findings")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
            ForEach(draft.actionTaken.findings.indices, id: \.self) { index in
                TextField("Finding \(index + 1)", text: findingBinding(at: index), axis: .vertical)
                    .lineLimit(1...4)
                    .font(.subheadline)
            }

            TextField("Customer Management", text: customerManagementBinding, axis: .vertical)
                .lineLimit(2...5)
                .font(.subheadline)

            TextField("Service Recovery", text: serviceRecoveryBinding, axis: .vertical)
                .lineLimit(2...5)
                .font(.subheadline)

            TextField("Follow Up", text: followUpBinding, axis: .vertical)
                .lineLimit(2...5)
                .font(.subheadline)

            TextField("Root Cause (optional)", text: rootCauseBinding, axis: .vertical)
                .lineLimit(1...3)
                .font(.subheadline)
        }
    }

    // MARK: - Character counts

    private var descriptionCharCount: Int {
        model.finalDraft?.descriptionBullets.joined(separator: "\n").count ?? 0
    }

    private var actionCharCount: Int {
        guard let action = model.finalDraft?.actionTaken else { return 0 }
        let parts = [
            action.findings.joined(separator: "\n"),
            action.customerManagement,
            action.serviceRecovery,
            action.followUp,
            action.rootCause ?? ""
        ]
        return parts.joined(separator: "\n").count
    }

    // MARK: - Bindings

    private func bulletBinding(at index: Int) -> Binding<String> {
        Binding(
            get: {
                guard let bullets = model.finalDraft?.descriptionBullets,
                      bullets.indices.contains(index) else { return "" }
                return bullets[index]
            },
            set: {
                guard model.finalDraft?.descriptionBullets.indices.contains(index) == true else { return }
                model.finalDraft?.descriptionBullets[index] = $0
            }
        )
    }

    private var phaseBinding: Binding<FlightPhase> {
        Binding(
            get: { model.finalDraft?.phase ?? .cruise },
            set: { model.finalDraft?.phase = $0 }
        )
    }

    private var locationBinding: Binding<String> {
        Binding(
            get: { model.finalDraft?.location ?? "" },
            set: { model.finalDraft?.location = $0 }
        )
    }

    private func findingBinding(at index: Int) -> Binding<String> {
        Binding(
            get: {
                guard let findings = model.finalDraft?.actionTaken.findings,
                      findings.indices.contains(index) else { return "" }
                return findings[index]
            },
            set: {
                guard model.finalDraft?.actionTaken.findings.indices.contains(index) == true else { return }
                model.finalDraft?.actionTaken.findings[index] = $0
            }
        )
    }

    private var customerManagementBinding: Binding<String> {
        Binding(
            get: { model.finalDraft?.actionTaken.customerManagement ?? "" },
            set: { model.finalDraft?.actionTaken.customerManagement = $0 }
        )
    }

    private var serviceRecoveryBinding: Binding<String> {
        Binding(
            get: { model.finalDraft?.actionTaken.serviceRecovery ?? "" },
            set: { model.finalDraft?.actionTaken.serviceRecovery = $0 }
        )
    }

    private var followUpBinding: Binding<String> {
        Binding(
            get: { model.finalDraft?.actionTaken.followUp ?? "" },
            set: { model.finalDraft?.actionTaken.followUp = $0 }
        )
    }

    private var rootCauseBinding: Binding<String> {
        Binding(
            get: { model.finalDraft?.actionTaken.rootCause ?? "" },
            set: {
                let value = $0.isEmpty ? nil : $0
                model.finalDraft?.actionTaken.rootCause = value
            }
        )
    }

    private var priorityLevelBinding: Binding<String> {
        Binding(
            get: { model.finalDraft?.priority.level ?? "Info only" },
            set: { model.finalDraft?.priority.level = $0 }
        )
    }

    private var priorityReasoningBinding: Binding<String> {
        Binding(
            get: { model.finalDraft?.priority.reasoning ?? "" },
            set: { model.finalDraft?.priority.reasoning = $0 }
        )
    }

    private var confidentialBinding: Binding<Bool> {
        Binding(
            get: { model.finalDraft?.priority.confidential ?? false },
            set: { model.finalDraft?.priority.confidential = $0 }
        )
    }
}

// MARK: - Bullet label style

private struct BulletLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            configuration.icon
                .font(.system(size: 4))
                .foregroundStyle(.secondary)
            configuration.title
        }
    }
}
