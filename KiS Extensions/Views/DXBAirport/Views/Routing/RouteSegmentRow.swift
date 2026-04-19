import SwiftUI

// MARK: - Route Segment Row

/// Single segment in the planner result list. Shows mode icon, from → to,
/// duration (or stub badge), and an optional detail line.
struct RouteSegmentRow: View {
    let segment: PlannedSegment

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(segment.from)  →  \(segment.to)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)

                if let detail = segment.detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if segment.isStub {
                stubBadge
            } else if let seconds = segment.timeSeconds {
                Text(formatTime(seconds))
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.primary)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Styling

    private var icon: String {
        switch segment.kind {
        case .walk: return "figure.walk"
        case .train: return "tram.fill"
        case .stairs: return "stairs"
        case .elevator: return "arrow.up.arrow.down.square"
        }
    }

    private var color: Color {
        switch segment.kind {
        case .walk: return .blue
        case .train: return Color(red: 0x00/255, green: 0x22/255, blue: 0x4C/255)
        case .stairs: return .gray
        case .elevator: return .purple
        }
    }

    private var stubBadge: some View {
        Text("TBD")
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.orange.opacity(0.15), in: Capsule())
            .foregroundStyle(.orange)
    }

    // MARK: - Time formatting

    private func formatTime(_ seconds: Double) -> String {
        let minutes = Int((seconds / 60).rounded())
        if minutes < 1 {
            return "<1 min"
        }
        return "\(minutes) min"
    }
}
