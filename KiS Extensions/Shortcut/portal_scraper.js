// KiS Extensions - Safari Shortcut Script
// This script runs on the crew portal page via Apple Shortcuts.
// It extracts trip, crew, and flight data from the portal's localStorage
// and returns it as JSON for the KiS Extensions app.
//
// HOW TO SET UP THE SHORTCUT:
// 1. Open the Shortcuts app on your iPad
// 2. Create a new shortcut named "KiS Extensions"
// 3. Add action: "Run JavaScript on Web Page" and paste this entire script
// 4. Add action: "Copy to Clipboard" (input: Shortcut Result)
// 5. Add action: "Open URLs" with URL: kisextensions://import
// 6. In Safari on the portal, tap Share → "KiS Extensions"

function safeParse(str) {
    try { return JSON.parse(str); }
    catch (e) { console.warn('Skipping invalid JSON:', str); return null; }
}

function transformFormat(str) {
    let fltNumber = str.split("_")[1];
    let temp = str.split("_")[2].split("-", 3);
    temp[1] = (parseInt(temp[1]) + 1).toString();
    temp[2] = (parseInt(temp[2]) + 2000).toString();
    temp.forEach((n, i) => temp[i] = n.padStart(2, "0"));
    return fltNumber + "_" + temp.join("/");
}

function convertDate(stringDate) {
    let [day, month, year] = stringDate.split(" ", 1)[0].split("/");
    let rest = stringDate.split(" ")[1];
    return [parseInt(month), day, year].join("/") + " " + rest;
}

// Extract data from portal localStorage
let userStaffNumber = localStorage.getItem("CurrentStaffNo");
let crewDataKey = Object.keys(localStorage).filter(k => k.startsWith("Crew_") && !k.endsWith("TimeOut"));
let rosterKey = Object.keys(localStorage).filter(k => k.startsWith("Roster_" + userStaffNumber) && !k.endsWith("TimeOut") && !k.endsWith("Destination"));
let flightDataKey = Object.keys(localStorage).filter(m => m.startsWith("Position_") && !m.endsWith("TimeOut"));

let dataToGo = {}, roster = [];

// Parse roster data
rosterKey.forEach(item => {
    let value = safeParse(localStorage.getItem(item));
    if (value) roster.push(value);
});

// Create trip entries
roster.forEach(item => {
    item.StaffRosters[0].RosterData.CrewRosterResonse.Trips.Trp.forEach(subitem => {
        dataToGo[subitem.TripNo + "_" + subitem.StartDate.split(" ", 1)] = {};
    });
});

// Attach crew data
crewDataKey.forEach(item => {
    let value = safeParse(localStorage.getItem(item));
    if (value) {
        let key = transformFormat(item);
        if (dataToGo[key]) dataToGo[key].crewData = value;
    }
});

// Attach flight data
flightDataKey.forEach(item => {
    let value = safeParse(localStorage.getItem(item));
    if (value) {
        let key = item.split(" ", 1)[0].split("_").slice(-2).join("_");
        if (dataToGo[key]) {
            if (!dataToGo[key].flightData) {
                dataToGo[key].flightData = value;
            } else if (value.FlightData) {
                dataToGo[key].flightData.FlightData =
                    (dataToGo[key].flightData.FlightData || []).concat(value.FlightData);
            }
        }
    }
});

// Build shortInfo for each trip
roster.forEach(item => {
    item.StaffRosters[0].RosterData.CrewRosterResonse.Trips.Trp.forEach(subitem => {
        let key = subitem.TripNo + "_" + subitem.StartDate.split(" ", 1)[0];
        if (!dataToGo[key]) dataToGo[key] = {};

        dataToGo[key].shortInfo = {};
        dataToGo[key].shortInfo.sectors = subitem.Dty.length;
        dataToGo[key].shortInfo.flightNumber = subitem.Dty[0].Flt[0].FltNo;
        // Convert Date to ISO string for JSON serialization (avoids iOS Date parsing issues)
        dataToGo[key].shortInfo.flightDate = new Date(convertDate(subitem.Dty[0].Flt[0].DepDate)).toISOString();

        let flightLegs = ["DXB"], layovers = [], durations = [], sectorsPerDuty = [];
        subitem.Dty.forEach(duty => {
            sectorsPerDuty.push(duty.Flt.length);
            duty.Flt.forEach(flightLeg => {
                if (flightLeg.ArrStn !== "DXB") {
                    flightLegs.push(flightLeg.ArrStn);
                    layovers.push(flightLeg.LayOverTime);
                }
                durations.push(flightLeg.Duration);
            });
        });

        dataToGo[key].shortInfo.flightLegs = flightLegs;
        dataToGo[key].shortInfo.layovers = layovers;
        dataToGo[key].shortInfo.durations = durations;
        dataToGo[key].shortInfo.sectorsPerDuty = sectorsPerDuty;
        dataToGo[key].shortInfo.staff = userStaffNumber;
    });
});

// Sort by flight date
dataToGo = Object.entries(dataToGo)
    .sort(([, a], [, b]) => new Date(a.shortInfo.flightDate) - new Date(b.shortInfo.flightDate))
    .reduce((r, [k, v]) => ({ ...r, [k]: v }), {});

// Return JSON to Shortcuts app
// The "completion()" call is required by Apple Shortcuts "Run JavaScript on Web Page"
completion(JSON.stringify(dataToGo));
