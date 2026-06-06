import SwiftUI

// MARK: - Bay Row

struct BayRowView: View {
    let bay: Bay

    private var concourseColor: Color {
        switch bay.concourse {
        case .A: return Color(red: 0.15, green: 0.35, blue: 0.70)
        case .B: return Color(red: 0.10, green: 0.55, blue: 0.42)
        case .C: return Color(red: 0.75, green: 0.45, blue: 0.10)
        case .D: return Color(red: 0.50, green: 0.25, blue: 0.65)   // T1 — purple
        case .F: return Color(red: 0.45, green: 0.45, blue: 0.50)   // T2 — slate
        case .G: return Color(red: 0.55, green: 0.40, blue: 0.20)   // Apron G — bronze
        case .E: return Color(red: 0.10, green: 0.45, blue: 0.55)   // Apron E — teal
        case .H: return Color(red: 0.70, green: 0.55, blue: 0.10)   // Apron H — royal gold
        case .Q: return Color(red: 0.55, green: 0.20, blue: 0.20)   // Apron Q — maintenance red
        case .S: return Color(red: 0.40, green: 0.40, blue: 0.40)   // Apron S — neutral gray
        }
    }

    private var standLabel: String {
        bay.stand.isA380Capable ? "F" : bay.stand.code
    }

    private var bridgeText: String? {
        guard let count = bay.bridges.totalCount, count > 0 else { return nil }
        return "\(count) bridge\(count == 1 ? "" : "s")"
    }

    var body: some View {
        HStack(spacing: 14) {
            // MARK: Bay ID badge
            VStack(spacing: 3) {
                Text(bay.bayId)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)

                Text("Stand \(standLabel)")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.75))
            }
            .frame(width: 72, height: 60)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(concourseColor.gradient)
            )

            // MARK: Details
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    if let gate = bay.gateId, gate != bay.bayId {
                        Text("Gate \(gate)")
                            .font(.body.weight(.semibold))
                    }

                    if let oldGate = bay.oldGateId {
                        Text("(was \(oldGate))")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    Spacer()

                    if bay.operationalStatus == .closed {
                        Text("Closed")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.red, in: Capsule())
                    }
                }

                HStack(spacing: 5) {
                    featureIcon(
                        icon: bay.isContact ? "arrow.up.right.and.arrow.down.left.rectangle" : "bus",
                        label: bay.isContact ? "Contact" : "Remote",
                        color: bay.isContact ? .blue : .orange
                    )

                    if bay.isA380Capable {
                        featureIcon(icon: "airplane", label: "A380", color: .indigo)
                    }

                    if bay.hasDuda {
                        featureIcon(icon: "arrow.up.arrow.down", label: "DUDA", color: .teal)
                    }

                    if bay.biometricBoarding {
                        featureIcon(icon: "faceid", label: "Bio", color: .purple)
                    }

                    if let text = bridgeText {
                        featureIcon(icon: "door.sliding.left.hand.open", label: text, color: .secondary)
                    }
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.quaternary)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }

    // MARK: - Feature Icon

    private func featureIcon(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .semibold))
            Text(label)
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}
