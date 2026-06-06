import Foundation

// MARK: - We Care Cabin

enum WeCareCabin: String, CaseIterable, Identifiable, Codable {
    case firstClass = "First Class"
    case businessClass = "Business Class"
    case premiumEconomy = "Premium Economy"
    case economyClass = "Economy Class"

    var id: String { rawValue }

    var shortCode: String {
        switch self {
        case .firstClass: return "FC"
        case .businessClass: return "JC"
        case .premiumEconomy: return "WC"
        case .economyClass: return "YC"
        }
    }

    var cycleDurationMin: Int {
        switch self {
        case .firstClass, .businessClass, .premiumEconomy: return 30
        case .economyClass: return 45
        }
    }

    var usesPremiumTiming: Bool {
        switch self {
        case .firstClass, .businessClass, .premiumEconomy: return true
        case .economyClass: return false
        }
    }
}

// MARK: - Service Placement

struct WeCareServicePlacement: Identifiable {
    let id = UUID()
    let serviceNumber: Int
    let startMin: Int
    let durationJC: Int
    let durationYC: Int

    func endMin(premium: Bool) -> Int {
        startMin + (premium ? durationJC : durationYC)
    }
}

// MARK: - We Care Cycle

struct WeCareCycle: Identifiable {
    let id = UUID()
    let cabin: WeCareCabin
    let cycleNumber: Int
    let gapIndex: Int
    let startMin: Int
    let endMin: Int
    var assignedCrew: [String]
}

// MARK: - We Care Gap

struct WeCareGap: Identifiable {
    let id = UUID()
    let gapIndex: Int
    let afterService: Int
    let startMin: Int
    let endMin: Int
    let availableMin: Int
    var cycles: [WeCareCycle]
}

// MARK: - Cabin Result

struct CabinWeCareResult: Identifiable {
    let cabin: WeCareCabin
    var gaps: [WeCareGap]
    let totalCycles: Int
    var id: String { cabin.shortCode }
}

// MARK: - We Care Result

struct WeCareResult {
    let isEligible: Bool
    let flightDurationMin: Int
    var cabinResults: [CabinWeCareResult]
    let servicePlacements: [WeCareServicePlacement]
    let ineligibilityReason: String?
}

// MARK: - Break Entry

struct WeCareBreakEntry {
    let group: Int
    let startMin: Int
    let endMin: Int
}
