//
//  Categories+Transport.swift
//  KiS Extensions — ReportWriter
//
//  GENERATED FILE. Do not edit by hand.
//  Parent category: "Transport"
//

import Foundation

enum Categories_transport {

    // MARK: - Cat2 options
    static let cat2List: [String] = [
        "Base (Dubai)",
        "Outstation",
    ]

    // MARK: - Cat3 lookup
    static func cat3List(cat2: String) -> [String] {
        switch cat2 {
        case "Base (Dubai)":
            return [
                "Chauffeur Drive",
                "Crew Transport Base",
            ]
        case "Outstation":
            return [
                "Chauffeur Drive",
                "Crew Transport",
            ]
        default: return []
        }
    }

    // MARK: - Cat4 lookup
    static func cat4List(cat2: String, cat3: String) -> [String] {
        switch (cat2, cat3) {
        case ("Base (Dubai)", "Crew Transport Base"):
            return [
                "Driver Behaviour",
                "On Time Performance",
                "Safety",
                "Vehicle Standard",
            ]
        case ("Outstation", "Crew Transport"):
            return [
                "Driver Behaviour",
                "On Time Performance – Hotel Pickup",
                "Safety",
                "Vehicle Standard",
                "On Time Performance – Airport Pickup",
            ]
        default: return []
        }
    }
}
