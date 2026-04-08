import SwiftUI
import SwiftData

struct ReportWriterRootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var model = ComposerModel()
    @State private var speechService = SpeechRecognitionService()

    @State private var showHistory = false
    @State private var showTemplatePicker = false
    @State private var showAgentTuning = false
    @State private var showDiagnostic = false

    var body: some View {
        AvailabilityGate {
            VStack(spacing: 0) {
                // Chat thread
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            if model.isComposerEmpty && !speechService.isRecording {
                                emptyState
                                    .transition(.opacity)
                            }

                            // User message bubble (shown after send)
                            if !model.committedBullets.isEmpty {
                                UserBubble(text: model.committedBullets)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .bottom).combined(with: .opacity),
                                        removal: .opacity
                                    ))
                            }

                            // Classifying indicator
                            if model.isClassifying {
                                AssistantBubble {
                                    TypingIndicator()
                                }
                                .transition(.opacity)
                            }

                            // Classification result
                            if model.classifiedPath != nil {
                                CategorySection(model: model)
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                            }

                            // Report (streaming or final)
                            ReportSection(model: model)

                            // Export
                            if model.hasReport {
                                ExportSection(model: model)
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                            }

                            // Scroll anchor
                            Color.clear
                                .frame(height: 1)
                                .id("bottom")
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                        .padding(.bottom, 12)
                    }
                    .background(Color(red: 242/255, green: 242/255, blue: 242/255))
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: model.classifiedPath?.displayPath) {
                        scrollToBottom(proxy)
                    }
                    .onChange(of: model.hasReport) {
                        scrollToBottom(proxy)
                    }
                    .onChange(of: model.partialDraft?.descriptionBullets?.count) {
                        scrollToBottom(proxy)
                    }
                    .onChange(of: model.isClassifying) {
                        scrollToBottom(proxy)
                    }
                }

                // Input bar
                InputBar(
                    model: model,
                    speechService: speechService
                )
            }
            .overlay(alignment: .top) {
                errorBanner
            }
            .animation(.easeInOut(duration: 0.3), value: model.classifiedPath?.displayPath)
            .animation(.easeInOut(duration: 0.3), value: model.hasReport)
            .animation(.easeInOut(duration: 0.3), value: model.isClassifying)
            .onAppear {
                model.modelContext = modelContext
                speechService.requestAuthorization()
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("KiS Reports")
                        .font(.headline)
                        .onTapGesture(count: 3) {
                            showAgentTuning = true
                        }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 4) {
                        Button {
                            showDiagnostic = true
                        } label: {
                            Image(systemName: "stethoscope")
                        }

                        Button {
                            showHistory = true
                        } label: {
                            Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                        }
                    }
                }
            }
            .sheet(isPresented: $showHistory) {
                DraftHistoryView { record in
                    model.loadFrom(record: record)
                    showHistory = false
                }
            }
            .sheet(isPresented: $showTemplatePicker) {
                TemplatePickerSheet { template in
                    model.applyTemplate(template)
                }
            }
            .sheet(isPresented: $showAgentTuning) {
                AgentTuningView()
            }
            .sheet(isPresented: $showDiagnostic) {
                ClassifierDiagnosticView()
            }
        }
        .navigationTitle("KiS Reports")
    }

    // MARK: - Helpers

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.25)) {
            proxy.scrollTo("bottom", anchor: .bottom)
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
                .frame(height: 60)

            Image(systemName: "sparkles")
                .font(.system(size: 44))
                .foregroundStyle(.tint.opacity(0.4))

            Text("KiS Report Assistant")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)

            Text("Describe an inflight event using text or voice, and the AI will classify and draft your KiS report.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                showTemplatePicker = true
            } label: {
                Label("Start from template", systemImage: "text.badge.plus")
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.bordered)
            .tint(.accentColor)

            Spacer()
                .frame(height: 60)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Error banner

    @ViewBuilder
    private var errorBanner: some View {
        if let error = model.lastError ?? speechService.error {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption2)
                Text(error)
                    .font(.caption.weight(.medium))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.red.gradient, in: Capsule())
            .padding(.top, 4)
            .transition(.move(edge: .top).combined(with: .opacity))
            .onTapGesture {
                model.dismissError()
            }
        }
    }
}

// MARK: - User Bubble

private struct UserBubble: View {
    let text: String

    var body: some View {
        HStack(alignment: .top) {
            Spacer(minLength: 48)

            Text(text)
                .font(.body)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(red: 220/255, green: 245/255, blue: 220/255))
                )
        }
    }
}

// MARK: - Assistant Bubble

struct AssistantBubble<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // AI avatar
            Circle()
                .fill(.tint.opacity(0.12))
                .frame(width: 28, height: 28)
                .overlay {
                    Image(systemName: "sparkle")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.tint)
                }

            VStack(alignment: .leading, spacing: 8) {
                content
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white)
            )

            Spacer(minLength: 0)
        }
    }
}

// MARK: - Typing Indicator

/// Animated three-dot "thinking" indicator shown during classification.
private struct TypingIndicator: View {
    @State private var phase = 0.0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(.secondary)
                    .frame(width: 7, height: 7)
                    .offset(y: animationOffset(for: index))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                phase = 1.0
            }
        }
    }

    private func animationOffset(for index: Int) -> CGFloat {
        let delay = Double(index) * 0.15
        let progress = max(0, min(1, phase - delay))
        return -4 * sin(progress * .pi)
    }
}

// MARK: - Input Bar

private struct InputBar: View {
    @Bindable var model: ComposerModel
    @Bindable var speechService: SpeechRecognitionService
    @FocusState private var isFocused: Bool

    private var placeholderText: String {
        if let template = model.activeTemplate {
            return template.bulletPlaceholders.first ?? "Describe the event..."
        }
        return "Describe the event..."
    }

    /// True when the text field has content that can be submitted.
    private var hasText: Bool {
        !model.rawBullets.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            // Action chips above input
            actionChips
                .padding(.horizontal, 14)

            // Unified input container
            VStack(spacing: 0) {
                // Text area
                textArea

                // Bottom toolbar row inside the container
                HStack {
                    // Left-side action buttons
                    if model.canWriteReport && !model.isWriting && !model.hasReport {
                        chipButton(
                            title: "Write report",
                            icon: "doc.text",
                            style: .prominent
                        ) {
                            Task { await model.generateReport() }
                        }
                    } else if model.hasReport {
                        chipButton(
                            title: "New report",
                            icon: "arrow.counterclockwise",
                            style: .plain
                        ) {
                            model.reset()
                        }
                    }

                    Spacer()

                    // Right-side buttons
                    HStack(spacing: 4) {
                        micButton
                        sendButton
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 8)
                .padding(.top, 4)
            }
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        speechService.isRecording ? Color.red.opacity(0.5) : Color(.separator).opacity(0.2),
                        lineWidth: speechService.isRecording ? 2 : 1
                    )
            )
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .background(Color(red: 242/255, green: 242/255, blue: 242/255))
    }

    // MARK: - Action chips

    @ViewBuilder
    private var actionChips: some View {
        EmptyView()
    }

    // MARK: - Text area

    private var textArea: some View {
        ZStack(alignment: .topLeading) {
            // Live transcription preview
            if speechService.isRecording && !speechService.transcribedText.isEmpty {
                Text(speechService.transcribedText)
                    .font(.body)
                    .foregroundStyle(.primary.opacity(0.5))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            TextField(
                speechService.isRecording ? "Listening..." : placeholderText,
                text: $model.rawBullets,
                axis: .vertical
            )
            .lineLimit(1...8)
            .textFieldStyle(.plain)
            .font(.body)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .focused($isFocused)
            .disabled(speechService.isRecording)
        }
    }

    // MARK: - Mic button

    private var micButton: some View {
        Button {
            toggleRecording()
        } label: {
            ZStack {
                if speechService.isRecording {
                    Circle()
                        .fill(.red.opacity(0.15))
                        .frame(width: 32, height: 32)

                    Image(systemName: "stop.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.red)
                } else {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(speechService.isAuthorized ? Color.secondary : Color.secondary.opacity(0.3))
                        .frame(width: 32, height: 32)
                }
            }
        }
        .disabled(!speechService.isAuthorized && !speechService.isRecording)
    }

    // MARK: - Send button

    private var sendButton: some View {
        Button {
            isFocused = false
            Task { await model.classify() }
        } label: {
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 32))
                .foregroundStyle(model.canClassify ? Color.accentColor : Color.secondary.opacity(0.3))
        }
        .disabled(!model.canClassify)
    }

    // MARK: - Chip button

    private enum ChipStyle { case prominent, plain }

    private func chipButton(
        title: String,
        icon: String,
        style: ChipStyle,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(
                        style == .prominent
                            ? AnyShapeStyle(.tint.opacity(0.12))
                            : AnyShapeStyle(.secondary.opacity(0.1))
                    )
                )
                .foregroundStyle(style == .prominent ? Color.accentColor : Color.secondary)
        }
    }

    // MARK: - Recording

    private func toggleRecording() {
        if speechService.isRecording {
            // Commit transcribed text and stop
            if !speechService.transcribedText.isEmpty {
                let separator = model.rawBullets.isEmpty ? "" : "\n"
                model.rawBullets += separator + speechService.transcribedText
            }
            speechService.stopRecording()
        } else {
            speechService.startRecording()
        }
    }
}
