import SwiftUI

/// A searchable grid of incident templates. Presented as a sheet from the composer
/// when the composer is empty. Tapping a card calls the onSelect closure.
struct TemplatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var onSelect: (IncidentTemplate) -> Void

    private var filteredTemplates: [IncidentTemplate] {
        if searchText.isEmpty { return TemplateLibrary.all }
        let query = searchText.lowercased()
        return TemplateLibrary.all.filter {
            $0.displayName.lowercased().contains(query)
                || $0.categoryDisplayPath.lowercased().contains(query)
        }
    }

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(filteredTemplates) { template in
                        TemplateCard(template: template) {
                            onSelect(template)
                            dismiss()
                        }
                    }
                }
                .padding()
            }
            .searchable(text: $searchText, prompt: "Search templates")
            .navigationTitle("Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Template card

private struct TemplateCard: View {
    let template: IncidentTemplate
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: template.iconName)
                    .font(.title2)
                    .foregroundStyle(priorityColor)

                Text(template.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)

                Text(template.categoryDisplayPath)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private var priorityColor: Color {
        switch template.suggestedPriority {
        case "Critical": return .red
        case "Follow up required": return .orange
        default: return .blue
        }
    }
}
