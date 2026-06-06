import SwiftUI

// MARK: - Add Trip Tile

/// Dashboard tile that opens a menu to import a trip from the Crew Portal or
/// add one manually. Matches the visual treatment of `DashboardCard` so it
/// slots naturally into the Features grid.
struct AddTripTile: View {
    var onImportPortal: () -> Void
    var onAddManually: () -> Void

    private let accent: Color = AppColor.todayAccent

    var body: some View {
        Menu {
            Button {
                onImportPortal()
            } label: {
                Label("Import from Portal", systemImage: "square.and.arrow.down")
            }
            Button {
                onAddManually()
            } label: {
                Label("Add manually", systemImage: "square.and.pencil")
            }
        } label: {
            tileLabel
        }
        .buttonStyle(CardPressStyle())
    }

    // MARK: - Label

    private var tileLabel: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                IconBadge(systemImage: "plus", accent: accent, size: 40)
                Spacer(minLength: AppSpacing.sm)
                Image(systemName: "chevron.down")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColor.textTertiary)
            }

            Spacer(minLength: AppSpacing.lg)

            Text("Add Trip")
                .font(.dashCardTitle)
                .foregroundStyle(AppColor.textPrimary)

            Text("Import from the Crew Portal or add a trip manually.")
                .font(.dashBody)
                .foregroundStyle(AppColor.textSecondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)
        }
        .padding(AppSpacing.xl)
        .frame(maxWidth: .infinity, minHeight: 168, alignment: .leading)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .fill(AppColor.surfaceElevated)
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .fill(LinearGradient(
                        colors: [accent.opacity(0.10), .clear],
                        startPoint: .topLeading, endPoint: .center))
                Image(systemName: "plus")
                    .font(.system(size: 124, weight: .semibold))
                    .foregroundStyle(accent.opacity(0.06))
                    .offset(x: 34, y: 40)
            }
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        }
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .strokeBorder(AppColor.border, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.10), radius: 14, x: 0, y: 8)
    }
}

// MARK: - Preview

#Preview {
    AddTripTile(onImportPortal: {}, onAddManually: {})
        .padding()
        .background(AppColor.background)
}
