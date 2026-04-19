import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsArray: [AppSettings]

    // MARK: - Snapshot for discard

    @State private var snapshot: SettingsSnapshot?
    @State private var selectedTab: SettingsTab = .general
    @State private var showSeedConfirm = false
    @State private var showSeedDone = false
    @State private var showDeleteConfirm = false
    @State private var showDeleteDone = false
    @State private var deleteResultMessage = ""

    private var settings: AppSettings {
        if let existing = settingsArray.first {
            return existing
        }
        let newSettings = AppSettings()
        modelContext.insert(newSettings)
        return newSettings
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Tab Picker
            Picker("", selection: $selectedTab) {
                ForEach(SettingsTab.allCases) { tab in
                    Text(tab.label).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            // MARK: - Tab Content
            Group {
                switch selectedTab {
                case .general:
                    generalTab
                case .allocatePositions:
                    allocatePositionsTab
                case .polaroidEvidence:
                    polaroidEvidenceTab
                case .diagnostics:
                    diagnosticsTab
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    try? modelContext.save()
                    appState.returnToDashboard()
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Discard") {
                    restoreSnapshot()
                    appState.returnToDashboard()
                }
            }
        }
        .onAppear {
            takeSnapshot()
        }
        .confirmationDialog("Delete data older than:", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("1 month", role: .destructive) { deleteData(olderThan: 1) }
            Button("3 months", role: .destructive) { deleteData(olderThan: 3) }
            Button("6 months", role: .destructive) { deleteData(olderThan: 6) }
            Button("12 months", role: .destructive) { deleteData(olderThan: 12) }
            Button("All data", role: .destructive) { deleteData(olderThan: nil) }
            Button("Cancel", role: .cancel) { }
        }
        .alert("Data deleted", isPresented: $showDeleteDone) {
            Button("OK") { }
        } message: {
            Text(deleteResultMessage)
        }
    }

    // MARK: - General Tab

    private var generalTab: some View {
        Form {
            Section("Display") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Appearance")
                    Picker("", selection: appearanceBinding) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }

            Section("Flight Planner") {
                Toggle("Open all cards simultaneously", isOn: binding(for: \.openAllCardsSimultaneously))
            }

            Section("Data Management") {
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Label("Delete old data", systemImage: "trash")
                }
            }
        }
        .scrollContentBackground(.hidden)
    }

    // MARK: - Allocate Positions Tab

    private var allocatePositionsTab: some View {
        Form {
            Section("Display") {
                Toggle("Additional Info", isOn: binding(for: \.additionalInfo))
                Toggle("Ramadan", isOn: binding(for: \.ramadan))
                Toggle("Languages and PAs", isOn: binding(for: \.languagesAndPAs))
                Toggle("Positions Badges", isOn: binding(for: \.positionsBadges))
                Toggle("Clickable Headers", isOn: binding(for: \.clickableHeaders))
            }

            Section("Behavior") {
                Toggle("Break Auto Correction", isOn: binding(for: \.breakAutoCorrection))
                Toggle("Repeated Positions Highlight", isOn: binding(for: \.repeatedPositionsHighlight))
            }
        }
        .scrollContentBackground(.hidden)
    }

    // MARK: - Polaroid Evidence Tab

    private var polaroidEvidenceTab: some View {
        Form {
            Section("Editing") {
                Toggle("Auto-save changes", isOn: binding(for: \.polaroidAutoSave))
            }
        }
        .scrollContentBackground(.hidden)
    }

    // MARK: - Diagnostics Tab

    private var diagnosticsTab: some View {
        Form {
            #if DEBUG
            Section {
                Button {
                    showSeedConfirm = true
                } label: {
                    HStack {
                        Image(systemName: "ladybug")
                        Text("Seed polaroid test data")
                    }
                }
                .confirmationDialog(
                    "Seed test data?",
                    isPresented: $showSeedConfirm,
                    titleVisibility: .visible
                ) {
                    Button("Seed") {
                        let store = PolaroidEvidenceStore(context: modelContext)
                        store.seedTestData()
                        showSeedDone = true
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This inserts 5 sample polaroids for testing.")
                }
                .alert("Done", isPresented: $showSeedDone) {
                    Button("OK") {}
                } message: {
                    Text("Test polaroids have been added.")
                }
            } header: {
                Text("Polaroid Evidence")
            }
            #endif

            Section {
                Text("The roster diagnose tool is available inside the Import Roster view when an import fails.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Roster Import")
            }
        }
        .scrollContentBackground(.hidden)
    }

    // MARK: - Snapshot

    private func takeSnapshot() {
        let s = settings
        snapshot = SettingsSnapshot(
            appearanceModeRaw: s.appearanceModeRaw,
            openAllCardsSimultaneously: s.openAllCardsSimultaneously,
            polaroidAutoSave: s.polaroidAutoSave,
            additionalInfo: s.additionalInfo,
            ramadan: s.ramadan,
            languagesAndPAs: s.languagesAndPAs,
            breakAutoCorrection: s.breakAutoCorrection,
            repeatedPositionsHighlight: s.repeatedPositionsHighlight,
            positionsBadges: s.positionsBadges,
            clickableHeaders: s.clickableHeaders
        )
    }

    private func restoreSnapshot() {
        guard let snap = snapshot else { return }
        let s = settings
        s.appearanceModeRaw = snap.appearanceModeRaw
        s.openAllCardsSimultaneously = snap.openAllCardsSimultaneously
        s.polaroidAutoSave = snap.polaroidAutoSave
        s.additionalInfo = snap.additionalInfo
        s.ramadan = snap.ramadan
        s.languagesAndPAs = snap.languagesAndPAs
        s.breakAutoCorrection = snap.breakAutoCorrection
        s.repeatedPositionsHighlight = snap.repeatedPositionsHighlight
        s.positionsBadges = snap.positionsBadges
        s.clickableHeaders = snap.clickableHeaders
        try? modelContext.save()
    }

    // MARK: - Data Management

    private func deleteData(olderThan months: Int?) {
        let cutoff = months.flatMap {
            Calendar.current.date(byAdding: .month, value: -$0, to: Date())
        }

        let tripCount = deleteModels(SavedTrip.self, cutoff: cutoff, dateKeyPath: \.savedAt)
        let flightCount = deleteModels(PlannedFlight.self, cutoff: cutoff, dateKeyPath: \.createdAt)
        let stackCount = deleteModels(PolaroidStack.self, cutoff: cutoff, dateKeyPath: \.createdAt)

        try? modelContext.save()

        let total = tripCount + flightCount + stackCount
        if total == 0 {
            deleteResultMessage = "No data found matching the selected period."
        } else {
            var parts: [String] = []
            if tripCount > 0 { parts.append("\(tripCount) trip\(tripCount == 1 ? "" : "s")") }
            if flightCount > 0 { parts.append("\(flightCount) flight\(flightCount == 1 ? "" : "s")") }
            if stackCount > 0 { parts.append("\(stackCount) evidence stack\(stackCount == 1 ? "" : "s")") }
            deleteResultMessage = "Deleted \(parts.joined(separator: ", "))."
        }
        showDeleteDone = true
    }

    private func deleteModels<T: PersistentModel>(
        _ type: T.Type,
        cutoff: Date?,
        dateKeyPath: KeyPath<T, Date>
    ) -> Int {
        guard let all = try? modelContext.fetch(FetchDescriptor<T>()) else { return 0 }
        let targets = cutoff.map { c in all.filter { $0[keyPath: dateKeyPath] < c } } ?? all
        targets.forEach { modelContext.delete($0) }
        return targets.count
    }

    // MARK: - Bindings

    private var appearanceBinding: Binding<AppearanceMode> {
        Binding(
            get: { settings.appearanceMode },
            set: { settings.appearanceMode = $0 }
        )
    }

    private func binding(for keyPath: ReferenceWritableKeyPath<AppSettings, Bool>) -> Binding<Bool> {
        Binding(
            get: { settings[keyPath: keyPath] },
            set: { settings[keyPath: keyPath] = $0 }
        )
    }
}

// MARK: - Settings Tab

private enum SettingsTab: String, CaseIterable, Identifiable {
    case general
    case allocatePositions
    case polaroidEvidence
    case diagnostics

    var id: String { rawValue }

    var label: String {
        switch self {
        case .general: "General"
        case .allocatePositions: "Allocate Positions"
        case .polaroidEvidence: "Evidence"
        case .diagnostics: "Diagnostics"
        }
    }
}

// MARK: - Settings Snapshot

private struct SettingsSnapshot {
    let appearanceModeRaw: Int
    let openAllCardsSimultaneously: Bool
    let polaroidAutoSave: Bool
    let additionalInfo: Bool
    let ramadan: Bool
    let languagesAndPAs: Bool
    let breakAutoCorrection: Bool
    let repeatedPositionsHighlight: Bool
    let positionsBadges: Bool
    let clickableHeaders: Bool
}
