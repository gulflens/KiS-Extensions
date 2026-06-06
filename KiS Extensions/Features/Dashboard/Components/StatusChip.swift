import SwiftUI

// MARK: - Status Chip

/// Compact pill for operational state: sync status, flight phase, alerts.
struct StatusChip: View {

    enum Style {
        case soft     // tinted background, tinted text
        case solid    // filled background, light text
        case outline  // bordered, tinted text
    }

    let text: String
    var systemImage: String? = nil
    var tint: Color = AppColor.navyAccent
    var style: Style = .soft

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 10, weight: .bold))
            }
            Text(text)
                .font(.dashMicroLabel)
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(Capsule().fill(background))
        .overlay(Capsule().strokeBorder(borderColor, lineWidth: 1))
    }

    // MARK: Style Resolution

    private var foreground: Color {
        switch style {
        case .soft, .outline: return tint
        case .solid:          return .white
        }
    }

    private var background: Color {
        switch style {
        case .soft:    return tint.opacity(0.16)
        case .solid:   return tint
        case .outline: return .clear
        }
    }

    private var borderColor: Color {
        switch style {
        case .soft:    return .clear
        case .solid:   return .clear
        case .outline: return tint.opacity(0.45)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: AppSpacing.md) {
        StatusChip(text: "Synced", systemImage: "checkmark.icloud", tint: AppColor.positive)
        StatusChip(text: "En route", systemImage: "airplane", tint: AppColor.gold, style: .solid)
        StatusChip(text: "2 alerts", systemImage: "bell.badge", tint: AppColor.warning, style: .outline)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppColor.background)
}
