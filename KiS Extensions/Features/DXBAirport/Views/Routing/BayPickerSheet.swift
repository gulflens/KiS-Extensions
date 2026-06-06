import SwiftUI

// MARK: - Bay Picker Sheet

/// Reusable searchable bay/gate picker. Shared between origin and destination
/// pickers in the route planner. Reuses `DXBDataStore.search` and `BayRowView`
/// so behaviour matches the home-screen lookup.
struct BayPickerSheet: View {
    let title: String
    let onSelect: (Bay) -> Void

    @Environment(DXBDataStore.self) private var dataStore
    @Environment(\.dismiss) private var dismiss
    @State private var query: String = ""

    private var results: [(concourse: Concourse, bays: [Bay])] {
        dataStore.grouped(dataStore.search(query))
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(results, id: \.concourse) { group in
                    Section {
                        ForEach(group.bays) { bay in
                            Button {
                                onSelect(bay)
                                dismiss()
                            } label: {
                                BayRowView(bay: bay)
                            }
                            .buttonStyle(.plain)
                        }
                    } header: {
                        Text("Concourse \(group.concourse.rawValue)")
                            .font(.subheadline.weight(.semibold))
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search bay, gate, or old gate"
            )
            .textInputAutocapitalization(.characters)
            .autocorrectionDisabled()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
