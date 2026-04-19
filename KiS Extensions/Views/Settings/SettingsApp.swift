import SwiftUI

// MARK: - Settings Mini-App

struct SettingsApp: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            SettingsView()
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
    }
}
