import SwiftUI

// MARK: - Lounge Access Verdict View

/// Renders a `LoungeAccessDecision` as a colored card with a clear headline
/// (allowed / paid / denied), a one-line reason, and price detail when paid.
struct LoungeAccessVerdictView: View {
    let decision: LoungeAccessDecision

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                Text(headline)
                    .font(.headline)
            }
            .foregroundStyle(color)

            Text(reasonText)
                .font(.subheadline)
                .foregroundStyle(.primary)

            if case .allowedWithLimitedGuests(let adults, let children, _) = decision {
                Text("Guest entitlement: \(adults) adult\(adults == 1 ? "" : "s")\(children > 0 ? ", \(children) under 17" : "")")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if case .paidOnly(let usd, let aed, _) = decision {
                if usd != nil || aed != nil {
                    HStack(spacing: 12) {
                        if let usd {
                            priceTag(value: usd, currency: "USD")
                        }
                        if let aed {
                            priceTag(value: aed, currency: "AED")
                        }
                    }
                    Text("Indicative pricing — verify on emirates.com before quoting.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
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

    // MARK: - Verdict styling

    private var color: Color {
        switch decision {
        case .allowed, .allowedWithLimitedGuests: return .green
        case .paidOnly: return .orange
        case .denied: return .red
        }
    }

    private var icon: String {
        switch decision {
        case .allowed, .allowedWithLimitedGuests: return "checkmark.seal.fill"
        case .paidOnly: return "creditcard.fill"
        case .denied: return "xmark.seal.fill"
        }
    }

    private var headline: String {
        switch decision {
        case .allowed: return "Complimentary access"
        case .allowedWithLimitedGuests: return "Complimentary access"
        case .paidOnly: return "Paid access only"
        case .denied: return "Access denied"
        }
    }

    private var reasonText: String {
        switch decision {
        case .allowed(let reason, _),
             .allowedWithLimitedGuests(_, _, let reason),
             .paidOnly(_, _, let reason),
             .denied(let reason):
            return reason
        }
    }

    // MARK: - Price Tag

    private func priceTag(value: Double, currency: String) -> some View {
        let formatted = value.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(value))"
            : String(format: "%.2f", value)
        return Text("\(formatted) \(currency)")
            .font(.subheadline.weight(.semibold).monospacedDigit())
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.orange.opacity(0.15), in: Capsule())
            .foregroundStyle(.orange)
    }
}
