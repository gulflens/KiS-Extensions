import SwiftUI

// MARK: - DXB Airport Mini-App

/// Read-only reference for DXB bays, gates, lounges, and APM transit. Loads
/// authoritative data from the bundle once at launch via `DXBDataStore`.
struct DXBAirportApp: View {
    @Environment(AppState.self) private var appState
    @State private var dataStore = DXBDataStore()

    var body: some View {
        @Bindable var appState = appState

        NavigationStack(path: $appState.dxbAirportPath) {
            DXBAirportHomeView()
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
        }
        .environment(dataStore)
    }
}
