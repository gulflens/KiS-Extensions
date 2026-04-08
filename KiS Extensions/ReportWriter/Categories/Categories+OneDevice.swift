//
//  Categories+OneDevice.swift
//  KiS Extensions — ReportWriter
//
//  GENERATED FILE. Do not edit by hand.
//  Parent category: "One Device"
//

import Foundation

enum Categories_oneDevice {

    // MARK: - Cat2 options
    static let cat2List: [String] = [
        "Connectivity",
        "Customer List",
        "Device issues",
        "FNB App",
        "Inventory",
        "Lost/Stolen/Damaged",
        "Other issues",
        "Printer",
        "Suggestions",
        "iPhone & iOS",
    ]

    // MARK: - Cat3 lookup
    static func cat3List(cat2: String) -> [String] {
        switch cat2 {
        case "Connectivity":
            return [
                "Net gear",
                "Net gear Login",
                "Sync issues",
                "Wi-Fi",
                "sim card",
            ]
        case "Customer List":
            return [
                "Failure to match final load",
            ]
        case "Device issues":
            return [
                "Miscellaneous",
            ]
        case "Inventory":
            return [
                "Distribution etc.",
            ]
        case "Printer":
            return [
                "Cable Lost/Damaged/Not Loaded",
                "Printer Inoperative",
            ]
        case "Suggestions":
            return [
                "Areas for improvement",
                "Positive feedback",
            ]
        default: return []
        }
    }

    // MARK: - Cat4 lookup
    static func cat4List(cat2: String, cat3: String) -> [String] {
        switch (cat2, cat3) {
        case ("Connectivity", "Net gear Login"):
            return [
                "Login prompt issues",
            ]
        case ("Connectivity", "Sync issues"):
            return [
                "Device to device",
            ]
        default: return []
        }
    }
}
