import SwiftUI

struct CrewEntryForm: View {
    @Environment(\.dismiss) private var dismiss
    @State private var entry = ManualCrewEntry()

    let onSave: (ManualCrewEntry) -> Void

    var body: some View {
        Form {
            Section("Personal Information") {
                TextField("First Name", text: $entry.firstName)
                TextField("Last Name", text: $entry.lastName)
                TextField("Nickname (optional)", text: $entry.nickName)
                TextField("Staff ID", text: $entry.staffID)
                    .keyboardType(.numberPad)
                DatePicker("Date of Birth", selection: $entry.dob, displayedComponents: .date)
            }

            Section("Grade") {
                Picker("Operation Grade", selection: $entry.operationGrade) {
                    ForEach(CrewGrade.allCases) { grade in
                        Text(grade.rawValue).tag(grade)
                    }
                }
                Picker("HR Grade", selection: $entry.hrGrade) {
                    ForEach(CrewGrade.allCases) { grade in
                        Text(grade.rawValue).tag(grade)
                    }
                }
                TextField("Grade Experience (e.g. 2 Years 3 Months)", text: $entry.gradeExp)
            }

            Section("Nationality") {
                TextField("Country Code (e.g. IN)", text: $entry.nationalityCode)
                    .autocapitalization(.allCharacters)
                TextField("Nationality (e.g. Indian)", text: $entry.nationality)
            }

            Section("Qualifications") {
                TextField("Profile codes (comma-separated)", text: $entry.profile)
                    .font(.system(.body, design: .monospaced))
                Text("Enter qualification codes separated by commas")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Add Crew Member")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Add") {
                    onSave(entry)
                }
                .disabled(entry.firstName.isEmpty || entry.staffID.isEmpty)
            }
        }
    }
}
