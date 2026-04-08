import SwiftUI

// MARK: - Diagnostic result model

struct DiagnosticResult: Identifiable {
    let id = UUID()
    let label: String
    let expected: String
    let notes: String
    var got: String?
    var confidence: Double?
    var errorMessage: String?
    var isCorrect: Bool {
        guard let got else { return false }
        return got == expected
    }
}

// MARK: - Test cases

private let diagnosticTestCases: [(label: String, expected: String, notes: String)] = [
    (
        label: "hair in meal",
        expected: "Catering",
        notes: "Passenger 23A complained about hair in chicken meal during second service. Showed me the hair, said 'this is disgusting'. Replaced with vegetarian option."
    ),
    (
        label: "disruptive drunk pax",
        expected: "Security",
        notes: "Pax 14C shouting at crew member after refused more alcohol. Verbal abuse continued for 20 min. Formal warning issued by purser."
    ),
    (
        label: "broken seat",
        expected: "Cabin Defect",
        notes: "Seat 32K recline broken from boarding. Pax moved to 41D. Tech log entry made."
    ),
    (
        label: "crew compliment",
        expected: "Cabin Crew",
        notes: "Crew member Sarah Ahmed staff 388291 went above and beyond helping elderly pax 8A with medication. Customer specifically thanked her."
    ),
    (
        label: "medical emergency",
        expected: "Medical",
        notes: "Pax 19F felt unwell during cruise, chest pain. Doctor onboard assisted. EMK opened. Oxygen administered. Diverted to AUH."
    ),
    (
        label: "oven broken",
        expected: "Cabin Defect",
        notes: "Oven 3 in galley 4L not heating. Impacted meal service for Y class. Used oven 4 instead, delay of 15 min."
    ),
    (
        label: "loading shortage",
        expected: "Catering",
        notes: "Short loaded 4 JCL meals on EK237. Offered pax choice from Y class or snack box. Pax in 3K and 3H accepted vegetarian alternative."
    ),
    (
        label: "wifi down",
        expected: "Wi-Fi & Mobile",
        notes: "Wi-Fi unavailable entire flight DXB-LHR. 6 hours affected. Multiple pax complained in J class."
    ),
]

// MARK: - ClassifierDiagnosticView

struct ClassifierDiagnosticView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var results: [DiagnosticResult] = diagnosticTestCases.map {
        DiagnosticResult(label: $0.label, expected: $0.expected, notes: $0.notes)
    }
    @State private var isRunning = false
    @State private var agent = KiSAgent()
    @State private var selectedNotes: String?

    private var score: Int {
        results.filter(\.isCorrect).count
    }

    private var hasRun: Bool {
        results.contains { $0.got != nil || $0.errorMessage != nil }
    }

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Run button & score

                Section {
                    Button {
                        Task { await runDiagnostic() }
                    } label: {
                        HStack {
                            if isRunning {
                                ProgressView()
                                    .padding(.trailing, 4)
                                Text("Running...")
                            } else {
                                Label("Run Diagnostic", systemImage: "play.fill")
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .disabled(isRunning)

                    HStack {
                        Text("Score:")
                            .font(.headline)
                        Spacer()
                        Text(hasRun ? "\(score)/8" : "—/8")
                            .font(.title2.monospacedDigit().bold())
                            .foregroundStyle(hasRun && score == 8 ? .green : .primary)
                    }
                }

                // MARK: - Results

                Section("Results") {
                    ForEach(results) { result in
                        Button {
                            selectedNotes = result.notes
                        } label: {
                            resultRow(result)
                        }
                        .tint(.primary)
                    }
                }
            }
            .navigationTitle("Classifier Diagnostic")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(item: $selectedNotes) { notes in
                NavigationStack {
                    ScrollView {
                        Text(notes)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .navigationTitle("Test Notes")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { selectedNotes = nil }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
        }
    }

    // MARK: - Result row

    @ViewBuilder
    private func resultRow(_ result: DiagnosticResult) -> some View {
        HStack(spacing: 12) {
            Image(systemName: statusIcon(for: result))
                .foregroundStyle(statusColor(for: result))
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(result.label)
                    .font(.subheadline.bold())

                Text(statusDetail(for: result))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 2)
    }

    private func statusIcon(for result: DiagnosticResult) -> String {
        if result.errorMessage != nil { return "xmark.circle.fill" }
        guard result.got != nil else { return "circle" }
        return result.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill"
    }

    private func statusColor(for result: DiagnosticResult) -> Color {
        if result.errorMessage != nil { return .red }
        guard result.got != nil else { return .gray }
        return result.isCorrect ? .green : .red
    }

    private func statusDetail(for result: DiagnosticResult) -> String {
        if let error = result.errorMessage {
            return "ERROR: \(error)"
        }
        guard let got = result.got else {
            return "Not run"
        }
        let conf = result.confidence.map { String(format: "%.2f", $0) } ?? "—"
        return "Expected: \(result.expected)  |  Got: \(got)  |  Conf: \(conf)"
    }

    // MARK: - Run logic

    private func runDiagnostic() async {
        isRunning = true

        // Reset all results
        for i in results.indices {
            results[i].got = nil
            results[i].confidence = nil
            results[i].errorMessage = nil
        }

        for i in results.indices {
            do {
                let pick = try await agent.classifyCat1(bullets: results[i].notes)
                results[i].got = pick.category
                results[i].confidence = pick.confidence
            } catch {
                results[i].errorMessage = "\(error)"
            }
        }

        isRunning = false
    }
}

// MARK: - String+Identifiable for sheet

extension String: @retroactive Identifiable {
    public var id: String { self }
}
