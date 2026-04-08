import Foundation

/// Static library of predefined incident templates.
/// One clean array — update templates by editing this data.
enum TemplateLibrary {
    static let all: [IncidentTemplate] = [
        IncidentTemplate(
            id: "foreign_object_meal",
            displayName: "Foreign object in meal",
            iconName: "fork.knife.circle",
            suggestedCat1: .catering,
            suggestedCat2: "Food",
            suggestedCat3: "Economy Class",
            suggestedCat4: "Foreign Object",
            defaultPhase: .service,
            bulletPlaceholders: [
                "Seat number and class of affected passenger",
                "What was found and in which meal item",
                "Passenger reaction and any health concerns",
                "Item preserved for evidence (yes/no)",
            ],
            suggestedPriority: "Follow up required",
            priorityReasoning: "Foreign object in food requires catering investigation and passenger follow-up"
        ),
        IncidentTemplate(
            id: "loading_shortage_economy",
            displayName: "Loading shortage (Economy)",
            iconName: "takeoutbag.and.cup.and.straw",
            suggestedCat1: .catering,
            suggestedCat2: "Loading",
            suggestedCat3: "Economy Class",
            suggestedCat4: nil,
            defaultPhase: .service,
            bulletPlaceholders: [
                "What was short or not loaded",
                "Number of passengers affected",
                "Alternative offered to passengers",
            ],
            suggestedPriority: "Follow up required",
            priorityReasoning: "Catering loading error affects passenger experience and requires supplier report"
        ),
        IncidentTemplate(
            id: "disruptive_pax_alcohol",
            displayName: "Disruptive passenger (alcohol)",
            iconName: "exclamationmark.triangle",
            suggestedCat1: .security,
            suggestedCat2: "Disruptive/ Alcohol",
            suggestedCat3: "Disregard to Safety",
            suggestedCat4: "Formal Warning Given",
            defaultPhase: .cruise,
            bulletPlaceholders: [
                "Passenger seat number and flight sector",
                "Specific behaviour observed",
                "Number of warnings issued and by whom",
                "Passenger response after warning",
            ],
            suggestedPriority: "Critical",
            priorityReasoning: "Alcohol-related disruptive behaviour is a safety and security matter"
        ),
        IncidentTemplate(
            id: "disruptive_pax_unruly",
            displayName: "Unruly passenger (non-alcohol)",
            iconName: "person.fill.xmark",
            suggestedCat1: .security,
            suggestedCat2: "Disruptive/Unruly Behaviour - Level 1",
            suggestedCat3: "Unacceptable language and gestures-Pax to Crew",
            suggestedCat4: "Formal Warning-No Authorities",
            defaultPhase: .cruise,
            bulletPlaceholders: [
                "Passenger seat number and any witnesses",
                "Exact words or actions observed",
                "Crew member(s) involved and their response",
                "Outcome (calmed down / escalated / restrained)",
            ],
            suggestedPriority: "Critical",
            priorityReasoning: "Unruly behaviour threatens crew safety and requires mandatory reporting"
        ),
        IncidentTemplate(
            id: "seat_defect",
            displayName: "Seat defect",
            iconName: "chair.lounge",
            suggestedCat1: .cabinDefect,
            suggestedCat2: "Seat Defect",
            suggestedCat3: nil,
            suggestedCat4: nil,
            defaultPhase: .boarding,
            bulletPlaceholders: [
                "Seat number and class",
                "Nature of defect (recline, IFE, tray table, etc.)",
                "Passenger reseated (yes/no) and to which seat",
            ],
            suggestedPriority: "Follow up required",
            priorityReasoning: "Seat defect requires tech log entry and engineering follow-up"
        ),
        IncidentTemplate(
            id: "galley_equipment_defect",
            displayName: "Galley equipment defect",
            iconName: "wrench.and.screwdriver",
            suggestedCat1: .cabinDefect,
            suggestedCat2: "Galley Defect",
            suggestedCat3: nil,
            suggestedCat4: nil,
            defaultPhase: .cruise,
            bulletPlaceholders: [
                "Galley position (e.g. galley 4R)",
                "Equipment type and nature of fault",
                "Impact on service delivery",
            ],
            suggestedPriority: "Follow up required",
            priorityReasoning: "Galley equipment failure requires tech log entry"
        ),
        IncidentTemplate(
            id: "pax_medical_illness",
            displayName: "Passenger medical event",
            iconName: "cross.case",
            suggestedCat1: .medical,
            suggestedCat2: "Passenger",
            suggestedCat3: "Illness",
            suggestedCat4: nil,
            defaultPhase: .cruise,
            bulletPlaceholders: [
                "Passenger seat number and age/gender if known",
                "Symptoms reported or observed",
                "Medical kit used (EMK/FAK/SEMK) and items administered",
                "Doctor/nurse onboard assisted (yes/no)",
            ],
            suggestedPriority: "Critical",
            priorityReasoning: "Medical event requires full documentation for regulatory and liability purposes"
        ),
        IncidentTemplate(
            id: "crew_injury",
            displayName: "Crew injury or accident",
            iconName: "bandage",
            suggestedCat1: .medical,
            suggestedCat2: "Crew",
            suggestedCat3: "Injury/ Accident",
            suggestedCat4: nil,
            defaultPhase: .service,
            bulletPlaceholders: [
                "Crew member staff number and grade",
                "How the injury occurred",
                "Body part affected and severity",
                "Crew member continued duty or relieved",
            ],
            suggestedPriority: "Critical",
            priorityReasoning: "Crew injury is a mandatory safety report"
        ),
        IncidentTemplate(
            id: "service_recovery_complaint",
            displayName: "Service complaint and recovery",
            iconName: "hand.raised",
            suggestedCat1: .productService,
            suggestedCat2: "Business Class",
            suggestedCat3: "Meal Service",
            suggestedCat4: "Service procedures",
            defaultPhase: .service,
            bulletPlaceholders: [
                "Passenger seat number and loyalty tier if known",
                "Nature of the complaint",
                "Service recovery action taken",
                "Passenger response after recovery",
            ],
            suggestedPriority: "Follow up required",
            priorityReasoning: "Service complaint with recovery action needs documentation for quality tracking"
        ),
        IncidentTemplate(
            id: "spillage_cold",
            displayName: "Spillage incident (cold)",
            iconName: "drop.triangle",
            suggestedCat1: .spillageCold,
            suggestedCat2: nil,
            suggestedCat3: nil,
            suggestedCat4: nil,
            defaultPhase: .service,
            bulletPlaceholders: [
                "What was spilled and on whom/where",
                "Passenger seat number if applicable",
                "Cleaning action taken",
                "Dry cleaning offer or compensation provided",
            ],
            suggestedPriority: "Info only",
            priorityReasoning: "Routine spillage handled onboard with immediate service recovery; escalate manually if VVIP, injury, or unresolved"
        ),
        IncidentTemplate(
            id: "crew_performance_feedback",
            displayName: "Crew performance feedback",
            iconName: "star.bubble",
            suggestedCat1: .cabinCrew,
            suggestedCat2: "Performance Feedback",
            suggestedCat3: nil,
            suggestedCat4: nil,
            defaultPhase: .cruise,
            bulletPlaceholders: [
                "Crew member staff number and name",
                "Specific behaviour or action observed",
                "Context and impact on service/team",
            ],
            suggestedPriority: "Info only",
            priorityReasoning: "Performance observation for developmental record"
        ),
        IncidentTemplate(
            id: "water_leak_cabin",
            displayName: "Water leakage (cabin)",
            iconName: "drop.halffull",
            suggestedCat1: .cabinDefect,
            suggestedCat2: "Water leakage (Cabin)",
            suggestedCat3: nil,
            suggestedCat4: nil,
            defaultPhase: .cruise,
            bulletPlaceholders: [
                "Location of leak (overhead bin, window, panel)",
                "Seats or areas affected",
                "Passengers reseated (yes/no)",
                "Containment action taken",
            ],
            suggestedPriority: "Follow up required",
            priorityReasoning: "Water ingress requires tech log entry and engineering inspection"
        ),
    ]
}
