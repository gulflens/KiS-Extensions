//
//  Categories+CabinDefect.swift
//  KiS Extensions — ReportWriter
//
//  GENERATED FILE. Do not edit by hand.
//  Parent category: "Cabin Defect"
//

import Foundation

enum Categories_cabinDefect {

    // MARK: - Cat2 options
    static let cat2List: [String] = [
        "A380 Shower Spa Defect",
        "Galley Defect",
        "Onboard Lounge",
        "Seat Defect",
        "Toilets",
        "Water leakage (Cabin)",
        "Water leakage (Galley)",
        "Water leakage (Toilets)",
    ]

    // MARK: - Cat3 lookup
    static func cat3List(cat2: String) -> [String] {
        switch cat2 {
        case "Galley Defect":
            return [
                "A380 Cart lift",
                "Chillers",
                "Coffee makers",
                "Espresso makers",
                "Galley Pull-out Table",
                "Microwave",
                "Ovens",
                "Trash Compactors",
            ]
        default: return []
        }
    }

    // MARK: - Cat4 lookup
    static func cat4List(cat2: String, cat3: String) -> [String] {
        switch (cat2, cat3) {
        // No Cat4 level under this Cat1
        default: return []
        }
    }
}
