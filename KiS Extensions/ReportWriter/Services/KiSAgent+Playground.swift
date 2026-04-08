import Foundation
import FoundationModels
import Playgrounds

#Playground {
    let agent = KiSAgent()

    let testCases: [(notes: String, expectedCat1: String, label: String)] = [
        (
            notes: "Passenger 23A complained about hair in chicken meal during second service. Showed me the hair, said 'this is disgusting'. Replaced with vegetarian option.",
            expectedCat1: "Catering",
            label: "hair in meal"
        ),
        (
            notes: "Pax 14C shouting at crew member after refused more alcohol. Verbal abuse continued for 20 min. Formal warning issued by purser.",
            expectedCat1: "Security",
            label: "disruptive drunk pax"
        ),
        (
            notes: "Seat 32K recline broken from boarding. Pax moved to 41D. Tech log entry made.",
            expectedCat1: "Cabin Defect",
            label: "broken seat"
        ),
        (
            notes: "Crew member Sarah Ahmed staff 388291 went above and beyond helping elderly pax 8A with medication. Customer specifically thanked her.",
            expectedCat1: "Cabin Crew",
            label: "crew compliment"
        ),
        (
            notes: "Pax 19F felt unwell during cruise, chest pain. Doctor onboard assisted. EMK opened. Oxygen administered. Diverted to AUH.",
            expectedCat1: "Medical",
            label: "medical emergency"
        ),
        (
            notes: "Oven 3 in galley 4L not heating. Impacted meal service for Y class. Used oven 4 instead, delay of 15 min.",
            expectedCat1: "Cabin Defect",
            label: "oven broken"
        ),
        (
            notes: "Short loaded 4 JCL meals on EK237. Offered pax choice from Y class or snack box. Pax in 3K and 3H accepted vegetarian alternative.",
            expectedCat1: "Catering",
            label: "loading shortage"
        ),
        (
            notes: "Wi-Fi unavailable entire flight DXB-LHR. 6 hours affected. Multiple pax complained in J class.",
            expectedCat1: "Wi-Fi & Mobile",
            label: "wifi down"
        ),
    ]

    print("=== CLASSIFIER DIAGNOSTIC ===")
    print("")

    var correct = 0

    for testCase in testCases {
        do {
            let pick = try await agent.classifyCat1(bullets: testCase.notes)
            let match = pick.category == testCase.expectedCat1
            if match { correct += 1 }

            print("\(match ? "✓" : "✗") [\(testCase.label)]")
            print("  Expected:   \(testCase.expectedCat1)")
            print("  Got:        \(pick.category)")
            print("  Confidence: \(String(format: "%.2f", pick.confidence))")
            print("")
        } catch {
            print("✗ [\(testCase.label)] ERROR: \(error)")
            print("")
        }
    }

    print("=== SCORE: \(correct)/8 ===")
}
