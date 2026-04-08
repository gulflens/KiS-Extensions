//
//  Categories+Medical.swift
//  KiS Extensions — ReportWriter
//
//  GENERATED FILE. Do not edit by hand.
//  Parent category: "Medical"
//

import Foundation

enum Categories_medical {

    // MARK: - Cat2 options
    static let cat2List: [String] = [
        "Crew",
        "EMK/FAK/SEMK/UPK Fault-Issue",
        "EquipmentFault-Issue",
        "Passenger",
    ]

    // MARK: - Cat3 lookup
    static func cat3List(cat2: String) -> [String] {
        switch cat2 {
        case "Crew":
            return [
                "Injury/ Accident",
            ]
        case "Passenger":
            return [
                "Illness",
                "Injury/ Accident",
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
