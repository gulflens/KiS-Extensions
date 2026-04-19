import SwiftUI

// MARK: - Route Verdict View

/// Renders a `RouteVerdict` as a colored card. Mirrors the visual language of
/// `LoungeAccessVerdictView` so verdicts feel consistent across the mini-app.
struct RouteVerdictView: View {
    let verdict: RouteVerdict
    let totalSeconds: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                Text(headline)
                    .font(.headline)
            }
            .foregroundStyle(color)

            Text(detailText)
                .font(.subheadline)
                .foregroundStyle(.primary)

            if let totalSeconds {
                Text("Estimated total: \(Int((totalSeconds / 60).rounded())) min")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(color.opacity(0.30), lineWidth: 1)
        )
    }

    // MARK: - Styling

    private var color: Color {
        switch verdict {
        case .comfortable: return .green
        case .tight: return .orange
        case .unrealistic: return .red
        }
    }

    private var icon: String {
        switch verdict {
        case .comfortable: return "checkmark.seal.fill"
        case .tight: return "clock.badge.exclamationmark"
        case .unrealistic: return "xmark.seal.fill"
        }
    }

    private var headline: String {
        switch verdict {
        case .comfortable: return "Comfortable"
        case .tight: return "Tight"
        case .unrealistic: return "Unrealistic"
        }
    }

    private var detailText: String {
        switch verdict {
        case .comfortable:
            return "Plenty of time. Route is well within the boarding window."
        case .tight(let spare):
            return "Only \(spare) min spare before boarding. Move now."
        case .unrealistic(let reason):
            return reason
        }
    }
}
