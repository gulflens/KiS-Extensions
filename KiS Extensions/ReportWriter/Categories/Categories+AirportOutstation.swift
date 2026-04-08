//
//  Categories+AirportOutstation.swift
//  KiS Extensions — ReportWriter
//
//  GENERATED FILE. Do not edit by hand.
//  Parent category: "Airport - Outstation"
//

import Foundation

enum Categories_airportOutstation {

    // MARK: - Cat2 options
    static let cat2List: [String] = [
        "Baggage Issues",
        "Boarding",
        "Cleaning Issues",
        "Complaints",
        "Compliments",
        "Excess Baggage",
        "Image - Uniform",
        "Landing Cards",
        "Lost and Found",
        "Mishandled Baggage",
        "Seating",
        "UM/YP standards/procedures not Met",
        "WCH Handling Problem",
    ]

    // MARK: - Cat3 lookup
    static func cat3List(cat2: String) -> [String] {
        switch cat2 {
        case "Cleaning Issues":
            return [
                "Business Class",
                "Economy Class",
                "First Class",
            ]
        case "Seating":
            return [
                "Seating Swaps/Changes",
                "Seating discrepancy",
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
