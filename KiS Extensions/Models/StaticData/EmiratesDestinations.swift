import Foundation

// MARK: - Emirates Destinations

/// Emirates airline IATA destination codes for station validation.
enum EmiratesDestinations {
    static let codes: Set<String> = [
        "AAN", "ABJ", "ACC", "ADD", "ADL", "AKL", "ALA", "ALG", "AMD", "AMM",
        "AMS", "ANC", "ARN", "ATH", "AUH", "AVV", "BAH", "BCN", "BEY", "BGW",
        "BHX", "BKK", "BLQ", "BLR", "BNE", "BOG", "BOM", "BOS", "BQN", "BRU",
        "BSR", "BUD", "CAI", "CAN", "CCU", "CDG", "CEB", "CGK", "CGO", "CHC",
        "CKY", "CLO", "CMB", "CMN", "COK", "COO", "CPH", "CPT", "CRK", "CTU",
        "DAC", "DAD", "DAR", "DEL", "DFW", "DME", "DMM", "DPS", "DSS", "DTW",
        "DUB", "DUR", "DUS", "DWC", "DXB", "EBB", "EBL", "EDI", "EWR", "EZE",
        "FCO", "FRA", "GIG", "GLA", "GRU", "GVA", "HAM", "HAN", "HGH", "HKG",
        "HKT", "HND", "HRE", "HYD", "IAD", "IAH", "ICN", "IKA", "ISB", "ISL",
        "IST", "JED", "JFK", "JNB", "KHI", "KIX", "KTI", "KUL", "KWI", "LAX",
        "LCA", "LED", "LGG", "LGW", "LHE", "LHR", "LIS", "LLW", "LOS", "LUN",
        "LYS", "MAA", "MAD", "MAN", "MCO", "MCT", "MED", "MEL", "MEX", "MIA",
        "MLA", "MLE", "MNL", "MRU", "MST", "MUC", "MXP", "NBJ", "NBO", "NCE",
        "NCL", "NLU", "NQY", "NRT", "ORD", "OSL", "PAE", "PEK", "PER", "PEW",
        "PKX", "PRG", "PVG", "RUH", "SAI", "SEA", "SEZ", "SFO", "SGN", "SHJ",
        "SIN", "SKT", "STN", "SYD", "SZX", "TEV", "TLS", "TNR", "TPE", "TRV",
        "TUN", "UIO", "VCE", "VIE", "WAW", "XMN", "YUL", "YYZ", "ZAZ", "ZRH"
    ]

    /// Returns true if the given code is a valid Emirates destination.
    static func isValid(_ code: String) -> Bool {
        codes.contains(code.uppercased())
    }
}
