//
//  Categories+Catering.swift
//  KiS Extensions — ReportWriter
//
//  GENERATED FILE. Do not edit by hand.
//  Parent category: "Catering"
//

import Foundation

enum Categories_catering {

    // MARK: - Cat2 options
    static let cat2List: [String] = [
        "Festive offering",
        "Food",
        "JC POML-Preordered Meals",
        "Loading",
        "SPML",
        "Serve Better JCL - Food",
        "Serve Better JCL - Loading",
    ]

    // MARK: - Cat3 lookup
    static func cat3List(cat2: String) -> [String] {
        switch cat2 {
        case "Festive offering":
            return [
                "Business Class",
                "Economy Class",
                "First Class",
                "Premium Economy Class",
            ]
        case "Food":
            return [
                "Business Class",
                "Economy Class",
                "First Class",
                "Premium Economy Class",
            ]
        case "JC POML-Preordered Meals":
            return [
                "Business Class",
            ]
        case "Loading":
            return [
                "Business Class",
                "Economy Class",
                "First Class",
                "Premium Economy Class",
            ]
        case "SPML":
            return [
                "Business Class",
                "Economy Class",
                "First Class",
                "Premium Economy Class",
            ]
        case "Serve Better JCL - Food":
            return [
                "Business Class",
            ]
        case "Serve Better JCL - Loading":
            return [
                "Business Class",
            ]
        default: return []
        }
    }

    // MARK: - Cat4 lookup
    static func cat4List(cat2: String, cat3: String) -> [String] {
        switch (cat2, cat3) {
        case ("Festive offering", "Business Class"):
            return [
                "Food",
                "Loading",
                "Service",
            ]
        case ("Festive offering", "Economy Class"):
            return [
                "Food",
                "Loading",
                "Service",
            ]
        case ("Festive offering", "First Class"):
            return [
                "Food",
                "Loading",
                "Service",
            ]
        case ("Festive offering", "Premium Economy Class"):
            return [
                "Food",
                "Loading",
                "Service",
            ]
        case ("Food", "Business Class"):
            return [
                "Quality Presentation",
                "Foreign Object",
                "Food Poisoning",
                "Positive Feedback",
                "Crew Meals",
                "Incorrect Food",
                "MOD Menu Incorrect",
                "SPML Quality Content",
                "Ramadan Feedback",
                "EU Allergen Info",
                "Choice unavailable - Appetiser 1 - Arabic Mezze",
                "Choice unavailable - Appetiser 2 - Western/Local",
                "Choice unavailable - Main course Chicken",
                "Choice unavailable - Main course Fish/Seafood",
                "Choice unavailable - Main course Beef",
                "Choice unavailable - Main course Lamb/Mutton",
                "Choice unavailable - Main course Vegetarian",
                "Choice unavailable - Main course Local",
                "Choice unavailable - Cheese",
                "Choice unavailable - Dessert",
                "Choice unavailable - Fruits",
                "Choice unavailable - Breads",
                "Choice unavailable -Light bites",
                "Choice unavailable - Fresh Juices",
                "Digital Menu feedback",
                "Menucards and Folder",
                "Quality-Mould/Fungus",
            ]
        case ("Food", "Economy Class"):
            return [
                "Quality Presentation",
                "Foreign Object",
                "Food Poisoning",
                "Crew Meals",
                "Positive Feedback",
                "SPML Quality Content",
                "Ramadan Feedback",
                "EU Allergen Info",
                "Incorrect Food",
                "Choice unavailable - Main course Chicken",
                "Choice unavailable - Main course Fish/Seafood",
                "Choice unavailable - Main course Beef",
                "Choice unavailable - Main course Lamb/Mutton",
                "Choice unavailable - Main course Vegetarian",
                "Choice unavailable - Main course Local",
                "Digital Menu feedback",
                "Menucards and Folder",
                "Quality-Mould/Fungus",
            ]
        case ("Food", "First Class"):
            return [
                "Quality Presentation",
                "Foreign Object",
                "Food Poisoning",
                "Crew Meals",
                "Positive Feedback",
                "Incorrect Food",
                "SPML Quality Content",
                "Ramadan Feedback",
                "EU Allergen Info",
                "Choice unavailable - Caviar",
                "Choice unavailable - Appetiser 1 - Arabic Mezze",
                "Choice unavailable - Appetiser 2 - Western/Local",
                "Choice unavailable - Main course Chicken",
                "Choice unavailable - Main course Fish/Seafood",
                "Choice unavailable - Main course Beef",
                "Choice unavailable - Main course Lamb/Mutton",
                "Choice unavailable - Main course Vegetarian",
                "Choice unavailable - Main course Local",
                "Choice unavailable - Fruits",
                "Choice unavailable - Breads",
                "Choice unavailable - Salad",
                "Choice unavailable - Dressing",
                "Choice unavailable - Soup",
                "Choice unavailable - Cheese",
                "Choice unavailable - Dessert 1",
                "Choice unavailable - Dessert 2",
                "Choice unavailable - Light bites",
                "Choice unavailable - Fresh Juices",
                "Plating Guides",
                "MOD Menu Incorrect",
                "Digital Menu feedback",
                "Chocolates and sweets",
                "Movie snack",
                "Amuse Bouche",
                "Menucards and Folder",
                "Quality-Mould/Fungus",
            ]
        case ("Food", "Premium Economy Class"):
            return [
                "Food Poisoning",
                "Foreign Object",
                "EU Allergen Info",
                "Choice unavailable - Main course Chicken",
                "Choice unavailable - Main course Fish/Seafood",
                "Choice unavailable - Main course Beef",
                "Choice unavailable - Main course Lamb/Mutton",
                "Choice unavailable - Main course Vegetarian",
                "Choice unavailable - Main course Local",
                "Digital Menu feedback",
                "Incorrect Food",
                "Ramadan Feedback",
                "SPML Quality Content",
                "Positive Feedback",
                "Crew Meals",
                "Quality Presentation",
                "Menucards and Folder",
                "Quality-Mould/Fungus",
            ]
        case ("JC POML-Preordered Meals", "Business Class"):
            return [
                "Customer feedback",
                "Meal not available",
                "Crew feedback/suggestion",
                "Meal not delivered",
                "Preorder info not available",
                "Preorder info not clear",
            ]
        case ("Loading", "Business Class"):
            return [
                "Dry Stores/ Shortage",
                "Drystores/Not Loaded",
                "Trashcompactor/Boxes",
                "Headsets",
                "Giveaways (Toys)",
                "Kitbags",
                "Equipment - Dirty",
                "Newspapers",
                "Positive Feedback",
                "Chillers or Ovens",
                "A/C ROB equip defect",
                "A/C ROB equip short",
                "Equipment Shortage -Chinaware",
                "Equipment Shortage -Glassware",
                "Equipment Shortage - Cutlery",
                "Equipment Shortage - Racks",
                "Equipment Shortage - Trays",
                "Equipment Shortage - Drawers",
                "Equipment Shortage- Standard Unit",
                "Equipment Shortage- Half Cart",
                "Equipment Shortage - Full cart",
                "Shortage Drinks - Aperitif",
                "Shortage Drinks - Beer",
                "Shortage Drinks - Liqueur",
                "Shortage Drinks - Champagne",
                "Shortage Drinks - Wine (White)",
                "Shortage Drinks - Wine (Red)",
                "Shortage Drinks - Wine (Port)",
                "Shortage Drinks -Juice (Tetrapak)",
                "Shortage Drinks - Minerals(Can)",
                "Shortage Drinks - Milk(Fresh)",
                "Shortage Drinks - Milk(Tetrapak)",
                "Shortage Drinks - Water(Small)",
                "Shortage Drinks - Water(Large)",
                "Shortage Drinks -Tea",
                "Shortage Drinks -Coffee",
                "Equipment not loaded -Chinaware",
                "Equipment not loaded -Glassware",
                "Equipment not loaded - Cutlery",
                "Equipment not loaded - Racks",
                "Equipment not loaded - Trays",
                "Equipment not loaded - Drawers",
                "Equipment not loaded- Standard Unit",
                "Equipment not loaded- Half Cart",
                "Equipment not loaded - Full cart",
                "Bed Linen-Dirty",
                "Bed Linen-Not Loaded",
                "Tableware Linen-Dirty/Creased",
                "Tableware Linen-Not Loaded",
                "Shortage Drinks - Spirit",
                "Wine List Mismatch",
            ]
        case ("Loading", "Economy Class"):
            return [
                "Drinks - Not Loaded",
                "Dry Stores/ Shortage",
                "Drystores/Not Loaded",
                "Trashcompactor/Boxes",
                "Headsets",
                "Giveaways (Toys)",
                "Kitbags",
                "Equipment - Dirty",
                "Newspapers",
                "Positive Feedback",
                "Chillers or Ovens",
                "A/C ROB equip defect",
                "A/C ROB equip short",
                "Equipment Shortage -Chinaware",
                "Equipment Shortage -Glassware",
                "Equipment Shortage - Cutlery",
                "Equipment Shortage - Racks",
                "Equipment Shortage - Trays",
                "Equipment Shortage - Drawers",
                "Equipment Shortage- Standard Unit",
                "Equipment Shortage- Half Cart",
                "Equipment Shortage - Full cart",
                "Shortage Drinks - Aperitif",
                "Shortage Drinks - Beer",
                "Shortage Drinks - Liqueur",
                "Shortage Drinks - Spirit",
                "Shortage Drinks - Champagne",
                "Shortage Drinks - Wine (White)",
                "Shortage Drinks - Wine (Red)",
                "Shortage Drinks - Wine (Port)",
                "Shortage Drinks -Juice (Tetrapak)",
                "Shortage Drinks - Minerals(Can)",
                "Shortage Drinks - Minerals(Bottle)",
                "Shortage Drinks - Milk(Fresh)",
                "Shortage Drinks - Milk(Tetrapak)",
                "Shortage Drinks - Water(Small)",
                "Shortage Drinks - Water(Large)",
                "Shortage Drinks -Tea",
                "Shortage Drinks -Coffee",
                "Equipment not loaded -Chinaware",
                "Equipment not loaded -Glassware",
                "Equipment not loaded - Cutlery",
                "Equipment not loaded - Racks",
                "Equipment not loaded - Trays",
                "Equipment not loaded - Drawers",
                "Equipment not loaded- Standard Unit",
                "Equipment not loaded- Half Cart",
                "Equipment not loaded - Full cart",
                "Bed Linen-Dirty",
                "Bed Linen-Not Loaded",
                "Service Linen-Dirty/Creased",
                "Service Linen-Not Loaded",
            ]
        case ("Loading", "First Class"):
            return [
                "Drinks - Not Loaded",
                "Dry Stores/ Shortage",
                "Drystores/Not Loaded",
                "Trashcompactor/Boxes",
                "Headsets",
                "Giveaways (Toys)",
                "Kitbags",
                "Equipment - Dirty",
                "Newspapers",
                "Positive Feedback",
                "Chillers or Ovens",
                "A/C ROB equip defect",
                "A/C ROB equip short",
                "Equipment Shortage -Chinaware",
                "Equipment Shortage -Glassware",
                "Equipment Shortage - Cutlery",
                "Equipment Shortage - Racks",
                "Equipment Shortage - Trays",
                "Equipment Shortage - Drawers",
                "Equipment Shortage- Standard Unit",
                "Equipment Shortage- Half Cart",
                "Equipment Shortage - Full cart",
                "Shortage Drinks - Aperitif",
                "Shortage Drinks - Beer",
                "Shortage Drinks - Liqueur",
                "Shortage Drinks - Spirit",
                "Shortage Drinks - Champagne",
                "Shortage Drinks - Wine (White)",
                "Shortage Drinks - Wine (Red)",
                "Shortage Drinks - Wine (Port)",
                "Shortage Drinks -Juice (Tetrapak)",
                "Shortage Drinks - Minerals(Can)",
                "Shortage Drinks - Minerals(Bottle)",
                "Shortage Drinks - Milk(Fresh)",
                "Shortage Drinks - Milk(Tetrapak)",
                "Shortage Drinks - Water(Small)",
                "Shortage Drinks - Water(Large)",
                "Shortage Drinks -Tea",
                "Shortage Drinks -Coffee",
                "Equipment not loaded -Chinaware",
                "Equipment not loaded -Glassware",
                "Equipment not loaded - Cutlery",
                "Equipment not loaded - Racks",
                "Equipment not loaded - Trays",
                "Equipment not loaded - Drawers",
                "Equipment not loaded- Standard Unit",
                "Equipment not loaded- Half Cart",
                "Equipment not loaded - Full cart",
                "Bed Linen-Dirty",
                "Bed Linen-Not Loaded",
                "Tableware Linen-Dirty/Creased",
                "Tableware Linen-Not Loaded",
                "Wine List Mismatch",
            ]
        case ("Loading", "Premium Economy Class"):
            return [
                "A/C ROB equip defect",
                "A/C ROB equip short",
                "Bed Linen-Dirty",
                "Bed Linen-Not Loaded",
                "Chillers or Ovens",
                "Drinks - Not Loaded",
                "Dry Stores/ Shortage",
                "Drystores/Not Loaded",
                "Equipment - Dirty",
                "Equipment not loaded - Cutlery",
                "Equipment not loaded - Drawers",
                "Equipment not loaded - Full cart",
                "Equipment not loaded - Racks",
                "Equipment not loaded - Trays",
                "Equipment not loaded -Chinaware",
                "Equipment not loaded -Glassware",
                "Equipment not loaded- Half Cart",
                "Equipment not loaded- Standard Unit",
                "Equipment Shortage - Cutlery",
                "Equipment Shortage - Drawers",
                "Equipment Shortage - Full cart",
                "Giveaways (Toys)",
                "Headsets",
                "Kitbags",
                "Positive Feedback",
                "Service Linen-Dirty/Creased",
                "Service Linen-Not Loaded",
                "Shortage Drinks - Aperitif",
                "Shortage Drinks - Beer",
                "Shortage Drinks - Champagne",
                "Shortage Drinks - Liqueur",
                "Shortage Drinks - Milk(Fresh)",
                "Shortage Drinks - Milk(Tetrapak)",
                "Shortage Drinks - Minerals(Bottle)",
                "Shortage Drinks - Minerals(Can)",
                "Shortage Drinks - Spirit",
                "Shortage Drinks - Water(Large)",
                "Shortage Drinks - Water(Small)",
                "Shortage Drinks - Wine (Port)",
                "Shortage Drinks - Wine (Red)",
                "Shortage Drinks - Wine (White)",
                "Shortage Drinks -Coffee",
                "Shortage Drinks -Juice (Tetrapak)",
                "Shortage Drinks -Tea",
                "Trashcompactor/Boxes",
            ]
        case ("SPML", "Business Class"):
            return [
                "On PIL not loaded",
            ]
        case ("SPML", "Economy Class"):
            return [
                "On PIL not loaded",
            ]
        case ("SPML", "First Class"):
            return [
                "On PIL not loaded",
            ]
        case ("SPML", "Premium Economy Class"):
            return [
                "On PIL not loaded",
            ]
        case ("Serve Better JCL - Food", "Business Class"):
            return [
                "Quality/Presentation",
                "Choice Not Available",
                "Dressing/Garnish Feedback",
                "Plating Image Quality (accurate/clear)",
                "SPML Loading (in the new foils)",
            ]
        case ("Serve Better JCL - Loading", "Business Class"):
            return [
                "Excess Equipment",
                "Shortage of Equipment",
                "Incorrect Equipment",
                "Packing Improvement Request",
                "New Equipment Request",
                "One Device Holders - Missing/Broken",
            ]
        default: return []
        }
    }
}
