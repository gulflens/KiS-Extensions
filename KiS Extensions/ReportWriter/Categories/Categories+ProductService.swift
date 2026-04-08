//
//  Categories+ProductService.swift
//  KiS Extensions — ReportWriter
//
//  GENERATED FILE. Do not edit by hand.
//  Parent category: "Product/Service"
//

import Foundation

enum Categories_productService {

    // MARK: - Cat2 options
    static let cat2List: [String] = [
        "Business Class",
        "Economy Class",
        "First Class",
        "Premium Economy Class",
        "Serve Better JCL (CAT 4-8)",
    ]

    // MARK: - Cat3 lookup
    static func cat3List(cat2: String) -> [String] {
        switch cat2 {
        case "Business Class":
            return [
                "A380 lounge",
                "Deviation",
                "Give aways (e.g. kit bags)",
                "Meal Service",
                "Ready to land",
                "Social area",
                "We care",
                "Welcome service",
            ]
        case "Economy Class":
            return [
                "Deviation",
                "Give aways (e.g. kit bags)",
                "Meal Service",
                "Ready to land",
                "Social area",
                "We care",
                "Welcome service",
            ]
        case "First Class":
            return [
                "Deviation",
                "Drink service",
                "Give aways (e.g. kit bags)",
                "Meal service",
                "Ready to land",
                "Shower spa",
                "Social area",
                "We care",
                "Welcome service",
            ]
        case "Premium Economy Class":
            return [
                "Deviation",
                "Give aways (e.g. kit bags)",
                "Meal Service",
                "Ready to land",
                "Social area",
                "We care",
                "Welcome service",
            ]
        case "Serve Better JCL (CAT 4-8)":
            return [
                "Customer Feedback",
                "One Device",
                "Service Procedure",
            ]
        default: return []
        }
    }

    // MARK: - Cat4 lookup
    static func cat4List(cat2: String, cat3: String) -> [String] {
        switch (cat2, cat3) {
        case ("Business Class", "A380 lounge"):
            return [
                "Service procedures",
                "Product feedback",
                "Delay",
                "Ad-hoc situation",
                "service guide",
            ]
        case ("Business Class", "Deviation"):
            return [
                "Service procedures",
                "Product feedback",
                "Delay",
                "Ad-hoc situation",
                "service guide",
            ]
        case ("Business Class", "Give aways (e.g. kit bags)"):
            return [
                "Service procedures",
                "Product feedback",
                "Delay",
                "Ad-hoc situation",
                "service guide",
                "Loungewear Slippers & Eyemasks",
            ]
        case ("Business Class", "Meal Service"):
            return [
                "Service procedures",
                "Product feedback",
                "Delay",
                "Ad-hoc situation",
                "service guide",
                "MOD",
            ]
        case ("Business Class", "Ready to land"):
            return [
                "Service procedures",
                "Product feedback",
                "Delay",
                "Ad-hoc situation",
                "service guide",
            ]
        case ("Business Class", "Social area"):
            return [
                "Service procedures",
                "Product feedback",
                "Delay",
                "Ad-hoc situation",
                "service guide",
            ]
        case ("Business Class", "We care"):
            return [
                "Service procedures",
                "Product feedback",
                "Delay",
                "Ad-hoc situation",
                "service guide",
            ]
        case ("Business Class", "Welcome service"):
            return [
                "Service procedures",
                "Product feedback",
                "Delay",
                "Ad-hoc situation",
                "service guide",
            ]
        case ("Economy Class", "Deviation"):
            return [
                "Service procedures",
                "Product feedback",
                "Delay",
                "Ad-hoc situation",
                "service guide",
            ]
        case ("Economy Class", "Give aways (e.g. kit bags)"):
            return [
                "Service procedures",
                "Product feedback",
                "Delay",
                "Ad-hoc situation",
                "Service guide",
            ]
        case ("Economy Class", "Meal Service"):
            return [
                "Service procedures",
                "Product feedback",
                "Delay",
                "Ad-hoc situation",
                "Service guide",
            ]
        case ("Economy Class", "Ready to land"):
            return [
                "Service procedures",
                "Product feedback",
                "Delay",
                "Ad-hoc situation",
                "Service guide",
            ]
        case ("Economy Class", "Social area"):
            return [
                "Service procedures",
                "Product feedback",
                "Delay",
                "Ad-hoc situation",
                "Service guide",
            ]
        case ("Economy Class", "We care"):
            return [
                "Service procedures",
                "Product feedback",
                "Delay",
                "Ad-hoc situation",
                "Service guide",
            ]
        case ("Economy Class", "Welcome service"):
            return [
                "Service procedures",
                "Product feedback",
                "Delay",
                "Ad-hoc situation",
                "Service guide",
            ]
        case ("First Class", "Deviation"):
            return [
                "Ad-hoc situation",
                "Delay",
                "Product feedback",
                "Service procedures",
                "Service guide",
            ]
        case ("First Class", "Drink service"):
            return [
                "Service procedures",
                "Product feedback",
                "Delay",
                "Ad-hoc situation",
                "Service guide",
            ]
        case ("First Class", "Give aways (e.g. kit bags)"):
            return [
                "Service procedures",
                "Product feedback",
                "Delay",
                "Ad-hoc situation",
                "Service guide",
            ]
        case ("First Class", "Meal service"):
            return [
                "Service procedures",
                "Product feedback",
                "Delay",
                "Ad-hoc situation",
                "Service guide",
            ]
        case ("First Class", "Ready to land"):
            return [
                "Service procedures",
                "Product feedback",
                "Delay",
                "Ad-hoc situation",
                "Service guide",
            ]
        case ("First Class", "Shower spa"):
            return [
                "Service procedures",
                "Product feedback",
                "Delay",
                "Ad-hoc situation",
                "Service guide",
            ]
        case ("First Class", "Social area"):
            return [
                "Service guide",
                "Service procedures",
                "Product feedback",
                "Delay",
                "Ad-hoc situation",
            ]
        case ("First Class", "We care"):
            return [
                "Service procedures",
                "Product feedback",
                "Delay",
                "Ad-hoc situation",
                "Service guide",
            ]
        case ("First Class", "Welcome service"):
            return [
                "Service guide",
                "Service procedures",
                "Product feedback",
                "Delay",
                "Ad-hoc situation",
            ]
        case ("Premium Economy Class", "Deviation"):
            return [
                "Service procedures",
                "Product feedback",
                "Delay",
                "Ad-hoc situation",
                "service guide",
            ]
        case ("Premium Economy Class", "Give aways (e.g. kit bags)"):
            return [
                "Service procedures",
                "Product feedback",
                "Delay",
                "Ad-hoc situation",
                "Service guide",
            ]
        case ("Premium Economy Class", "Meal Service"):
            return [
                "Service procedures",
                "Product feedback",
                "Delay",
                "Ad-hoc situation",
                "Service guide",
            ]
        case ("Premium Economy Class", "Ready to land"):
            return [
                "Service procedures",
                "Product feedback",
                "Delay",
                "Ad-hoc situation",
                "Service guide",
            ]
        case ("Premium Economy Class", "Social area"):
            return [
                "Service procedures",
                "Product feedback",
                "Delay",
                "Ad-hoc situation",
                "Service guide",
            ]
        case ("Premium Economy Class", "We care"):
            return [
                "Service procedures",
                "Product feedback",
                "Delay",
                "Ad-hoc situation",
                "Service guide",
            ]
        case ("Premium Economy Class", "Welcome service"):
            return [
                "Service procedures",
                "Product feedback",
                "Delay",
                "Ad-hoc situation",
                "Service guide",
            ]
        case ("Serve Better JCL (CAT 4-8)", "Customer Feedback"):
            return [
                "Positive Feedback",
                "Concerns",
            ]
        case ("Serve Better JCL (CAT 4-8)", "One Device"):
            return [
                "F&B App – Plating & Summary Tabs",
                "F&B App – Plating Image Feature",
                "Holders – Usage Feedback",
            ]
        case ("Serve Better JCL (CAT 4-8)", "Service Procedure"):
            return [
                "Full Meal",
                "Dine Anytime",
                "Late Night Dining (LND)",
                "Hot Breakfast/Brunch",
                "Galley Operator",
            ]
        default: return []
        }
    }
}
