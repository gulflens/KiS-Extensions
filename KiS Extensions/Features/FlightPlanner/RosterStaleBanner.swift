import SwiftUI

// MARK: - Roster Stale Banner

/// Lightweight banner shown when the imported roster is older than 24 hours
/// (or has never been imported). Tap to launch the importer; subscribes to
/// `rosterLastSyncedAt` written by `RosterImportView`.
struct RosterStaleBanner: View {
    @AppStorage("rosterLastSyncedAt") private var lastSyncedAtRaw: Double = 0
    var onRefresh: () -> Void

    private static let staleThreshold: TimeInterval = 24 * 3600

    private var lastSyncedAt: Date? {
        lastSyncedAtRaw > 0 ? Date(timeIntervalSince1970: lastSyncedAtRaw) : nil
    }

    private var isStale: Bool {
        guard let date = lastSyncedAt else { return true }
        return Date().timeIntervalSince(date) >= Self.staleThreshold
    }

    private var relativeLabel: String {
        guard let date = lastSyncedAt else { return "Never imported" }
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .full
        return "Last synced \(f.localizedString(for: date, relativeTo: Date()))"
    }

    var body: some View {
        if isStale {
            Button(action: onRefresh) {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.arrow.triangle.2.circlepath")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Roster may be out of date")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text(relativeLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("Refresh")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.orange))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.orange.opacity(0.10))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.orange.opacity(0.25), lineWidth: 0.5)
                )
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        RosterStaleBanner(onRefresh: {})
        Spacer()
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
