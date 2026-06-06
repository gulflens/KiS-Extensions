import SwiftUI

// MARK: - Rotation Strip

/// Horizontal stepper showing the sectors of the active rotation, with each
/// leg marked completed, active, or upcoming. Scrolls horizontally so long
/// rotations stay glanceable. Pure presentation.
struct RotationStrip: View {
    let rotation: OperationalContext.Rotation

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 0) {
                ForEach(Array(rotation.steps.enumerated()), id: \.element.id) { index, step in
                    legView(step, index: index)
                    if index != rotation.steps.count - 1 {
                        connector(after: step)
                    }
                }
            }
            .padding(.vertical, AppSpacing.xs)
        }
    }

    // MARK: Leg

    private func legView(_ step: OperationalContext.Rotation.Step, index: Int) -> some View {
        VStack(spacing: AppSpacing.sm) {
            numberedDot(step.status, index: index)
            VStack(spacing: 1) {
                Text(step.from)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                Image(systemName: "arrow.down")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(AppColor.textTertiary)
                Text(step.to)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
            }
            .foregroundStyle(textColor(for: step.status))
        }
        .frame(width: 58)
    }

    private func numberedDot(_ status: OperationalContext.Rotation.Status, index: Int) -> some View {
        ZStack {
            Circle().fill(tint(status).opacity(status == .upcoming ? 0.12 : 0.18))
            Circle().strokeBorder(tint(status), lineWidth: 2)
            if status == .completed {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(tint(status))
            } else if status == .active {
                Image(systemName: "airplane")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(tint(status))
            } else {
                Text("\(index + 1)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(tint(status))
            }
        }
        .frame(width: 34, height: 34)
    }

    private func connector(after step: OperationalContext.Rotation.Step) -> some View {
        Image(systemName: "airplane")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(step.status == .completed ? AppColor.positive : AppColor.textTertiary)
            .frame(width: 26)
            .padding(.top, 12)
            .background(alignment: .center) {
                Rectangle()
                    .fill(step.status == .completed ? AppColor.positive : AppColor.separator)
                    .frame(height: 2)
                    .padding(.top, 12)
            }
    }

    private func tint(_ status: OperationalContext.Rotation.Status) -> Color {
        switch status {
        case .completed: return AppColor.positive
        case .active:    return AppColor.gold
        case .upcoming:  return AppColor.textTertiary
        }
    }

    private func textColor(for status: OperationalContext.Rotation.Status) -> Color {
        status == .upcoming ? AppColor.textSecondary : AppColor.textPrimary
    }
}

// MARK: - Preview

#Preview {
    RotationStrip(rotation: .init(title: "EK0622", steps: [
        .init(id: UUID(), from: "DXB", to: "KHI", status: .completed),
        .init(id: UUID(), from: "KHI", to: "DXB", status: .active),
        .init(id: UUID(), from: "DXB", to: "LHR", status: .upcoming),
        .init(id: UUID(), from: "LHR", to: "DXB", status: .upcoming),
    ]))
    .padding(AppSpacing.xxl)
    .frame(maxWidth: .infinity)
    .background(AppColor.background)
}
