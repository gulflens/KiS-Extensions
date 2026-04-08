//
//  Categories+WiFiAndMobile.swift
//  KiS Extensions — ReportWriter
//
//  GENERATED FILE. Do not edit by hand.
//  Parent category: "Wi-Fi & Mobile"
//

import Foundation

enum Categories_wiFiAndMobile {

    // MARK: - Cat2 options
    static let cat2List: [String] = [
        "Mobile",
        "Wi-Fi",
    ]

    // MARK: - Cat3 lookup
    static func cat3List(cat2: String) -> [String] {
        switch cat2 {
        case "Mobile":
            return [
                "Calling issue",
                "Connection issue",
            ]
        case "Wi-Fi":
            return [
                "Free Wi-Fi",
                "Wi-Fi refund",
                "Wi-Fi unavailable",
            ]
        default: return []
        }
    }

    // MARK: - Cat4 lookup
    static func cat4List(cat2: String, cat3: String) -> [String] {
        switch (cat2, cat3) {
        case ("Wi-Fi", "Free Wi-Fi"):
            return [
                "Skywards login issues",
                "Not available",
                "Other",
            ]
        case ("Wi-Fi", "Wi-Fi refund"):
            return [
                "Describe problem/include email",
            ]
        case ("Wi-Fi", "Wi-Fi unavailable"):
            return [
                "Less than 1 hour",
                "Less than 3 hours",
                "More than 3 hours",
            ]
        default: return []
        }
    }
}
