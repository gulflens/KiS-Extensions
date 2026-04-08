//
//  Categories+EmiratesSkywards.swift
//  KiS Extensions — ReportWriter
//
//  GENERATED FILE. Do not edit by hand.
//  Parent category: "Emirates Skywards"
//

import Foundation

enum Categories_emiratesSkywards {

    // MARK: - Cat2 options
    static let cat2List: [String] = [
        "Transactions",
        "iO Members",
    ]

    // MARK: - Cat3 lookup
    static func cat3List(cat2: String) -> [String] {
        switch cat2 {
        case "Transactions":
            return [
                "Skywards Upgrades",
            ]
        default: return []
        }
    }

    // MARK: - Cat4 lookup
    static func cat4List(cat2: String, cat3: String) -> [String] {
        switch (cat2, cat3) {
        case ("Transactions", "Skywards Upgrades"):
            return [
                "Refund Skywards Miles",
                "Redeem Skywards Miles",
            ]
        default: return []
        }
    }
}
