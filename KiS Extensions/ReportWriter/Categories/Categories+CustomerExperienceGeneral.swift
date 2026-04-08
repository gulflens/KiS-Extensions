//
//  Categories+CustomerExperienceGeneral.swift
//  KiS Extensions — ReportWriter
//
//  GENERATED FILE. Do not edit by hand.
//  Parent category: "Customer Experience-General"
//

import Foundation

enum Categories_customerExperienceGeneral {

    // MARK: - Cat2 options
    static let cat2List: [String] = [
        "Non-Crew related",
    ]

    // MARK: - Cat3 lookup
    static func cat3List(cat2: String) -> [String] {
        switch cat2 {
        case "Non-Crew related":
            return [
                "Concerns/Requests",
                "Overall Positive experience",
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
