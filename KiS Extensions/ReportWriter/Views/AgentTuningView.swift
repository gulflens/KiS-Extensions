import SwiftUI
import UniformTypeIdentifiers

/// Developer-only view for overriding the AI prompt instructions used by KiSAgent.
/// Accessed via triple-tap on the "KiS Reports" navigation title.
/// All overrides are stored in UserDefaults (per-device, not synced).
struct AgentTuningView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var classifierText: String = ""
    @State private var writerText: String = ""
    @State private var showExporter = false
    @State private var showImporter = false
    @State private var showResetConfirm = false
    @State private var saveConfirmed = false

    /// True when edits differ from the currently active instructions.
    private var hasChanges: Bool {
        classifierText != KiSPrompts.activeClassifierInstructions ||
        writerText != KiSPrompts.activeWriterInstructions
    }

    /// True when any override is active (differs from compiled default).
    private var hasActiveOverrides: Bool {
        UserDefaults.standard.string(forKey: KiSPrompts.classifierOverrideKey)?.isEmpty == false ||
        UserDefaults.standard.string(forKey: KiSPrompts.writerOverrideKey)?.isEmpty == false
    }

    var body: some View {
        NavigationStack {
            Form {
                overrideBanner

                Section {
                    TextEditor(text: $classifierText)
                        .font(.system(.caption, design: .monospaced))
                        .frame(minHeight: 200)
                } header: {
                    Label("Classifier Instructions", systemImage: "tag")
                } footer: {
                    Text("Used when auto-classifying crew notes into category paths.")
                }

                Section {
                    TextEditor(text: $writerText)
                        .font(.system(.caption, design: .monospaced))
                        .frame(minHeight: 280)
                } header: {
                    Label("Writer Instructions", systemImage: "pencil.and.outline")
                } footer: {
                    Text("Used when generating the structured KiS report draft.")
                }

                transferSection
            }
            .navigationTitle("Agent Tuning")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(saveConfirmed ? "Saved" : "Save") {
                        save()
                    }
                    .disabled(!hasChanges)
                    .bold()
                }
            }
            .onAppear { loadCurrent() }
            .confirmationDialog(
                "Reset to Defaults",
                isPresented: $showResetConfirm,
                titleVisibility: .visible
            ) {
                Button("Reset Both Prompts", role: .destructive) {
                    resetToDefaults()
                }
            } message: {
                Text("This will remove all custom overrides and revert to the compiled default instructions.")
            }
            .fileExporter(
                isPresented: $showExporter,
                document: InstructionsDocument(
                    classifier: classifierText,
                    writer: writerText
                ),
                contentType: .json,
                defaultFilename: "kis-agent-instructions"
            ) { _ in }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [.json]
            ) { result in
                importInstructions(result: result)
            }
        }
    }

    // MARK: - Override banner

    @ViewBuilder
    private var overrideBanner: some View {
        if hasActiveOverrides {
            Section {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Custom overrides are active. The agent is not using compiled defaults.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
        }
    }

    // MARK: - Transfer section

    private var transferSection: some View {
        Section {
            Button {
                showExporter = true
            } label: {
                Label("Export Instructions", systemImage: "square.and.arrow.up")
            }

            Button {
                showImporter = true
            } label: {
                Label("Import Instructions", systemImage: "square.and.arrow.down")
            }

            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
            }
            .disabled(!hasActiveOverrides)
        } header: {
            Label("Transfer", systemImage: "arrow.left.arrow.right")
        }
    }

    // MARK: - Actions

    private func loadCurrent() {
        classifierText = KiSPrompts.activeClassifierInstructions
        writerText = KiSPrompts.activeWriterInstructions
    }

    private func save() {
        // Only write overrides if they differ from the compiled defaults.
        if classifierText == KiSPrompts.classifierInstructionsDefault {
            UserDefaults.standard.removeObject(forKey: KiSPrompts.classifierOverrideKey)
        } else {
            UserDefaults.standard.set(classifierText, forKey: KiSPrompts.classifierOverrideKey)
        }

        if writerText == KiSPrompts.writerInstructionsDefault {
            UserDefaults.standard.removeObject(forKey: KiSPrompts.writerOverrideKey)
        } else {
            UserDefaults.standard.set(writerText, forKey: KiSPrompts.writerOverrideKey)
        }

        saveConfirmed = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            saveConfirmed = false
        }
    }

    private func resetToDefaults() {
        UserDefaults.standard.removeObject(forKey: KiSPrompts.classifierOverrideKey)
        UserDefaults.standard.removeObject(forKey: KiSPrompts.writerOverrideKey)
        loadCurrent()
    }

    private func importInstructions(result: Result<URL, Error>) {
        guard case .success(let url) = result,
              url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        guard let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] else { return }

        if let classifier = json["classifier"] { classifierText = classifier }
        if let writer = json["writer"] { writerText = writer }
    }
}

// MARK: - File transfer types

private struct InstructionsDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    let classifier: String
    let writer: String

    init(classifier: String, writer: String) {
        self.classifier = classifier
        self.writer = writer
    }

    nonisolated init(configuration: ReadConfiguration) throws {
        let data = configuration.file.regularFileContents ?? Data()
        let json = try JSONSerialization.jsonObject(with: data) as? [String: String] ?? [:]
        self.classifier = json["classifier"] ?? ""
        self.writer = json["writer"] ?? ""
    }

    nonisolated func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let dict: [String: String] = ["classifier": classifier, "writer": writer]
        let data = try JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys])
        return FileWrapper(regularFileWithContents: data)
    }
}
