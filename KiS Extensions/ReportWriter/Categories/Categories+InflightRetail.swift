//
//  Categories+InflightRetail.swift
//  KiS Extensions — ReportWriter
//
//  GENERATED FILE. Do not edit by hand.
//  Parent category: "Inflight retail"
//

import Foundation

enum Categories_inflightRetail {

    // MARK: - Cat2 options
    static let cat2List: [String] = [
        "Customer Feedback",
        "Donation",
        "EmiratesRED NIL Sale",
        "Equipment",
        "Item Issues",
        "Onboard seat sales",
        "Paperwork",
        "Pre Order",
        "Restart Phase 2 Sales",
    ]

    // MARK: - Cat3 lookup
    static func cat3List(cat2: String) -> [String] {
        switch cat2 {
        case "Donation":
            return [
                "Card Payment",
                "Cash Payment",
            ]
        case "Equipment":
            return [
                "Hand Held Computer",
                "LivePOS",
            ]
        case "Item Issues":
            return [
                "Defective",
                "Excess",
                "Missing",
            ]
        case "Onboard seat sales":
            return [
                "Bulkhead Seat",
                "Extra Legroom seat",
                "Premium Economy",
                "Upgrade",
            ]
        case "Paperwork":
            return [
                "ABC",
                "Trip Record",
                "UCCCF",
            ]
        case "Pre Order":
            return [
                "Customer feedback",
                "Delivery",
                "Orders",
                "Process feedback",
            ]
        case "Restart Phase 2 Sales":
            return [
                "Donation",
                "Extra Legroom Seat",
                "Premium Extra Legroom seat",
                "Upgrade",
            ]
        default: return []
        }
    }

    // MARK: - Cat4 lookup
    static func cat4List(cat2: String, cat3: String) -> [String] {
        switch (cat2, cat3) {
        case ("Donation", "Card Payment"):
            return [
                "Amount/Approval Code/Terminal No/Receipt No",
            ]
        case ("Equipment", "Hand Held Computer"):
            return [
                "HHC No",
            ]
        case ("Equipment", "LivePOS"):
            return [
                "LivePOS Serial No",
            ]
        case ("Onboard seat sales", "Bulkhead Seat"):
            return [
                "Amount/Approval Code/Terminal No/Receipt No",
            ]
        case ("Onboard seat sales", "Extra Legroom seat"):
            return [
                "Amount/Approval Code/Terminal No/Receipt No",
            ]
        case ("Onboard seat sales", "Premium Economy"):
            return [
                "Amount/Approval Code/Terminal No/Receipt No",
            ]
        case ("Onboard seat sales", "Upgrade"):
            return [
                "Amount/Approval Code/Terminal No/Receipt No",
            ]
        case ("Pre Order", "Delivery"):
            return [
                "Customer not on board",
                "Customer rejecting order",
                "Customer identification issues",
            ]
        case ("Pre Order", "Orders"):
            return [
                "Order missing",
                "Item(s) missing",
                "Item(s) damaged",
            ]
        case ("Pre Order", "Process feedback"):
            return [
                "Seals and locks",
                "Paperwork",
                "Crew suggestions",
            ]
        case ("Restart Phase 2 Sales", "Donation"):
            return [
                "Amount/Approval Code/Terminal No/Receipt No",
            ]
        case ("Restart Phase 2 Sales", "Extra Legroom Seat"):
            return [
                "Amount/Approval Code/Terminal No/Receipt No",
            ]
        case ("Restart Phase 2 Sales", "Premium Extra Legroom seat"):
            return [
                "Amount/Approval Code/Terminal No/Receipt No",
            ]
        case ("Restart Phase 2 Sales", "Upgrade"):
            return [
                "Amount/Approval Code/Terminal No/Receipt No",
            ]
        default: return []
        }
    }
}
