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
            KiSReportRecord.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
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
}
