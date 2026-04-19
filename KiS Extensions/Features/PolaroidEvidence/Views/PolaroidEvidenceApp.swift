import SwiftUI
import SwiftData

// MARK: - PolaroidEvidenceApp

/// Mini-app root. Mirrors the FlightPlannerApp pattern: own NavigationStack
/// rooted in `appState.polaroidEvidencePath`, leading "Dashboard" toolbar
/// button.
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
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        appState.returnToDashboard()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "square.grid.2x2")
                            Text("Dashboard")
                        }
                    }
                }

            }
            .onAppear {
                if evidenceStore == nil {
                    evidenceStore = PolaroidEvidenceStore(context: modelContext)
                }
            }
        }
    }
}
