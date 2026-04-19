import SwiftUI
import SwiftData

@main
struct KiS_ExtensionsApp: App {
    @State private var appState = AppState()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            AppSettings.self,
            SavedTrip.self,
            SavedCrewAllocation.self,
            PlannedFlight.self,
            PlannedSector.self,
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
            print("[KiS] CloudKit container init failed: \(error). Wiping store and retrying.")
            Self.removeStoreFiles(at: cloudConfig.url)
            do {
                return try makeContainer(cloudConfig)
            } catch {
                print("[KiS] CloudKit retry failed: \(error). Falling back to local-only store.")
                do {
                    return try makeContainer(localConfig)
                } catch {
                    fatalError("Local-only fallback also failed: \(error)")
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
