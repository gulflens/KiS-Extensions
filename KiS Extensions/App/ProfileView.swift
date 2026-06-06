import SwiftUI
import SwiftData
import PhotosUI

// MARK: - Profile View

/// Editable crew profile: name, staff number, rank, and photo. Edits a local
/// draft and writes back to `AppSettings` only on Save, so Cancel discards.
struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsArray: [AppSettings]

    @State private var name = ""
    @State private var staffNumber = ""
    @State private var rank = ""
    @State private var imageData: Data?
    @State private var photoItem: PhotosPickerItem?
    @State private var loaded = false

    private var settings: AppSettings {
        if let existing = settingsArray.first { return existing }
        let created = AppSettings()
        modelContext.insert(created)
        return created
    }

    var body: some View {
        NavigationStack {
            Form {
                photoSection
                Section("Identity") {
                    TextField("Full name", text: $name)
                        .textInputAutocapitalization(.words)
                    TextField("Staff number", text: $staffNumber)
                        .keyboardType(.numbersAndPunctuation)
                }
                Section {
                    TextField("Rank or grade", text: $rank)
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("Role")
                } footer: {
                    Text("For example: Cabin Crew, First Class, Purser.")
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .onAppear(perform: loadIfNeeded)
            .onChange(of: photoItem) { _, newItem in
                Task { await loadPhoto(newItem) }
            }
        }
    }

    // MARK: Photo Section

    private var photoSection: some View {
        Section {
            VStack(spacing: AppSpacing.md) {
                ProfileAvatar(name: name, imageData: imageData, size: 96)
                PhotosPicker(selection: $photoItem, matching: .images) {
                    Text(imageData == nil ? "Choose Photo" : "Change Photo")
                        .font(.dashCardTitle)
                }
                if imageData != nil {
                    Button(role: .destructive) {
                        imageData = nil
                        photoItem = nil
                    } label: {
                        Text("Remove Photo")
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
        }
    }

    // MARK: Actions

    private func loadIfNeeded() {
        guard !loaded else { return }
        let s = settings
        name = s.crewName
        staffNumber = s.staffNumber
        rank = s.rank
        imageData = s.profileImageData
        loaded = true
    }

    private func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self) else { return }
        imageData = data
    }

    private func save() {
        let s = settings
        s.crewName = name.trimmingCharacters(in: .whitespaces)
        s.staffNumber = staffNumber.trimmingCharacters(in: .whitespaces)
        s.rank = rank.trimmingCharacters(in: .whitespaces)
        s.profileImageData = imageData
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    ProfileView()
        .modelContainer(for: AppSettings.self, inMemory: true)
}
