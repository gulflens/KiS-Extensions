//
//  Categories.swift
//  KiS Extensions — ReportWriter
//
//  GENERATED FILE. Do not edit by hand.
//  Regenerate when the official KiS category master list changes.
//

import Foundation

// MARK: - Top-level category

enum KiSCategory1: String, CaseIterable, Codable, Hashable {
    case aircraftDevelopment = "Aircraft Development"
    case airportDubai = "Airport - Dubai"
    case airportOutstation = "Airport - Outstation"
    case cabinCrew = "Cabin Crew"
    case cabinDefect = "Cabin Defect"
    case cargoDocuments = "Cargo documents"
    case catering = "Catering"
    case crewRestInflight = "Crew Rest Inflight"
    case customerExperienceGeneral = "Customer Experience-General"
    case etechlogTrials = "ETechLog Trials"
    case emiratesSkywards = "Emirates Skywards"
    case ife = "IFE"
    case inflightRetail = "Inflight retail"
    case kis = "KIS"
    case liveTv = "Live TV"
    case medical = "Medical"
    case noIncidentToReport = "No incident to report"
    case oneDevice = "One Device"
    case pasSsqsManuals = "PAs, SSQs, Manuals"
    case productService = "Product/Service"
    case resSpmlNonSkywards = "Res SPML/Non-Skywards"
    case security = "Security"
    case spillageCold = "Spillage (Cold)"
    case trainingDepartment = "Training Department"
    case transport = "Transport"
    case wiFiAndMobile = "Wi-Fi & Mobile"

    /// All Cat1 raw values as strings — pass to @Guide(.anyOf(...)) for guided generation.
    static var allRawValues: [String] {
        allCases.map(\.rawValue)
    }
}

// MARK: - Tree navigation API
//
// Each Cat1 has its own file (Categories+<Name>.swift) that exposes its sub-tree.
// This file provides the unified API the KiSAgent calls.

enum CategoryTree {

    /// Returns the list of Cat2 options under the given Cat1.
    /// Empty array means the Cat1 is a leaf (has no children).
    static func cat2List(under cat1: KiSCategory1) -> [String] {
        switch cat1 {
        case .aircraftDevelopment: return Categories_aircraftDevelopment.cat2List
        case .airportDubai: return Categories_airportDubai.cat2List
        case .airportOutstation: return Categories_airportOutstation.cat2List
        case .cabinCrew: return Categories_cabinCrew.cat2List
        case .cabinDefect: return Categories_cabinDefect.cat2List
        case .cargoDocuments: return Categories_cargoDocuments.cat2List
        case .catering: return Categories_catering.cat2List
        case .crewRestInflight: return Categories_crewRestInflight.cat2List
        case .customerExperienceGeneral: return Categories_customerExperienceGeneral.cat2List
        case .etechlogTrials: return Categories_etechlogTrials.cat2List
        case .emiratesSkywards: return Categories_emiratesSkywards.cat2List
        case .ife: return Categories_ife.cat2List
        case .inflightRetail: return Categories_inflightRetail.cat2List
        case .kis: return Categories_kis.cat2List
        case .liveTv: return Categories_liveTv.cat2List
        case .medical: return Categories_medical.cat2List
        case .noIncidentToReport: return Categories_noIncidentToReport.cat2List
        case .oneDevice: return Categories_oneDevice.cat2List
        case .pasSsqsManuals: return Categories_pasSsqsManuals.cat2List
        case .productService: return Categories_productService.cat2List
        case .resSpmlNonSkywards: return Categories_resSpmlNonSkywards.cat2List
        case .security: return Categories_security.cat2List
        case .spillageCold: return Categories_spillageCold.cat2List
        case .trainingDepartment: return Categories_trainingDepartment.cat2List
        case .transport: return Categories_transport.cat2List
        case .wiFiAndMobile: return Categories_wiFiAndMobile.cat2List
        }
    }

    /// Returns the list of Cat3 options under the given Cat1 > Cat2.
    /// Empty array means that Cat2 is a leaf.
    static func cat3List(under cat1: KiSCategory1, cat2: String) -> [String] {
        switch cat1 {
        case .aircraftDevelopment: return Categories_aircraftDevelopment.cat3List(cat2: cat2)
        case .airportDubai: return Categories_airportDubai.cat3List(cat2: cat2)
        case .airportOutstation: return Categories_airportOutstation.cat3List(cat2: cat2)
        case .cabinCrew: return Categories_cabinCrew.cat3List(cat2: cat2)
        case .cabinDefect: return Categories_cabinDefect.cat3List(cat2: cat2)
        case .cargoDocuments: return Categories_cargoDocuments.cat3List(cat2: cat2)
        case .catering: return Categories_catering.cat3List(cat2: cat2)
        case .crewRestInflight: return Categories_crewRestInflight.cat3List(cat2: cat2)
        case .customerExperienceGeneral: return Categories_customerExperienceGeneral.cat3List(cat2: cat2)
        case .etechlogTrials: return Categories_etechlogTrials.cat3List(cat2: cat2)
        case .emiratesSkywards: return Categories_emiratesSkywards.cat3List(cat2: cat2)
        case .ife: return Categories_ife.cat3List(cat2: cat2)
        case .inflightRetail: return Categories_inflightRetail.cat3List(cat2: cat2)
        case .kis: return Categories_kis.cat3List(cat2: cat2)
        case .liveTv: return Categories_liveTv.cat3List(cat2: cat2)
        case .medical: return Categories_medical.cat3List(cat2: cat2)
        case .noIncidentToReport: return Categories_noIncidentToReport.cat3List(cat2: cat2)
        case .oneDevice: return Categories_oneDevice.cat3List(cat2: cat2)
        case .pasSsqsManuals: return Categories_pasSsqsManuals.cat3List(cat2: cat2)
        case .productService: return Categories_productService.cat3List(cat2: cat2)
        case .resSpmlNonSkywards: return Categories_resSpmlNonSkywards.cat3List(cat2: cat2)
        case .security: return Categories_security.cat3List(cat2: cat2)
        case .spillageCold: return Categories_spillageCold.cat3List(cat2: cat2)
        case .trainingDepartment: return Categories_trainingDepartment.cat3List(cat2: cat2)
        case .transport: return Categories_transport.cat3List(cat2: cat2)
        case .wiFiAndMobile: return Categories_wiFiAndMobile.cat3List(cat2: cat2)
        }
    }

    /// Returns the list of Cat4 options under the given Cat1 > Cat2 > Cat3.
    static func cat4List(under cat1: KiSCategory1, cat2: String, cat3: String) -> [String] {
        switch cat1 {
        case .aircraftDevelopment: return Categories_aircraftDevelopment.cat4List(cat2: cat2, cat3: cat3)
        case .airportDubai: return Categories_airportDubai.cat4List(cat2: cat2, cat3: cat3)
        case .airportOutstation: return Categories_airportOutstation.cat4List(cat2: cat2, cat3: cat3)
        case .cabinCrew: return Categories_cabinCrew.cat4List(cat2: cat2, cat3: cat3)
        case .cabinDefect: return Categories_cabinDefect.cat4List(cat2: cat2, cat3: cat3)
        case .cargoDocuments: return Categories_cargoDocuments.cat4List(cat2: cat2, cat3: cat3)
        case .catering: return Categories_catering.cat4List(cat2: cat2, cat3: cat3)
        case .crewRestInflight: return Categories_crewRestInflight.cat4List(cat2: cat2, cat3: cat3)
        case .customerExperienceGeneral: return Categories_customerExperienceGeneral.cat4List(cat2: cat2, cat3: cat3)
        case .etechlogTrials: return Categories_etechlogTrials.cat4List(cat2: cat2, cat3: cat3)
        case .emiratesSkywards: return Categories_emiratesSkywards.cat4List(cat2: cat2, cat3: cat3)
        case .ife: return Categories_ife.cat4List(cat2: cat2, cat3: cat3)
        case .inflightRetail: return Categories_inflightRetail.cat4List(cat2: cat2, cat3: cat3)
        case .kis: return Categories_kis.cat4List(cat2: cat2, cat3: cat3)
        case .liveTv: return Categories_liveTv.cat4List(cat2: cat2, cat3: cat3)
        case .medical: return Categories_medical.cat4List(cat2: cat2, cat3: cat3)
        case .noIncidentToReport: return Categories_noIncidentToReport.cat4List(cat2: cat2, cat3: cat3)
        case .oneDevice: return Categories_oneDevice.cat4List(cat2: cat2, cat3: cat3)
        case .pasSsqsManuals: return Categories_pasSsqsManuals.cat4List(cat2: cat2, cat3: cat3)
        case .productService: return Categories_productService.cat4List(cat2: cat2, cat3: cat3)
        case .resSpmlNonSkywards: return Categories_resSpmlNonSkywards.cat4List(cat2: cat2, cat3: cat3)
        case .security: return Categories_security.cat4List(cat2: cat2, cat3: cat3)
        case .spillageCold: return Categories_spillageCold.cat4List(cat2: cat2, cat3: cat3)
        case .trainingDepartment: return Categories_trainingDepartment.cat4List(cat2: cat2, cat3: cat3)
        case .transport: return Categories_transport.cat4List(cat2: cat2, cat3: cat3)
        case .wiFiAndMobile: return Categories_wiFiAndMobile.cat4List(cat2: cat2, cat3: cat3)
        }
    }

    /// Full path string for a chosen category, joined with " > ".
    static func pathString(cat1: KiSCategory1, cat2: String? = nil, cat3: String? = nil, cat4: String? = nil) -> String {
        [cat1.rawValue, cat2, cat3, cat4].compactMap { $0 }.joined(separator: " > ")
    }
}
