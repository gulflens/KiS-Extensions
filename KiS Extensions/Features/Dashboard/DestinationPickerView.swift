import SwiftUI

// MARK: - Destination Picker

/// Region-grouped station picker used by the dashboard destination clock.
struct DestinationPickerView: View {
    @Binding var selectedCode: String
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private struct RegionGroup: Identifiable {
        let region: String
        let codes: [String]
        var id: String { region }
    }

    private static let allRegions: [RegionGroup] = {
        var grouped: [String: [String]] = [:]
        for code in StationTimezones.allCodes {
            guard let tz = StationTimezones.timeZone(for: code) else { continue }
            let region = tz.identifier.components(separatedBy: "/").first ?? "Other"
            let display: String
            switch region {
            case "America": display = "Americas"
            case "Indian": display = "Indian Ocean"
            default: display = region
            }
            grouped[display, default: []].append(code)
        }
        return grouped
            .map { RegionGroup(region: $0.key, codes: $0.value.sorted()) }
            .sorted { $0.region < $1.region }
    }()

    private var filteredRegions: [RegionGroup] {
        guard !searchText.isEmpty else { return Self.allRegions }
        let query = searchText.uppercased()
        return Self.allRegions.compactMap { group in
            let filtered = group.codes.filter { code in
                code.contains(query) ||
                (StationTimezones.displayName(for: code)?.uppercased().contains(query) ?? false)
            }
            guard !filtered.isEmpty else { return nil }
            return RegionGroup(region: group.region, codes: filtered)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredRegions) { group in
                    Section(group.region) {
                        ForEach(group.codes, id: \.self) { code in
                            Button {
                                selectedCode = code
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    Text(code)
                                        .font(.system(.body, design: .monospaced))
                                        .fontWeight(.medium)
                                    if let name = StationTimezones.displayName(for: code) {
                                        Text(name)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if code == selectedCode {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.green)
                                            .fontWeight(.semibold)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search by code or city")
            .navigationTitle("Select Destination")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear") {
                        selectedCode = ""
                        dismiss()
                    }
                    .disabled(selectedCode.isEmpty)
                }
            }
        }
    }
}
