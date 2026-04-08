import SwiftUI
import SwiftData

/// Shows saved KiS report drafts sorted by most recently updated.
/// Supports swipe-to-delete and tap to reopen in the composer.
struct DraftHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \KiSReportRecord.updatedAt, order: .reverse)
    private var drafts: [KiSReportRecord]

    /// Called when the user taps a draft to load it into the composer.
    var onSelect: (KiSReportRecord) -> Void

    @State private var recordToDelete: KiSReportRecord?

    var body: some View {
        NavigationStack {
            Group {
                if drafts.isEmpty {
                    emptyState
                } else {
                    draftList
                }
            }
            .navigationTitle("Drafts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Delete Draft?", isPresented: deleteAlertBinding) {
                Button("Delete", role: .destructive) {
                    if let record = recordToDelete {
                        modelContext.delete(record)
                    }
                    recordToDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    recordToDelete = nil
                }
            } message: {
                if let record = recordToDelete {
                    Text("\"\(record.displayTitle)\" will be permanently deleted.")
                }
            }
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        ContentUnavailableView(
            "No Drafts",
            systemImage: "doc.text",
            description: Text("Reports you start will appear here automatically.")
        )
    }

    private var draftList: some View {
        List {
            ForEach(drafts) { record in
                Button {
                    onSelect(record)
                } label: {
                    draftRow(record)
                }
                .tint(.primary)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        recordToDelete = record
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }

    private func draftRow(_ record: KiSReportRecord) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(record.displayTitle)
                    .font(.headline)

                Spacer()

                if record.isComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.subheadline)
                } else {
                    Text("Draft")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.secondary.opacity(0.15), in: Capsule())
                }
            }

            if !record.summary.isEmpty {
                Text(record.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            if let path = record.classificationPath {
                Text(path)
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .lineLimit(1)
            }

            Text(record.updatedAt, format: .dateTime.month(.abbreviated).day().hour().minute())
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }

    // MARK: - Helpers

    private var deleteAlertBinding: Binding<Bool> {
        Binding(
            get: { recordToDelete != nil },
            set: { if !$0 { recordToDelete = nil } }
        )
    }
}
