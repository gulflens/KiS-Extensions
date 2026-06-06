import SwiftUI
import SwiftData

// MARK: - PolaroidEvidenceApp

/// Mini-app root. Mirrors the FlightPlannerApp pattern: own NavigationStack
/// rooted in `appState.polaroidEvidencePath`.
struct PolaroidEvidenceApp: View {

    // MARK: Environment

    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    // MARK: Stores

    @State private var evidenceStore: PolaroidEvidenceStore?

    // MARK: Body

    var body: some View {
        @Bindable var appState = appState

        NavigationStack(path: $appState.polaroidEvidencePath) {
            Group {
                if let evidenceStore {
                    DesktopView(evidenceStore: evidenceStore)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(EvidenceTheme.desktopBackground)
                }
            }
            .navigationTitle("Polaroid Evidence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                if evidenceStore == nil {
                    evidenceStore = PolaroidEvidenceStore(context: modelContext)
                }
            }
        }
    }
}
