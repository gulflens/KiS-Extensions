//
//  Categories+Kis.swift
//  KiS Extensions — ReportWriter
//
//  GENERATED FILE. Do not edit by hand.
//  Parent category: "KIS"
//

import Foundation

enum Categories_kis {

    // MARK: - Cat2 options
    static let cat2List: [String] = [
        "Crew WiFi",
        "FNB Application",
        "Hotspot",
        "KIS Application",
        "KIS Tablet",
        "No Connection",
        "Printer",
        "SIM Connectivity",
        "iPhone",
    ]

    // MARK: - Cat3 lookup
    static func cat3List(cat2: String) -> [String] {
        switch cat2 {
        case "Crew WiFi":
            return [
                "KIS Device unable to connect",
                "OnBoard WiFi unavailable",
            ]
        case "FNB Application":
            return [
                "Menu Items",
                "Non-Responsive",
                "Suggestions",
                "Synchronisation issue",
            ]
        case "Hotspot":
            return [
                "Lost/Stolen/Damaged",
                "Non-Responsive",
            ]
        case "KIS Application":
            return [
                "Crew Position",
                "Customer Information",
                "Flight Final not received",
                "Flight not downloaded",
                "Functionality",
                "IBDN/Delayed Baggage",
                "Info Missing/Wrong",
                "MFP (My Flight Performance)",
                "Non-Responsive",
                "Other Issues",
                "P.C Tablet Problems",
                "Performance",
                "Suggestions",
                "Synchronisation issue",
                "Unable to close flight",
            ]
        case "KIS Tablet":
            return [
                "Lost/Stolen/Damaged",
                "Non-Responsive",
                "OME / Manuals Update",
            ]
        case "No Connection":
            return [
                "DXB",
                "Outstation",
            ]
        case "Printer":
            return [
                "Cable Lost/Damaged/Not Loaded",
                "Printer Inoperative",
            ]
        case "iPhone":
            return [
                "Application Updates",
                "Lost/Stolen/Damaged",
                "Non-Responsive",
            ]
        default: return []
        }
    }

    // MARK: - Cat4 lookup
    static func cat4List(cat2: String, cat3: String) -> [String] {
        switch (cat2, cat3) {
        case ("Crew WiFi", "OnBoard WiFi unavailable"):
            return [
                "B777 UAECREW2",
                "A380 uaecrew",
            ]
        case ("FNB Application", "Menu Items"):
            return [
                "No Menu",
                "Meal Items Missing",
                "Drinks Missing",
                "Wine Missing",
            ]
        case ("FNB Application", "Synchronisation issue"):
            return [
                "MOD to KIS",
                "MOD to MOD",
            ]
        case ("KIS Application", "Customer Information"):
            return [
                "Missing Customer",
                "Customer Count",
                "Customer Name/Seat",
                "Special Assistance",
                "Seat Swap",
            ]
        case ("KIS Application", "Synchronisation issue"):
            return [
                "KIS to KIS",
                "KIS to MOD",
            ]
        default: return []
        }
    }
}
