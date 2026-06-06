import SwiftUI

// MARK: - Bay Detail Sheet

/// Full record for a single bay. Mirrors every authoritative field from the
/// underlying JSON (capability, bridges, operational status, source citations,
/// confidence, notes) so crew can audit any value back to its source.
struct BayDetailSheet: View {
    let bay: Bay
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                identifiersSection
                standSection
                capabilitySection
                operationalSection
                provenanceSection
            }
            .navigationTitle(bay.displayLabel)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Identifiers

    private var identifiersSection: some View {
        Section("Identifiers") {
            row("Bay id", bay.bayId, mono: true)
            if let gate = bay.gateId {
                row("Gate id", gate, mono: true)
            }
            if let oldGate = bay.oldGateId {
                row("Old gate", oldGate, mono: true)
            }
            row("Concourse", bay.concourse.rawValue)
            row("Terminal", bay.terminal)
        }
    }

    // MARK: - Stand

    private var standSection: some View {
        Section("Stand") {
            row("Type", bay.isContact ? "Contact" : "Remote")
            row("Stand code", "\(bay.stand.code) (\(bay.stand.code == "F" ? "A380 capable" : "wide-body"))")
            row("DUDA", bay.hasDuda ? "Yes — upper deck bridge" : "No")
            if let direct = bay.stand.directBoarding, direct {
                row("Direct boarding", "Yes — apron walk")
            }
            row("Has stairs", bay.hasStairs ? "Yes" : "No")
        }
    }

    // MARK: - Capability

    private var capabilitySection: some View {
        Section("Aircraft capability") {
            ForEach(bay.aircraftCapability, id: \.self) { type in
                Text(type).monospaced()
            }
            if let count = bay.bridges.totalCount {
                row("Total bridges", "\(count)")
            }
            if let upper = bay.bridges.hasUpperDeckBridge {
                row("Upper deck bridge", upper ? "Yes" : "No")
            }
        }
    }

    // MARK: - Operational

    @ViewBuilder
    private var operationalSection: some View {
        Section("Operational") {
            row("Biometric boarding", bay.biometricBoarding ? "Yes" : "No")
            if let status = bay.operationalStatus {
                row("Status", statusLabel(status))
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
                ConfidenceBadge(level: bay._confidence)
            }
            if let sources = bay._sources, !sources.isEmpty {
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
            if let notes = bay._notes {
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
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Group {
                if mono {
                    Text(value).monospaced()
                } else {
                    Text(value)
                }
            }
            .foregroundStyle(.primary)
        }
    }

    private func statusLabel(_ status: OperationalStatus) -> String {
        switch status {
        case .open: return "Open"
        case .closed: return "Closed"
        case .hybridClosed: return "Hybrid closed"
        }
    }
}

// MARK: - Confidence Badge

struct ConfidenceBadge: View {
    let level: Confidence

    private var color: Color {
        switch level {
        case .high: return .green
        case .medium: return .yellow
        case .low: return .orange
        case .stub: return .red
        }
    }

    var body: some View {
        Text(level.rawValue.capitalized)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }
}
