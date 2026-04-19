import SwiftUI

// MARK: - Lounge Detail View

/// Full record for a single lounge plus an entry point to the access checker.
struct LoungeDetailView: View {
    let lounge: Lounge
    @State private var showAccessChecker = false

    var body: some View {
        List {
            locationSection
            featuresSection
            if !lounge.amenities.isEmpty {
                amenitiesSection
            }
            checkerSection
            provenanceSection
        }
        .navigationTitle(lounge.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAccessChecker) {
            AccessCheckerSheet(lounge: lounge)
        }
    }

    // MARK: - Location

    private var locationSection: some View {
        Section("Location") {
            row("Terminal", lounge.terminal)
            row("Concourse", lounge.concourse.rawValue)
            if let level = lounge.level {
                row("Level", level)
            }
            if let gate = lounge.nearestGate {
                row("Nearest gate", gate, mono: true)
            }
            if let entrance = lounge.entranceDescription {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Entrance")
                        .foregroundStyle(.secondary)
                    Text(entrance)
                        .font(.footnote)
                        .foregroundStyle(.primary)
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Features

    private var featuresSection: some View {
        Section("Features") {
            row("Operator", operatorLabel(lounge.operator))
            row("Kind", kindLabel(lounge.kind))
            row("Opening hours", lounge.openingHours)
            if let direct = lounge.directBoarding {
                row("Direct boarding", direct ? "Yes" : "No")
            }
            if let area = lounge.areaSqm {
                row("Area", "\(area) sqm")
            }
            if let cap = lounge.capacityPax {
                row("Capacity", "\(cap) pax")
            }
        }
    }

    // MARK: - Amenities

    private var amenitiesSection: some View {
        Section("Amenities") {
            ForEach(lounge.amenities, id: \.self) { amenity in
                Text(humanise(amenity))
            }
        }
    }

    // MARK: - Checker entry

    private var checkerSection: some View {
        Section {
            Button {
                showAccessChecker = true
            } label: {
                HStack {
                    Image(systemName: "person.crop.circle.badge.questionmark")
                    Text("Check access for a passenger")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    // MARK: - Provenance

    @ViewBuilder
    private var provenanceSection: some View {
        Section("Provenance") {
            HStack {
                Text("Confidence")
                    .foregroundStyle(.secondary)
                Spacer()
                ConfidenceBadge(level: lounge._confidence)
            }
            if let sources = lounge._sources, !sources.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Sources")
                        .foregroundStyle(.secondary)
                    ForEach(sources, id: \.self) { source in
                        Text(source)
                            .font(.footnote)
                            .foregroundStyle(.primary)
                    }
                }
                .padding(.vertical, 4)
            }
            if let notes = lounge._notes {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Notes")
                        .foregroundStyle(.secondary)
                    Text(notes)
                        .font(.footnote)
                        .foregroundStyle(.primary)
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Helpers

    private func row(_ label: String, _ value: String, mono: Bool = false) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Group {
                if mono { Text(value).monospaced() } else { Text(value) }
            }
            .foregroundStyle(.primary)
        }
    }

    private func operatorLabel(_ op: LoungeOperator) -> String {
        switch op {
        case .emirates: return "Emirates"
        case .marhaba: return "Marhaba"
        case .ahlan: return "Ahlan"
        case .plazaPremium: return "Plaza Premium"
        }
    }

    private func kindLabel(_ kind: LoungeKind) -> String {
        switch kind {
        case .first: return "First Class"
        case .business: return "Business Class"
        case .shared: return "Shared"
        case .thirdParty: return "Third party"
        }
    }

    /// Convert "champagneBar" → "Champagne bar" for amenities display.
    private func humanise(_ camel: String) -> String {
        var result = ""
        for (index, char) in camel.enumerated() {
            if index > 0, char.isUppercase {
                result.append(" ")
                result.append(Character(char.lowercased()))
            } else if index == 0 {
                result.append(Character(char.uppercased()))
            } else {
                result.append(char)
            }
        }
        return result
    }
}
