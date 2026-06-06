import SwiftUI

// MARK: - Duty Progress Ring

/// Circular progress indicator for the current sector. Renders a track plus an
/// accent arc with a two-line center label. Pure presentation — `progress` and
/// the labels are resolved upstream. Tuned to sit on the navy hero surface.
struct DutyProgressRing: View {
    let progress: Double      // 0...1
    let centerTop: String     // e.g. "5h 08m"
    let centerBottom: String  // e.g. "remaining"
    var accent: Color = AppColor.gold
    var diameter: CGFloat = 134
    var lineWidth: CGFloat = 9

    private var clamped: Double { min(max(progress, 0), 1) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.14), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(accent, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: clamped)
            VStack(spacing: 2) {
                Text(centerTop)
                    .font(.system(size: 23, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColor.textOnNavy)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(centerBottom.uppercased())
                    .font(.dashMicroLabel)
                    .tracking(0.8)
                    .foregroundStyle(AppColor.textOnNavySecondary)
            }
            .padding(10)
        }
        .frame(width: diameter, height: diameter)
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: AppSpacing.xl) {
        DutyProgressRing(progress: 0.62, centerTop: "2h 05m", centerBottom: "remaining")
        DutyProgressRing(progress: 0, centerTop: "5h 50m", centerBottom: "to departure",
                         accent: AppColor.info)
    }
    .padding(AppSpacing.xxl)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppColor.heroGradient)
}
