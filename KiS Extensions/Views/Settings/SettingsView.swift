import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsArray: [AppSettings]

    private var settings: AppSettings {
        if let existing = settingsArray.first {
            return existing
        }
        let newSettings = AppSettings()
        modelContext.insert(newSettings)
        return newSettings
    }

    var body: some View {
        Form {
            // MARK: - General
            Section("Display") {
                Picker("Appearance", selection: appearanceBinding) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
            }

            // MARK: - Crew Positions
            Section("Crew Positions — Display") {
                Toggle("Additional Info", isOn: binding(for: \.additionalInfo))
                Toggle("Ramadan", isOn: binding(for: \.ramadan))
                Toggle("Languages and PAs", isOn: binding(for: \.languagesAndPAs))
                Toggle("Positions Badges", isOn: binding(for: \.positionsBadges))
                Toggle("Clickable Headers", isOn: binding(for: \.clickableHeaders))
            }

            Section("Crew Positions — Behavior") {
                Toggle("Break Auto Correction", isOn: binding(for: \.breakAutoCorrection))
                Toggle("Repeated Positions Highlight", isOn: binding(for: \.repeatedPositionsHighlight))
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }

    }

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
