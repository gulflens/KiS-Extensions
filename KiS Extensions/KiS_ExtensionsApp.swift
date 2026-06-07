import SwiftUI
import SwiftData

@main
struct KiS_ExtensionsApp: App {
    @State private var appState = AppState()

    init() {
        // Interpret and display all dates/times in Dubai time, independent of
        // the device's (possibly profile-managed, auto) time zone. This makes
        // Calendar.current, TimeZone.current and default DateFormatters resolve
        // to Dubai process-wide.
        if let dubai = TimeZone(identifier: "Asia/Dubai") {
            NSTimeZone.default = dubai
        }

        // Load and validate the We Care rule base at launch (fails loudly if the
        // bundled resource is missing or malformed).
        _ = WeCareRulesLoader.shared
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            AppSettings.self,
            SavedTrip.self,
            SavedCrewAllocation.self,
            PlannedFlight.self,
            PlannedSector.self,
            PlannedDuty.self,
            PolaroidEvidence.self,
            PolaroidStack.self,
        ])
        let cloudConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.Gulflens-Studio.KiS-Extensions")
        )
        let localConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )

        func makeContainer(_ config: ModelConfiguration) throws -> ModelContainer {
            let container = try ModelContainer(for: schema, configurations: [config])
            try Self.ensureDefaultSettings(in: container)
            return container
        }

        do {
            return try makeContainer(cloudConfig)
        } catch {
            print("[KiS] CloudKit container init failed: \(error). Falling back to local-only store (data preserved).")
            do {
                return try makeContainer(localConfig)
            } catch {
                print("[KiS] Local-only init failed: \(error). Wiping store as last resort.")
                Self.removeStoreFiles(at: localConfig.url)
                do {
                    return try makeContainer(localConfig)
                } catch {
                    fatalError("Could not create ModelContainer after recovery: \(error)")
                }
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainAppView()
                .environment(appState)
                .onOpenURL { url in
                    handleOpenURL(url)
                }

        }
        .modelContainer(sharedModelContainer)
    }

    private func handleOpenURL(_ url: URL) {
        // Handle custom URL scheme: kisextensions://import
        if url.scheme == "kisextensions" || url.scheme == "crewpositions" {
            handleURLSchemeImport(url)
            return
        }

        // Handle .json file opens
        let importService = DataImportService()
        do {
            let trips = try importService.importFromFile(url)
            appState.loadTrips(trips)
        } catch {
            appState.showError(error.localizedDescription)
        }
    }

    /// Handle kisextensions:// URL scheme (also supports legacy crewpositions://)
    /// kisextensions://import — reads clipboard and imports
    /// kisextensions://import?data=<base64> — imports inline data
    private func handleURLSchemeImport(_ url: URL) {
        let importService = DataImportService()

        // Check for inline base64 data parameter
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let dataParam = components.queryItems?.first(where: { $0.name == "data" })?.value,
           let decoded = Data(base64Encoded: dataParam) {
            do {
                let trips = try importService.importFromSharedData(decoded)
                appState.loadTrips(trips)
                return
            } catch {
                appState.showError(error.localizedDescription)
                return
            }
        }

        // Default: read from clipboard (triggered by Shortcut)
        do {
            let trips = try importService.importFromClipboard()
            appState.loadTrips(trips)
        } catch {
            appState.showError(error.localizedDescription)
        }
    }

    private static func removeStoreFiles(at url: URL) {
        let fm = FileManager.default
        try? fm.removeItem(at: url)
        let path = url.path(percentEncoded: false)
        try? fm.removeItem(atPath: path + "-wal")
        try? fm.removeItem(atPath: path + "-shm")
    }

    private static func ensureDefaultSettings(in container: ModelContainer) throws {
        var descriptor = FetchDescriptor<AppSettings>()
        descriptor.fetchLimit = 1

        guard try container.mainContext.fetch(descriptor).isEmpty else {
            return
        }

        container.mainContext.insert(AppSettings())
        try container.mainContext.save()
    }
}

// MARK: - Dubai Time Zone

extension TimeZone {
    /// The app operates entirely in Dubai time, independent of the device's
    /// (possibly profile-managed) zone. Use this anywhere the device zone would
    /// otherwise leak in via `.current` / `TimeZone.current`, which — unlike
    /// `Calendar.current` and default formatters — is not affected by setting
    /// `NSTimeZone.default`.
    static let dubai = TimeZone(identifier: "Asia/Dubai")!
}
