import SwiftUI

// MARK: - Clock Card

/// Compact operational clock. Displays a pre-formatted time and date string;
/// the caller drives live updates with a `TimelineView`. An empty `time`
/// renders the prompt state used by the destination clock.
struct ClockCard: View {
    let label: String
    let systemImage: String
    var accent: Color = AppColor.navyAccent
    var time: String = ""
    var date: String = ""
    var promptText: String = "Tap to select"
    /// When true the card adopts a dark "night" palette, mirroring the Apple
    /// Clock list where locations in night-time hours render dark.
    var isNight: Bool = false

    @Environment(\.colorScheme) private var colorScheme

    private var isPrompt: Bool { time.isEmpty }

    // MARK: Palette

    private var cardBackground: Color {
        isNight ? AppColor.navy : AppColor.surfaceElevated
    }
    private var primaryText: Color {
        isNight ? AppColor.textOnNavy : AppColor.textPrimary
    }
    private var secondaryText: Color {
        isNight ? AppColor.textOnNavySecondary : AppColor.textSecondary
    }
    private var borderColor: Color {
        isNight ? Color.white.opacity(0.10) : AppColor.border
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Accent top border
            accent.frame(height: 3)

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack(spacing: 5) {
                    Image(systemName: systemImage)
                        .font(.system(size: 10, weight: .bold))
                    Text(label.uppercased())
                        .font(.dashMicroLabel)
                        .tracking(1.1)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                .foregroundStyle(accent)

                if isPrompt {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 19, weight: .regular))
                        Text(promptText)
                            .font(.dashMetadata)
                    }
                    .foregroundStyle(AppColor.textTertiary)
                    .padding(.vertical, 2)
                } else {
                    Text(time)
                        .font(.dashClockTime)
                        .monospacedDigit()
                        .foregroundStyle(primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text(date)
                        .font(.dashMetadata)
                        .foregroundStyle(secondaryText)
                        .lineLimit(1)
                }
            }
            .padding(AppSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        // Fill the height offered by the row so prompt and filled cards share a
        // uniform size; content stays pinned to the top.
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        // On night cards, resolve the dynamic accent (top border + label) to
        // its brighter dark-mode variant so it stays legible on the navy fill.
        .environment(\.colorScheme, isNight ? .dark : colorScheme)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.panel, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.panel, style: .continuous)
                .strokeBorder(borderColor, lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.35), value: isNight)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: AppSpacing.lg) {
        ClockCard(label: "Dubai", systemImage: "building.2",
                  accent: AppColor.gold, time: "08:00:38", date: "Sat, 17 May 2026")
        ClockCard(label: "UTC", systemImage: "globe",
                  accent: AppColor.info, time: "04:00:38", date: "Sat, 17 May 2026")
        ClockCard(label: "Destination", systemImage: "airplane",
                  accent: AppColor.positive)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppColor.background)
}
