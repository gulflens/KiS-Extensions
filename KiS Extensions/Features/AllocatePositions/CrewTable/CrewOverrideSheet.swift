import SwiftUI

// MARK: - Override Mode

enum CrewOverrideMode: Identifiable {
    case add(grade: CrewGrade)
    case edit(member: CrewMember, index: Int)

    var id: String {
        switch self {
        case .add(let grade): return "add-\(grade.rawValue)"
        case .edit(let member, _): return "edit-\(member.id)"
        }
    }
}

// MARK: - Crew Override Sheet

struct CrewOverrideSheet: View {
    @Environment(\.dismiss) private var dismiss

    let mode: CrewOverrideMode
    let sectors: Int
    let onSave: (CrewMember) -> Void
    var onDelete: (() -> Void)?

    @State private var nickname: String = ""
    @State private var fullname: String = ""
    @State private var staffNumber: String = ""
    @State private var grade: CrewGrade = .GR2
    @State private var flagCode: String = ""
    @State private var nationality: String = ""
    @State private var languages: String = ""
    @State private var comment: String = ""
    @State private var positions: [Int: String] = [:]
    @State private var breaks: [Int: Int] = [:]
    @State private var showDeleteConfirmation = false

    private var isAddMode: Bool {
        if case .add = mode { return true }
        return false
    }

    private var isManualCrewEdit: Bool {
        if case .edit(let member, _) = mode { return member.isManualOverride }
        return false
    }

    private var title: String {
        isAddMode ? "Add Crew Member" : "Edit Crew Member"
    }

    var body: some View {
        Form {
            // MARK: Personal
            Section("Personal") {
                TextField("Nickname", text: $nickname)
                    .textInputAutocapitalization(.words)
                TextField("Full name", text: $fullname)
                    .textInputAutocapitalization(.words)
                if isAddMode || isManualCrewEdit {
                    TextField("Staff number", text: $staffNumber)
                        .keyboardType(.numberPad)
                } else {
                    LabeledContent("Staff number", value: staffNumber)
                }
            }

            // MARK: Grade
            Section("Grade") {
                Picker("Grade", selection: $grade) {
                    ForEach(CrewGrade.allCases) { g in
                        Text("\(g.rawValue) - \(g.displayName)")
                            .tag(g)
                    }
                }
            }

            // MARK: Nationality
            Section("Nationality") {
                TextField("Country code (e.g. eg, gb)", text: $flagCode)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField("Nationality (e.g. Egyptian)", text: $nationality)
                    .textInputAutocapitalization(.words)
            }

            // MARK: Details
            Section("Details") {
                TextField("Languages (comma-separated)", text: $languages)
                    .textInputAutocapitalization(.words)
                TextField("Comment", text: $comment)
            }

            // MARK: Positions
            if !isAddMode {
                Section("Positions") {
                    ForEach(0..<sectors, id: \.self) { sector in
                        HStack {
                            Text("Sector \(sector + 1)")
                                .foregroundStyle(.secondary)
                            Spacer()
                            TextField("Position", text: positionBinding(for: sector))
                                .textInputAutocapitalization(.characters)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                        }
                    }
                }
            }

            // MARK: Remove
            if case .edit = mode, onDelete != nil {
                Section {
                    Button("Remove crew member", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveAndDismiss()
                }
                .disabled(nickname.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .confirmationDialog(
            "Remove this crew member?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                onDelete?()
                dismiss()
            }
        }
        .onAppear { populateFields() }
    }

    // MARK: - Helpers

    private func positionBinding(for sector: Int) -> Binding<String> {
        Binding(
            get: { positions[sector] ?? "" },
            set: { positions[sector] = $0.isEmpty ? nil : $0 }
        )
    }

    private func populateFields() {
        switch mode {
        case .add(let targetGrade):
            grade = targetGrade
            staffNumber = "MANUAL-\(UUID().uuidString.prefix(8))"
        case .edit(let member, _):
            nickname = member.nickname
            fullname = member.fullname
            staffNumber = member.staffNumber
            grade = member.grade
            flagCode = member.flag
            nationality = member.nationality
            languages = member.languages.joined(separator: ", ")
            comment = member.comment
            positions = member.positions
            breaks = member.breaks
        }
    }

    private func saveAndDismiss() {
        let parsedLanguages = languages
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        var member: CrewMember

        switch mode {
        case .add:
            member = CrewMember(
                id: staffNumber,
                index: grade.indexModifier + 99,
                ratingIR: 21,
                languages: parsedLanguages,
                badges: [],
                grade: grade,
                originalGrade: grade,
                outOfGrade: false,
                flag: flagCode.lowercased(),
                timeInGrade: "",
                timeInGradeMonths: 0,
                birthday: Date(),
                lastPosition: [],
                comment: comment,
                staffNumber: staffNumber,
                fullname: fullname.trimmingCharacters(in: .whitespaces),
                nickname: nickname.trimmingCharacters(in: .whitespaces),
                destinationExperience: [:],
                nationality: nationality.trimmingCharacters(in: .whitespaces),
                positions: positions,
                breaks: breaks,
                isManualOverride: true
            )

        case .edit(let existing, _):
            member = existing
            member.nickname = nickname.trimmingCharacters(in: .whitespaces)
            member.fullname = fullname.trimmingCharacters(in: .whitespaces)
            member.grade = grade
            member.flag = flagCode.lowercased()
            member.nationality = nationality.trimmingCharacters(in: .whitespaces)
            member.languages = parsedLanguages
            member.comment = comment
            member.positions = positions
            member.breaks = breaks
            member.isManualOverride = true
        }

        onSave(member)
        dismiss()
    }
}
