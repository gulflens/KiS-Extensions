//
//  Categories+TrainingDepartment.swift
//  KiS Extensions — ReportWriter
//
//  GENERATED FILE. Do not edit by hand.
//  Parent category: "Training Department"
//

import Foundation

enum Categories_trainingDepartment {

    // MARK: - Cat2 options
    static let cat2List: [String] = [
        "Safety",
        "Security",
        "Service",
    ]

    // MARK: - Cat3 lookup
    static func cat3List(cat2: String) -> [String] {
        switch cat2 {
        case "Safety":
            return [
                "OME Feedback",
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
