import SwiftUI

struct TextInputSheet: View {
    @Binding var text: String
    @Environment(\.dismiss) private var dismiss
    let onImport: (String) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Paste your JSON trip data below:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextEditor(text: $text)
                    .font(.system(.body, design: .monospaced))
                    .border(Color.secondary.opacity(0.3))
                    .padding(.horizontal)
            }
            .padding(.vertical)
            .navigationTitle("JSON Input")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Import") {
                        onImport(text)
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
