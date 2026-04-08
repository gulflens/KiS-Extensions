//
//  Categories+Ife.swift
//  KiS Extensions — ReportWriter
//
//  GENERATED FILE. Do not edit by hand.
//  Parent category: "IFE"
//

import Foundation

enum Categories_ife {

    // MARK: - Cat2 options
    static let cat2List: [String] = [
        "Customer Feedback",
        "Issues",
    ]

    // MARK: - Cat3 lookup
    static func cat3List(cat2: String) -> [String] {
        switch cat2 {
        case "Customer Feedback":
            return [
                "Content suggestion",
                "Other",
            ]
        case "Issues":
            return [
                "IFE unavailable",
                "Other issues",
            ]
        default: return []
        }
    }

    // MARK: - Cat4 lookup
    static func cat4List(cat2: String, cat3: String) -> [String] {
        switch (cat2, cat3) {
        case ("Issues", "IFE unavailable"):
            return [
                "Less than 1 hour",
                "Less than 3 hours",
                "More than 3 hours",
            ]
        case ("Issues", "Other issues"):
            return [
                "Picture quality",
                "Content",
                "Remote/Mode controller",
                "Other",
            ]
        default: return []
        }
    }
}
