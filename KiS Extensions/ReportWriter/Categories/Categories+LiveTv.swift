//
//  Categories+LiveTv.swift
//  KiS Extensions — ReportWriter
//
//  GENERATED FILE. Do not edit by hand.
//  Parent category: "Live TV"
//

import Foundation

enum Categories_liveTv {

    // MARK: - Cat2 options
    static let cat2List: [String] = [
        "Live Sport feature on KiS",
        "Not available",
        "Quality",
    ]

    // MARK: - Cat3 lookup
    static func cat3List(cat2: String) -> [String] {
        switch cat2 {
        case "Live Sport feature on KiS":
            return [
                "Event news missing",
                "Event news wrong",
                "Feature not available",
                "Suggestions",
            ]
        case "Not available":
            return [
                "All channels",
                "Specific channel",
            ]
        case "Quality":
            return [
                "Audio quality",
                "Image quality",
            ]
        default: return []
        }
    }

    // MARK: - Cat4 lookup
    static func cat4List(cat2: String, cat3: String) -> [String] {
        switch (cat2, cat3) {
        case ("Not available", "Specific channel"):
            return [
                "Sport 24",
                "Sport 24 Extra",
                "CNN",
                "BBC",
            ]
        case ("Quality", "Audio quality"):
            return [
                "Jittering",
                "Clarity",
            ]
        case ("Quality", "Image quality"):
            return [
                "Jittering",
                "Clarity",
                "Blackouts",
            ]
        default: return []
        }
    }
}
