//
//  Categories+CabinCrew.swift
//  KiS Extensions — ReportWriter
//
//  GENERATED FILE. Do not edit by hand.
//  Parent category: "Cabin Crew"
//

import Foundation

enum Categories_cabinCrew {

    // MARK: - Cat2 options
    static let cat2List: [String] = [
        "Complaints",
        "Compliments",
        "Covid Operation",
        "Fitness - Nutrition",
        "Ground to Pur Msgs",
        "Hotel Feedback",
        "Image - Uniform",
        "MFP Feedback",
        "Payroll adjustments",
        "Peer Support",
        "Performance Feedback",
        "Shortage of language speakers",
    ]

    // MARK: - Cat3 lookup
    static func cat3List(cat2: String) -> [String] {
        switch cat2 {
        case "Complaints":
            return [
                "Crew to Crew",
                "Customer to Crew",
            ]
        case "Compliments":
            return [
                "Crew to Crew",
                "Customer to Crew",
            ]
        case "Covid Operation":
            return [
                "PCR/ Vaccinations",
            ]
        case "Hotel Feedback":
            return [
                "Allowances",
                "Facilities",
                "Food and Beverage",
                "Location",
                "Noise",
                "Room quality",
                "Rooms not ready",
                "Security",
            ]
        case "Image - Uniform":
            return [
                "Training Issues",
                "Uniform Shortfalls",
            ]
        case "Payroll adjustments":
            return [
                "DHD/SK",
                "Meal Allowance",
                "Operating Higher Grade",
            ]
        case "Performance Feedback":
            return [
                "Above expectations",
                "Concerns",
            ]
        default: return []
        }
    }

    // MARK: - Cat4 lookup
    static func cat4List(cat2: String, cat3: String) -> [String] {
        switch (cat2, cat3) {
        case ("Complaints", "Crew to Crew"):
            return [
                "Customer",
                "Inflight Revenue",
                "Effectiveness & Conduct",
                "Leadership",
                "Safety",
            ]
        case ("Complaints", "Customer to Crew"):
            return [
                "Inflight Revenue",
                "Customer",
                "Effectiveness & Conduct",
                "Leadership",
                "Safety",
            ]
        case ("Compliments", "Crew to Crew"):
            return [
                "Safety",
                "Leadership",
                "Effectiveness & Conduct",
                "Inflight Revenue",
                "Customer",
            ]
        case ("Compliments", "Customer to Crew"):
            return [
                "Safety",
                "Leadership",
                "Effectiveness & Conduct",
                "Inflight Revenue",
                "Customer",
            ]
        case ("Payroll adjustments", "Operating Higher Grade"):
            return [
                "VCM",
                "Sick Crew",
                "Dead Head Crew",
                "Standby Pull-Out",
            ]
        case ("Performance Feedback", "Above expectations"):
            return [
                "Customer",
                "Effectiveness & Conduct",
                "Inflight Revenue",
                "Leadership",
                "Safety",
            ]
        case ("Performance Feedback", "Concerns"):
            return [
                "Customer",
                "Effectiveness & Conduct",
                "Inflight Revenue",
                "Leadership",
                "Safety",
            ]
        default: return []
        }
    }
}
