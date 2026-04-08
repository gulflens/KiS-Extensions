//
//  Categories+PasSsqsManuals.swift
//  KiS Extensions — ReportWriter
//
//  GENERATED FILE. Do not edit by hand.
//  Parent category: "PAs, SSQs, Manuals"
//

import Foundation

enum Categories_pasSsqsManuals {

    // MARK: - Cat2 options
    static let cat2List: [String] = [
        "Manuals",
        "PA",
        "SSQ",
    ]

    // MARK: - Cat3 lookup
    static func cat3List(cat2: String) -> [String] {
        switch cat2 {
        case "Manuals":
            return [
                "Business Class",
                "Economy Class",
                "First Class",
                "Policies & Procedures",
                "Service/Training",
                "Station information",
            ]
        case "PA":
            return [
                "After landing",
                "Before take-off",
                "Business Class",
                "During flight",
                "Economy Class",
                "First Class",
                "PA not available",
            ]
        case "SSQ":
            return [
                "Business Class",
                "Economy Class",
                "First Class",
                "Premium Economy Class",
            ]
        default: return []
        }
    }

    // MARK: - Cat4 lookup
    static func cat4List(cat2: String, cat3: String) -> [String] {
        switch (cat2, cat3) {
        case ("Manuals", "Business Class"):
            return [
                "Service/Training manual",
                "Station info manual",
                "Policies & Procedures manual",
            ]
        case ("Manuals", "Economy Class"):
            return [
                "Service/Training manual",
                "Station info manual",
                "Policies & Procedures manual",
            ]
        case ("Manuals", "First Class"):
            return [
                "Service/Training manual",
                "Station info manual",
                "Policies & Procedures manual",
            ]
        case ("PA", "Business Class"):
            return [
                "Before take-off",
                "During flight",
                "After landing",
                "PA not available",
            ]
        case ("PA", "Economy Class"):
            return [
                "PA not available",
                "After landing",
                "During flight",
                "Before take-off",
            ]
        case ("PA", "First Class"):
            return [
                "Before take-off",
                "During flight",
                "After landing",
                "PA not available",
            ]
        case ("SSQ", "Business Class"):
            return [
                "Errors",
                "Does not match menu",
                "Does not match loading",
                "Blankets/duvet/mattress (does not match loading)",
                "Give-aways",
                "Paperwork",
                "Cabin spray",
                "Landing Cards",
            ]
        case ("SSQ", "Economy Class"):
            return [
                "Errors",
                "Does not match menu",
                "Does not match loading",
                "Blankets/duvet/mattress (does not match loading)",
                "Give-aways",
                "Paperwork",
                "Cabin spray",
                "Landing Cards",
            ]
        case ("SSQ", "First Class"):
            return [
                "Errors",
                "Does not match menu",
                "Does not match loading",
                "Blankets/duvet/mattress (does not match loading)",
                "Give-aways",
                "Paperwork",
                "Cabin spray",
                "Landing Cards",
            ]
        case ("SSQ", "Premium Economy Class"):
            return [
                "Errors",
                "Does not match menu",
                "Does not match loading",
                "Blankets/duvet/mattress (does not match loading)",
                "Give-aways",
                "Paperwork",
                "Cabin spray",
                "Landing Cards",
            ]
        default: return []
        }
    }
}
