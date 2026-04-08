//
//  Categories+Security.swift
//  KiS Extensions — ReportWriter
//
//  GENERATED FILE. Do not edit by hand.
//  Parent category: "Security"
//

import Foundation

enum Categories_security {

    // MARK: - Cat2 options
    static let cat2List: [String] = [
        "Airport",
        "Airport Security",
        "Bomb Threat",
        "Cargo Flight",
        "Disruptive/ Alcohol",
        "Disruptive/ Non- Alc",
        "Disruptive/Unruly Behaviour - Level 1",
        "Disruptive/Unruly Behaviour - Level 2",
        "Disruptive/Unruly Behaviour - Level 3",
        "Disruptive/Unruly Behaviour - Level 4",
        "Onboard security",
        "Passenger Behaviour",
        "Passenger Load Error",
        "Passports",
    ]

    // MARK: - Cat3 lookup
    static func cat3List(cat2: String) -> [String] {
        switch cat2 {
        case "Airport":
            return [
                "DXB",
                "Outstation",
            ]
        case "Airport Security":
            return [
                "DXB",
                "Outstation",
            ]
        case "Bomb Threat":
            return [
                "In-flight",
                "On ground",
            ]
        case "Cargo Flight":
            return [
                "General Feedback",
                "Security Seacrh",
            ]
        case "Disruptive/ Alcohol":
            return [
                "Disregard to Safety",
                "Indecent Exposure",
                "Physical Abuse",
                "Refusal to Comply",
                "Sexual Harrassment",
                "Verbal Abuse",
            ]
        case "Disruptive/ Non- Alc":
            return [
                "Disregard to Safety",
                "Indecent Exposure",
                "Physical Abuse",
                "Refusal to Comply",
                "Sexual Harrassment",
                "Verbal Abuse",
            ]
        case "Disruptive/Unruly Behaviour - Level 1":
            return [
                "Alcohol consumption",
                "Boisterous/lively/excitable as part of group",
                "Causing discomfort",
                "Inappropriate verbal abuse/harassment-Pax to Crew",
                "Inappropriate verbal abuse/harassment-Pax to Pax",
                "Non-compliance to instructions",
                "Non-compliant with Safety & Security Regulations",
                "Non-compliant with company Policies",
                "Unacceptable gestures",
                "Unacceptable language and gestures-Pax to Crew",
                "Unacceptable language and gestures-Pax to Pax",
                "Verbal abuse",
            ]
        case "Disruptive/Unruly Behaviour - Level 2":
            return [
                "Damage to EK property",
                "Obscene or lewd physical contact - Pax to Crew",
                "Obscene or lewd physical contact - Pax to Pax",
                "Obscene/lewd Behaviour",
                "Physical abuse/aggression",
                "Physically abusive behaviour - Pax to Crew",
                "Physically abusive behaviour - Pax to Pax",
                "Sexual harassment",
                "Tampering with safety and emergency equipment",
                "Verbal threat",
                "Verbal threats - Pax to Crew",
                "Verbal threats - Pax to Pax",
            ]
        case "Disruptive/Unruly Behaviour - Level 3":
            return [
                "Actions threatening own life",
                "Actions threatening the safe operation of aircraft",
                "Intent or threat to injure",
                "Physical assault with intent to injure Pax to Crew",
                "Physical assault with intent to injure-Pax to Pax",
                "Sexual assault with intent to injure Pax to Crew",
                "Sexual assault with intent to injure Pax to Pax",
                "Threat, display or use of a weapon - Pax to Crew",
                "Threat, display or use of a weapon - Pax to Pax",
            ]
        case "Disruptive/Unruly Behaviour - Level 4":
            return [
                "Actions that render aircraft incapable of flight",
                "Attempt to seize/gain control of the aircraft",
                "Attempted/unauthorized intrusion into flight deck",
                "Flight deck",
                "No Formal Warning-No Restraint- No Authorities",
            ]
        case "Onboard security":
            return [
                "Access Control - Aircraft",
                "Access Control - Flight Deck",
                "Carriage of valuable cargo",
                "Data breaches",
                "Deportee",
                "Forwarding of lost and found item",
                "Fraud",
                "Group Security Staff - DXB",
                "INADs/DEPOs/Person in Custody",
                "Security audit and inspections",
                "Security search – DXB",
                "Security search/check",
                "Suspected drug trafficking",
                "Suspected human trafficking",
                "Suspected wildlife trafficking",
                "Theft/Suspected Theft",
                "Threat to Aircraft-On-ground",
                "Threat to aircarft - In-flight",
            ]
        case "Passenger Behaviour":
            return [
                "Non Compliance",
            ]
        case "Passenger Load Error":
            return [
                "Extra",
                "Less",
            ]
        case "Passports":
            return [
                "Found",
                "Lost",
            ]
        default: return []
        }
    }

    // MARK: - Cat4 lookup
    static func cat4List(cat2: String, cat3: String) -> [String] {
        switch (cat2, cat3) {
        case ("Airport Security", "DXB"):
            return [
                "Customs",
                "Immigration",
                "Police",
            ]
        case ("Airport Security", "Outstation"):
            return [
                "Customs",
                "Immigration",
                "Police",
            ]
        case ("Disruptive/ Alcohol", "Disregard to Safety"):
            return [
                "Offloaded DXB",
                "Offloaded Outstation",
                "Restrained",
                "Formal Warning Given",
                "Resolved No Action",
                "Police/ Sec Called",
                "Flight Diverted",
            ]
        case ("Disruptive/ Alcohol", "Indecent Exposure"):
            return [
                "Offloaded DXB",
                "Offloaded Outstation",
                "Restrained",
                "Formal Warning Given",
                "Resolved No Action",
                "Police/ Sec Called",
                "Flight Diverted",
            ]
        case ("Disruptive/ Alcohol", "Physical Abuse"):
            return [
                "Restrained",
                "Offloaded DXB",
                "Offloaded Outstation",
                "Police/ Sec Called",
                "Resolved No Action",
                "Flight Diverted",
                "Formal Warning Given",
            ]
        case ("Disruptive/ Alcohol", "Refusal to Comply"):
            return [
                "Offloaded DXB",
                "Offloaded Outstation",
                "Formal Warning Given",
                "Restrained",
                "Resolved No Action",
                "Police/ Sec Called",
                "Flight Diverted",
            ]
        case ("Disruptive/ Alcohol", "Sexual Harrassment"):
            return [
                "Offloaded DXB",
                "Offloaded Outstation",
                "Resolved No Action",
                "Restrained",
                "Formal Warning Given",
                "Flight Diverted",
                "Police/ Sec Called",
            ]
        case ("Disruptive/ Alcohol", "Verbal Abuse"):
            return [
                "Offloaded DXB",
                "Offloaded Outstation",
                "Resolved No Action",
                "Restrained",
                "Formal Warning Given",
                "Police/ Sec Called",
                "Flight Diverted",
            ]
        case ("Disruptive/ Non- Alc", "Disregard to Safety"):
            return [
                "Offloaded DXB",
                "Offloaded Outstation",
                "Restrained",
                "Resolved No Action",
                "Police/ Sec Called",
                "Formal Warning Given",
                "Flight Diverted",
            ]
        case ("Disruptive/ Non- Alc", "Indecent Exposure"):
            return [
                "Offloaded DXB",
                "Offloaded Outstation",
                "Resolved No Action",
                "Restrained",
                "Police/ Sec Called",
                "Flight Diverted",
                "Formal Warning Given",
            ]
        case ("Disruptive/ Non- Alc", "Physical Abuse"):
            return [
                "Offloaded DXB",
                "Offloaded Outstation",
                "Resolved No Action",
                "Restrained",
                "Formal Warning Given",
                "Flight Diverted",
                "Police/ Sec Called",
            ]
        case ("Disruptive/ Non- Alc", "Refusal to Comply"):
            return [
                "Offloaded DXB",
                "Offloaded Outstation",
                "Resolved No Action",
                "Restrained",
                "Formal Warning Given",
                "Flight Diverted",
                "Police/ Sec Called",
            ]
        case ("Disruptive/ Non- Alc", "Sexual Harrassment"):
            return [
                "Resolved No Action",
                "Restrained",
                "Offloaded DXB",
                "Offloaded Outstation",
                "Flight Diverted",
                "Formal Warning Given",
                "Police/ Sec Called",
            ]
        case ("Disruptive/ Non- Alc", "Verbal Abuse"):
            return [
                "Offloaded DXB",
                "Offloaded Outstation",
                "Resolved No Action",
                "Restrained",
                "Police/ Sec Called",
                "Formal Warning Given",
                "Flight Diverted",
            ]
        case ("Disruptive/Unruly Behaviour - Level 1", "Alcohol consumption"):
            return [
                "Drinking own alcohol",
                "Under age consumption",
                "Intoxication",
            ]
        case ("Disruptive/Unruly Behaviour - Level 1", "Boisterous/lively/excitable as part of group"):
            return [
                "Formal Warning-No Authorities",
                "Formal Warning-Called Authorities",
                "No Formal Warning-Called Authorities",
                "No Formal Warning-No Authorities",
            ]
        case ("Disruptive/Unruly Behaviour - Level 1", "Causing discomfort"):
            return [
                "Shouting/screaming/arguing",
                "Photos/videos",
                "Other",
            ]
        case ("Disruptive/Unruly Behaviour - Level 1", "Inappropriate verbal abuse/harassment-Pax to Crew"):
            return [
                "Formal Warning-No Authorities",
                "Formal Warning-Called Authorities",
                "No Formal Warning-Called Authorities",
                "No Formal Warning-No Authorities",
            ]
        case ("Disruptive/Unruly Behaviour - Level 1", "Inappropriate verbal abuse/harassment-Pax to Pax"):
            return [
                "Formal Warning-No Authorities",
                "Formal Warning-Called Authorities",
                "No Formal Warning-Called Authorities",
                "No Formal Warning-No Authorities",
            ]
        case ("Disruptive/Unruly Behaviour - Level 1", "Non-compliance to instructions"):
            return [
                "PPE mask (Covid)",
                "Continuous non-compliance",
            ]
        case ("Disruptive/Unruly Behaviour - Level 1", "Non-compliant with Safety & Security Regulations"):
            return [
                "Formal Warning-No Authorities",
                "Formal Warning-Called Authorities",
                "No Formal Warning-Called Authorities",
                "No Formal Warning-No Authorities",
            ]
        case ("Disruptive/Unruly Behaviour - Level 1", "Non-compliant with company Policies"):
            return [
                "Formal Warning-No Authorities",
                "Formal Warning-Called Authorities",
                "No Formal Warning-Called Authorities",
                "No Formal Warning-No Authorities",
            ]
        case ("Disruptive/Unruly Behaviour - Level 1", "Unacceptable gestures"):
            return [
                "Passenger to crew",
                "Passenger to passenger",
            ]
        case ("Disruptive/Unruly Behaviour - Level 1", "Unacceptable language and gestures-Pax to Crew"):
            return [
                "Formal Warning-No Authorities",
                "Formal Warning-Called Authorities",
                "No Formal Warning-Called Authorities",
                "No Formal Warning-No Authorities",
            ]
        case ("Disruptive/Unruly Behaviour - Level 1", "Unacceptable language and gestures-Pax to Pax"):
            return [
                "Formal Warning-No Authorities",
                "Formal Warning-Called Authorities",
                "No Formal Warning-Called Authorities",
                "No Formal Warning-No Authorities",
            ]
        case ("Disruptive/Unruly Behaviour - Level 1", "Verbal abuse"):
            return [
                "Passenger to crew",
                "Passenger to passenger",
            ]
        case ("Disruptive/Unruly Behaviour - Level 2", "Damage to EK property"):
            return [
                "Formal Warning-No Authorities",
                "Formal Warning-Called Authorities",
                "No Formal Warning-Called Authorities",
                "No Formal Warning-No Authorities",
            ]
        case ("Disruptive/Unruly Behaviour - Level 2", "Obscene or lewd physical contact - Pax to Crew"):
            return [
                "Formal Warning-No Authorities",
                "Formal Warning-Called Authorities",
                "No Formal Warning-No Authorities",
                "No Formal Warning-Called Authorities",
            ]
        case ("Disruptive/Unruly Behaviour - Level 2", "Obscene or lewd physical contact - Pax to Pax"):
            return [
                "Formal Warning-No Authorities",
                "Formal Warning-Called Authorities",
                "No Formal Warning-Called Authorities",
                "No Formal Warning-No Authorities",
            ]
        case ("Disruptive/Unruly Behaviour - Level 2", "Obscene/lewd Behaviour"):
            return [
                "Passenger to crew",
                "Passenger to passenger",
            ]
        case ("Disruptive/Unruly Behaviour - Level 2", "Physical abuse/aggression"):
            return [
                "Passenger to crew",
                "Passenger to passenger",
            ]
        case ("Disruptive/Unruly Behaviour - Level 2", "Physically abusive behaviour - Pax to Crew"):
            return [
                "Formal Warning-No Authorities",
                "Formal Warning-Called Authorities",
                "No Formal Warning-Called Authorities",
                "No Formal Warning-No Authorities",
            ]
        case ("Disruptive/Unruly Behaviour - Level 2", "Physically abusive behaviour - Pax to Pax"):
            return [
                "Formal Warning-No Authorities",
                "Formal Warning-Called Authorities",
                "No Formal Warning-Called Authorities",
                "No Formal Warning-No Authorities",
            ]
        case ("Disruptive/Unruly Behaviour - Level 2", "Sexual harassment"):
            return [
                "Passenger to crew",
                "Passenger to passenger",
            ]
        case ("Disruptive/Unruly Behaviour - Level 2", "Tampering with safety and emergency equipment"):
            return [
                "Formal Warning-No Authorities",
                "Formal Warning-Called Authorities",
                "No Formal Warning-No Authorities",
                "No Formal Warning-Called Authorities",
            ]
        case ("Disruptive/Unruly Behaviour - Level 2", "Verbal threat"):
            return [
                "Passenger to crew",
                "Passenger to passenger",
            ]
        case ("Disruptive/Unruly Behaviour - Level 2", "Verbal threats - Pax to Crew"):
            return [
                "Formal Warning-No Authorities",
                "Formal Warning-Called Authorities",
                "No Formal Warning-Called Authorities",
                "No Formal Warning-No Authorities",
            ]
        case ("Disruptive/Unruly Behaviour - Level 2", "Verbal threats - Pax to Pax"):
            return [
                "Formal Warning-No Authorities",
                "No Formal Warning-Called Authorities",
                "No Formal Warning-No Authorities",
                "Formal Warning-Called Authorities",
            ]
        case ("Disruptive/Unruly Behaviour - Level 3", "Actions threatening own life"):
            return [
                "Formal Warning-No Restraint-Called Authorities",
                "Formal Warning-No Restraint-No Authorities",
                "Formal Warning-Restraint -Called Authorities",
                "Formal Warning-Restraint -No Authorities",
                "No Formal Warning-No Restraint-Called Authorities",
                "No Formal Warning-No Restraint- No Authorities",
                "No Formal Warning-Restraint-Called Authorities",
                "No Formal Warning-Restraint-No Authorities",
            ]
        case ("Disruptive/Unruly Behaviour - Level 3", "Actions threatening the safe operation of aircraft"):
            return [
                "Formal Warning-No Restraint-Called Authorities",
                "Formal Warning-No Restraint-No Authorities",
                "Formal Warning-Restraint -Called Authorities",
                "Formal Warning-Restraint -No Authorities",
                "No Formal Warning-No Restraint-Called Authorities",
                "No Formal Warning-No Restraint- No Authorities",
                "No Formal Warning-Restraint-No Authorities",
                "No Formal Warning-Restraint-Called Authorities",
            ]
        case ("Disruptive/Unruly Behaviour - Level 3", "Intent or threat to injure"):
            return [
                "Passenger to crew",
                "Passenger to passenger",
            ]
        case ("Disruptive/Unruly Behaviour - Level 3", "Physical assault with intent to injure Pax to Crew"):
            return [
                "Formal Warning-No Restraint-Called Authorities",
                "Formal Warning-No Restraint-No Authorities",
                "Formal Warning-Restraint -Called Authorities",
                "Formal Warning-Restraint -No Authorities",
                "No Formal Warning-No Restraint-Called Authorities",
                "No Formal Warning-No Restraint- No Authorities",
                "No Formal Warning-Restraint-Called Authorities",
                "No Formal Warning-Restraint-No Authorities",
            ]
        case ("Disruptive/Unruly Behaviour - Level 3", "Physical assault with intent to injure-Pax to Pax"):
            return [
                "Formal Warning-No Restraint-Called Authorities",
                "Formal Warning-No Restraint-No Authorities",
                "Formal Warning-Restraint -Called Authorities",
                "Formal Warning-Restraint -No Authorities",
                "No Formal Warning-No Restraint-Called Authorities",
                "No Formal Warning-No Restraint- No Authorities",
                "No Formal Warning-Restraint-Called Authorities",
                "No Formal Warning-Restraint-No Authorities",
            ]
        case ("Disruptive/Unruly Behaviour - Level 3", "Sexual assault with intent to injure Pax to Crew"):
            return [
                "Formal Warning-No Restraint-Called Authorities",
                "Formal Warning-No Restraint-No Authorities",
                "Formal Warning-Restraint -Called Authorities",
                "Formal Warning-Restraint -No Authorities",
                "No Formal Warning-No Restraint-Called Authorities",
                "No Formal Warning-No Restraint- No Authorities",
                "No Formal Warning-Restraint-Called Authorities",
                "No Formal Warning-Restraint-No Authorities",
            ]
        case ("Disruptive/Unruly Behaviour - Level 3", "Sexual assault with intent to injure Pax to Pax"):
            return [
                "Formal Warning-No Restraint-Called Authorities",
                "Formal Warning-No Restraint-No Authorities",
                "Formal Warning-Restraint -Called Authorities",
                "Formal Warning-Restraint -No Authorities",
                "No Formal Warning-No Restraint-Called Authorities",
                "No Formal Warning-No Restraint- No Authorities",
                "No Formal Warning-Restraint-Called Authorities",
                "No Formal Warning-Restraint-No Authorities",
            ]
        case ("Disruptive/Unruly Behaviour - Level 3", "Threat, display or use of a weapon - Pax to Crew"):
            return [
                "Formal Warning-Restraint -No Authorities",
                "Formal Warning-No Restraint-No Authorities",
                "Formal Warning-Restraint -Called Authorities",
                "Formal Warning-No Restraint-Called Authorities",
                "No Formal Warning-No Restraint-Called Authorities",
                "No Formal Warning-No Restraint- No Authorities",
                "No Formal Warning-Restraint-Called Authorities",
                "No Formal Warning-Restraint-No Authorities",
            ]
        case ("Disruptive/Unruly Behaviour - Level 3", "Threat, display or use of a weapon - Pax to Pax"):
            return [
                "Formal Warning-No Restraint-Called Authorities",
                "Formal Warning-No Restraint-No Authorities",
                "Formal Warning-Restraint -Called Authorities",
                "Formal Warning-Restraint -No Authorities",
                "No Formal Warning-No Restraint-Called Authorities",
                "No Formal Warning-No Restraint- No Authorities",
                "No Formal Warning-Restraint-Called Authorities",
                "No Formal Warning-Restraint-No Authorities",
            ]
        case ("Disruptive/Unruly Behaviour - Level 4", "Actions that render aircraft incapable of flight"):
            return [
                "Formal Warning-No Restraint-Called Authorities",
                "Formal Warning-No Restraint-No Authorities",
                "Formal Warning-Restraint -Called Authorities",
                "Formal Warning-Restraint -No Authorities",
                "No Formal Warning-No Restraint-Called Authorities",
                "No Formal Warning-No Restraint- No Authorities",
                "No Formal Warning-Restraint-Called Authorities",
                "No Formal Warning-Restraint-No Authorities",
            ]
        case ("Disruptive/Unruly Behaviour - Level 4", "Attempt to seize/gain control of the aircraft"):
            return [
                "Formal Warning-No Restraint-Called Authorities",
                "Formal Warning-No Restraint-No Authorities",
                "Formal Warning-Restraint -Called Authorities",
                "Formal Warning-Restraint -No Authorities",
                "No Formal Warning-No Restraint-Called Authorities",
                "No Formal Warning-No Restraint- No Authorities",
                "No Formal Warning-Restraint-Called Authorities",
                "No Formal Warning-Restraint-No Authorities",
            ]
        case ("Disruptive/Unruly Behaviour - Level 4", "Attempted/unauthorized intrusion into flight deck"):
            return [
                "Formal Warning-No Restraint-Called Authorities",
                "Formal Warning-No Restraint-No Authorities",
                "Formal Warning-Restraint -Called Authorities",
                "Formal Warning-Restraint -No Authorities",
                "No Formal Warning-No Restraint-Called Authorities",
                "No Formal Warning-No Restraint- No Authorities",
                "No Formal Warning-Restraint-Called Authorities",
                "No Formal Warning-Restraint-No Authorities",
            ]
        case ("Disruptive/Unruly Behaviour - Level 4", "Flight deck"):
            return [
                "Attempted intrusion",
                "Breach of flight deck door",
            ]
        case ("Disruptive/Unruly Behaviour - Level 4", "No Formal Warning-No Restraint- No Authorities"):
            return [
                "Formal Warning-No Restraint-Called Authorities",
                "Formal Warning-No Restraint-No Authorities",
                "Formal Warning-Restraint -Called Authorities",
                "No Formal Warning-No Restraint-Called Authorities",
                "No Formal Warning-No Restraint- No Authorities",
                "No Formal Warning-Restraint-Called Authorities",
                "No Formal Warning-Restraint-No Authorities",
                "Formal Warning-Restraint -No Authorities",
            ]
        case ("Onboard security", "Access Control - Aircraft"):
            return [
                "Before Departure",
                "After Arrival",
            ]
        case ("Onboard security", "Access Control - Flight Deck"):
            return [
                "On-Ground",
                "In-Flight",
            ]
        case ("Onboard security", "Carriage of valuable cargo"):
            return [
                "SOP met",
                "SOP Deviation",
            ]
        case ("Onboard security", "Deportee"):
            return [
                "Deportee accompanied",
                "Deportee unaccompanied",
                "Person (Prisoner) in custody",
            ]
        case ("Onboard security", "Forwarding of lost and found item"):
            return [
                "SOP met",
                "SOP Deviation",
            ]
        case ("Onboard security", "Group Security Staff - DXB"):
            return [
                "Feedback / Issues",
                "Cabin crew searched",
            ]
        case ("Onboard security", "INADs/DEPOs/Person in Custody"):
            return [
                "SOP met",
                "SOP Deviation",
            ]
        case ("Onboard security", "Security audit and inspections"):
            return [
                "DXB",
                "Outstation",
            ]
        case ("Onboard security", "Security search – DXB"):
            return [
                "Feedback on Search Team",
                "Cabin crew searched",
            ]
        case ("Onboard security", "Security search/check"):
            return [
                "Diagram/Cabin crew security checklist",
                "Item Found In-Flight",
                "Item Found Post Arrival",
                "Incorrect security search",
                "Unable to search",
                "Security search & baggage ID",
                "Item Found Pre-Flight",
                "Timings",
                "Security Search Delegation",
                "Feedback on Licensed Service Provider",
                "Headcount Discrepancy",
            ]
        case ("Onboard security", "Suspected drug trafficking"):
            return [
                "No Authorities",
                "Called Authorities",
            ]
        case ("Onboard security", "Suspected human trafficking"):
            return [
                "No Authorities",
                "Called Authorities",
            ]
        case ("Onboard security", "Suspected wildlife trafficking"):
            return [
                "No Authorities",
                "Called Authorities",
            ]
        case ("Onboard security", "Theft/Suspected Theft"):
            return [
                "Aircraft items",
                "Passenger item",
                "Crew item",
            ]
        case ("Onboard security", "Threat to Aircraft-On-ground"):
            return [
                "Informed by VPNC",
                "Informed by Crew",
            ]
        case ("Onboard security", "Threat to aircarft - In-flight"):
            return [
                "Informed by VPNC",
                "Informed by Crew",
            ]
        case ("Passenger Behaviour", "Non Compliance"):
            return [
                "Stowing Hand Baggage",
                "Seat or Seat Area",
                "Lifting Hand Baggage",
                "PPE (Face Mask)",
                "Social Distancing",
                "Personal Items",
                "Lavatory",
                "Loose Items",
            ]
        default: return []
        }
    }
}
