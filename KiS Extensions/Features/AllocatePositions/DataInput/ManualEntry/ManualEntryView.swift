import SwiftUI

struct ManualEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var flightNumber = ""
    @State private var flightLegsText = "" // comma-separated: "DXB, AMS, DXB"
    @State private var flightDate = Date()
    @State private var registration = ""
    @State private var crewEntries: [ManualCrewEntry] = []
    @State private var showCrewForm = false
    @State private var editingCrewIndex: Int?

    let onComplete: (ParsedTrip) -> Void

    var body: some View {
        Form {
            Section("Flight Information") {
                TextField("Flight Number", text: $flightNumber)
                    .keyboardType(.numberPad)
                TextField("Flight Legs (e.g. DXB, AMS, DXB)", text: $flightLegsText)
                    .autocapitalization(.allCharacters)
                DatePicker("Flight Date", selection: $flightDate, displayedComponents: .date)
                TextField("Aircraft Registration (e.g. A6ECA)", text: $registration)
                    .autocapitalization(.allCharacters)

                if let reg = registration.isEmpty ? nil : registration,
                   let typeCode = FleetRegistry.fleet[reg],
                   let acType = AircraftTypes.types[typeCode] {
                    HStack {
                        Text("Aircraft Type")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(acType.description)
                            .foregroundStyle(.blue)
                    }
                }
            }

            Section("Crew (\(crewEntries.count))") {
                ForEach(crewEntries) { entry in
                    HStack {
                        Text(entry.operationGrade.rawValue)
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(gradeColor(entry.operationGrade))
                            .cornerRadius(4)
                        Text("\(entry.firstName) \(entry.lastName)")
                        Spacer()
                        Text(entry.staffID)
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete { indexSet in
                    crewEntries.remove(atOffsets: indexSet)
                }

                Button {
                    showCrewForm = true
                } label: {
                    Label("Add Crew Member", systemImage: "plus")
                }
            }
        }
        .navigationTitle("Manual Entry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Create Trip") {
                    createTrip()
                }
                .disabled(flightNumber.isEmpty || crewEntries.isEmpty)
            }
        }
        .sheet(isPresented: $showCrewForm) {
            NavigationStack {
                CrewEntryForm { entry in
                    crewEntries.append(entry)
                    showCrewForm = false
                }
            }
        }
    }

    private func createTrip() {
        let legs = flightLegsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces).uppercased() }

        let sectors = max(1, legs.count - 1)
        let durations = Array(repeating: 6.0, count: sectors) // default duration

        let service = DataImportService()
        let trip = service.createFromManualEntry(
            flightNumber: flightNumber,
            flightLegs: legs,
            flightDate: flightDate,
            sectors: sectors,
            durations: durations,
            registration: registration.isEmpty ? nil : registration,
            crewEntries: crewEntries
        )
        onComplete(trip)
    }

    private func gradeColor(_ grade: CrewGrade) -> Color {
        switch grade {
        case .PUR, .CSV: return .orange
        case .FG1: return .red
        case .GR1: return .blue
        case .W: return .purple
        case .GR2: return .green
        case .CSA: return .gray
        }
    }
}
