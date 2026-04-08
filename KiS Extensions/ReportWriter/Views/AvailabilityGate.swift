import SwiftUI
import FoundationModels

struct AvailabilityGate<Content: View>: View {
    private let model = SystemLanguageModel.default
    @ViewBuilder let content: () -> Content

    var body: some View {
        switch model.availability {
        case .available:
            content()

        case .unavailable(.deviceNotEligible):
            ContentUnavailableView(
                "Device Not Supported",
                systemImage: "exclamationmark.triangle",
                description: Text("This device doesn't support on-device AI. Manual entry coming in a future update.")
            )

        case .unavailable(.appleIntelligenceNotEnabled):
            ContentUnavailableView {
                Label("Apple Intelligence Required", systemImage: "brain")
            } description: {
                Text("Apple Intelligence must be enabled to use KiS report generation.")
            } actions: {
                Button("Enable in Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(.borderedProminent)
            }

        case .unavailable(.modelNotReady):
            VStack(spacing: 16) {
                ProgressView()
                    .controlSize(.large)
                Text("AI model is preparing.")
                    .font(.headline)
                Text("This happens once after install.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

        default:
            ContentUnavailableView(
                "AI Unavailable",
                systemImage: "exclamationmark.triangle",
                description: Text("The on-device AI model is currently unavailable.")
            )
        }
    }
}
