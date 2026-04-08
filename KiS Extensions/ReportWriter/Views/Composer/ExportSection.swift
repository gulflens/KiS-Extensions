import SwiftUI

/// Export format picker, "Copy to clipboard", preview, and "New report" buttons.
/// Shown after the report is finalized, displayed as a chat-style assistant bubble.
struct ExportSection: View {
    @Bindable var model: ComposerModel
    @State private var copied = false
    @State private var showPreview = false

    var body: some View {
        if model.hasReport {
            AssistantBubble {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Export")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Picker("Format", selection: $model.exportFormat) {
                        ForEach(ExportFormat.allCases) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: model.exportFormat) {
                        copied = false
                    }

                    HStack(spacing: 10) {
                        Button {
                            showPreview = true
                        } label: {
                            Label("Preview", systemImage: "eye")
                                .font(.subheadline.weight(.medium))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        Button {
                            if let text = model.exportFormatted() {
                                UIPasteboard.general.string = text
                                copied = true
                            }
                        } label: {
                            Label(
                                copied ? "Copied!" : "Copy",
                                systemImage: copied ? "checkmark" : "doc.on.doc"
                            )
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(copied ? .green : .accentColor)
                        .controlSize(.small)
                    }
                }
            }
            .sheet(isPresented: $showPreview) {
                ExportPreviewSheet(model: model)
            }
        }
    }
}

// MARK: - Export Preview Sheet

/// Full-screen preview sheet with tabbed view of all three export formats.
/// Each tab shows read-only formatted text with its own copy button.
private struct ExportPreviewSheet: View {
    @Bindable var model: ComposerModel
    @Environment(\.dismiss) private var dismiss
    @State private var previewFormat: ExportFormat = .plainText
    @State private var copiedFormat: ExportFormat?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Format", selection: $previewFormat) {
                    ForEach(ExportFormat.allCases) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                Divider()

                ScrollView {
                    if let text = formattedText(for: previewFormat) {
                        Text(text)
                            .font(.system(.caption, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .textSelection(.enabled)
                    }
                }

                Divider()

                Button {
                    copyFormat(previewFormat)
                } label: {
                    Label(
                        copiedFormat == previewFormat ? "Copied!" : "Copy \(previewFormat.rawValue)",
                        systemImage: copiedFormat == previewFormat ? "checkmark" : "doc.on.doc"
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .tint(copiedFormat == previewFormat ? .green : .accentColor)
                .padding()
            }
            .navigationTitle("Export Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func formattedText(for format: ExportFormat) -> String? {
        let saved = model.exportFormat
        model.exportFormat = format
        let result = model.exportFormatted()
        model.exportFormat = saved
        return result
    }

    private func copyFormat(_ format: ExportFormat) {
        if let text = formattedText(for: format) {
            UIPasteboard.general.string = text
            copiedFormat = format
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                if copiedFormat == format { copiedFormat = nil }
            }
        }
    }
}
