import SwiftUI

struct DataInputView: View {
    @Environment(AppState.self) private var appState
    @State private var showPortalBrowser = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 8) {
                Image(systemName: "airplane")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                Text("KiS Extensions")
                    .font(.largeTitle.bold())
                Text("Cabin crew position allocation")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 16) {
                Button {
                    showPortalBrowser = true
                } label: {
                    Label("Open Crew Portal", systemImage: "globe")
                        .frame(maxWidth: 340)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Text("Log in to the portal, load your trips, then tap Extract Data.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 340)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("KiS Extensions")
        .fullScreenCover(isPresented: $showPortalBrowser) {
            PortalBrowserView()
        }
    }
}
