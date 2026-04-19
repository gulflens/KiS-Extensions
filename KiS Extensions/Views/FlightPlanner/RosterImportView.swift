import SwiftUI
import SwiftData
import WebKit

// MARK: - Roster Import View

struct RosterImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var webView = WKWebView()
    @State private var isLoading = true
    @State private var isImporting = false
    @State private var canGoBack = false
    @State private var canGoForward = false
    @State private var currentURL = ""
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var importSummary: String?
    @State private var showSummary = false
    @State private var rawJSON: String?

    private let portalURL = "https://emiratesgroup.sharepoint.com/sites/ccp/roster/Pages/Roster.aspx#"

    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                ProgressView()
                    .frame(height: 2)
            }

            WebViewRepresentable(
                webView: webView,
                isLoading: $isLoading,
                canGoBack: $canGoBack,
                canGoForward: $canGoForward,
                currentURL: $currentURL
            )
        }
        .navigationTitle("Import Roster")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                HStack(spacing: 12) {
                    Button("Close") { dismiss() }

                    Button {
                        webView.goBack()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(!canGoBack)

                    Button {
                        flushTemporaryData {
                            webView.reload()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 8) {
                    Button {
                        importRoster()
                    } label: {
                        if isImporting {
                            ProgressView()
                                .controlSize(.small)
                                .padding(.horizontal, 8)
                        } else {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.down.doc")
                                Text("Import Roster")
                            }
                            .padding(.horizontal, 8)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.roundedRectangle)
                    .disabled(isImporting)
                }
            }
        }
        .alert("Import Error", isPresented: $showError) {
            Button("OK") {}
            Button("Diagnose") {
                diagnosePage()
            }
            if rawJSON != nil {
                Button("Copy Raw Data") {
                    if let json = rawJSON {
                        UIPasteboard.general.string = json
                    }
                }
            }
        } message: {
            Text(errorMessage ?? "Could not extract roster data.")
        }
        .alert("Roster Imported", isPresented: $showSummary) {
            Button("Done") { dismiss() }
        } message: {
            Text(importSummary ?? "")
        }
        .onAppear {
            flushTemporaryData {
                if let url = URL(string: portalURL) {
                    webView.load(URLRequest(url: url))
                }
            }
        }
    }

    // MARK: - Diagnose

    private func diagnosePage() {
        let script = """
        (function() {
            var out = {};

            // Month extraction (same logic as scraper)
            var monthMap = {
                JAN:"01",FEB:"02",MAR:"03",APR:"04",MAY:"05",JUN:"06",
                JUL:"07",AUG:"08",SEP:"09",OCT:"10",NOV:"11",DEC:"12",
                JANUARY:"01",FEBRUARY:"02",MARCH:"03",APRIL:"04",
                JUNE:"06",JULY:"07",AUGUST:"08",SEPTEMBER:"09",
                OCTOBER:"10",NOVEMBER:"11",DECEMBER:"12"
            };
            var monthNum = "";
            var yearFull = "";
            var monthSource = "none";

            var selects = document.querySelectorAll("select");
            out.selects = [];
            for (var s = 0; s < selects.length; s++) {
                var opt = selects[s].options[selects[s].selectedIndex];
                var txt = opt ? opt.text : "(none)";
                out.selects.push(txt);
                if (!monthNum) {
                    var sm = txt.match(/(\\w+)\\s+(\\d{4})/);
                    if (sm && monthMap[sm[1].toUpperCase()]) {
                        monthNum = monthMap[sm[1].toUpperCase()];
                        yearFull = sm[2];
                        monthSource = "select[" + s + "]: " + txt;
                    }
                }
            }
            out.extractedMonth = monthNum;
            out.extractedYear = yearFull;
            out.monthSource = monthSource;

            // Find roster table (same logic as scraper — reverse order, check header cells)
            var tables = document.querySelectorAll("table");
            out.tableCount = tables.length;
            var rosterTable = null;
            var rosterIdx = -1;
            var headerRowIdx = -1;

            for (var t = tables.length - 1; t >= 0; t--) {
                var tbl = tables[t];
                if (tbl.rows.length < 5) continue;
                for (var r = 0; r < Math.min(3, tbl.rows.length); r++) {
                    var cells = tbl.rows[r].cells;
                    if (cells.length < 8) continue;
                    var hasFlightNo = false;
                    var stationCount = 0;
                    var timeCount = 0;
                    for (var c = 0; c < cells.length; c++) {
                        var h = cells[c].textContent.trim();
                        if (h.indexOf("Flight") >= 0) hasFlightNo = true;
                        if (h === "Station") stationCount++;
                        if (h === "Time") timeCount++;
                    }
                    if (hasFlightNo && stationCount >= 2 && timeCount >= 2) {
                        rosterTable = tbl;
                        rosterIdx = t;
                        headerRowIdx = r;
                        break;
                    }
                }
                if (rosterTable) break;
            }

            out.rosterTableIndex = rosterIdx;
            out.headerRowIndex = headerRowIdx;

            if (!rosterTable) {
                out.error = "No roster table found";
                return JSON.stringify(out, null, 2);
            }

            out.totalRows = rosterTable.rows.length;

            // Dump every row of the roster table
            out.rows = [];
            for (var r = 0; r < rosterTable.rows.length; r++) {
                var cells = rosterTable.rows[r].cells;
                var row = { cellCount: cells.length, cells: [] };
                for (var c = 0; c < cells.length; c++) {
                    var cell = cells[c];
                    var entry = { text: cell.textContent.trim().substring(0, 50) };
                    if (cell.colSpan > 1) entry.colspan = cell.colSpan;
                    row.cells.push(entry);
                }
                out.rows.push(row);
            }

            return JSON.stringify(out, null, 2);
        })();
        """

        webView.evaluateJavaScript(script) { result, error in
            if let error = error {
                rawJSON = "JS Error: \(error.localizedDescription)"
            } else if let json = result as? String {
                rawJSON = json
            } else {
                rawJSON = "No result returned"
            }
            UIPasteboard.general.string = rawJSON
            errorMessage = "Roster table data copied to clipboard (\(rawJSON?.count ?? 0) chars). Paste it to Claude."
            showError = true
        }
    }

    // MARK: - Import Logic

    private func importRoster() {
        isImporting = true
        rawJSON = nil

        webView.evaluateJavaScript(Self.rosterScraperScript) { result, error in
            isImporting = false

            if let error = error {
                errorMessage = "JavaScript error: \(error.localizedDescription)"
                showError = true
                return
            }

            guard let jsonString = result as? String, !jsonString.isEmpty else {
                errorMessage = "No data returned. Make sure you are on the crew portal and your roster is loaded."
                showError = true
                return
            }

            rawJSON = jsonString
            processRosterJSON(jsonString)
        }
    }

    private func processRosterJSON(_ jsonString: String) {
        guard let data = jsonString.data(using: .utf8) else {
            errorMessage = "Failed to read extracted data."
            showError = true
            return
        }

        let decoded: RosterResponse
        do {
            decoded = try JSONDecoder().decode(RosterResponse.self, from: data)
        } catch {
            errorMessage = "Failed to parse roster data: \(error.localizedDescription)\n\nTap 'Copy Raw Data' to inspect."
            showError = true
            return
        }

        if let err = decoded.error {
            let debugInfo = decoded.sampleKeys?.joined(separator: ", ") ?? ""
            switch err {
            case "notLoggedIn":
                errorMessage = "Not logged in. Please sign in to the crew portal first."
            case "noRoster":
                errorMessage = "No roster table found. Make sure your roster is loaded and visible on the page.\n\n\(debugInfo)"
                rawJSON = debugInfo
            default:
                errorMessage = "Extraction error: \(err)\n\n\(debugInfo)"
                rawJSON = debugInfo
            }
            showError = true
            return
        }

        guard let trips = decoded.trips, !trips.isEmpty else {
            errorMessage = "No trips found in the roster data."
            showError = true
            return
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yy"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")

        // Diagnostic: check if times were extracted before doing anything
        let firstSectorHasNoTime = trips.first?.sectors.first.map { $0.depTime.isEmpty } ?? false

        if firstSectorHasNoTime, let keys = decoded.sampleKeys {
            let sampleData = keys.joined(separator: ", ")
            rawJSON = sampleData
            errorMessage = "Times could not be extracted. Flight object fields:\n\n\(sampleData)\n\nTap 'Copy Raw Data' to copy all field names and values."
            showError = true
            return
        }

        let existingTrips: [PlannedFlight]
        do {
            existingTrips = try modelContext.fetch(FetchDescriptor<PlannedFlight>())
        } catch {
            existingTrips = []
        }

        let now = Calendar.current.startOfDay(for: Date())

        let existingFuture = existingTrips.filter { $0.flightDate >= now }
        let pastCount = existingTrips.count - existingFuture.count
        let replacedCount = existingFuture.count

        for flight in existingFuture {
            for sector in flight.sectors {
                modelContext.delete(sector)
            }
            modelContext.delete(flight)
        }

        var imported = 0
        var skippedPast = 0

        for rosterTrip in trips {
            guard let firstSector = rosterTrip.sectors.first,
                  let tripDate = dateFormatter.date(from: firstSector.date) else {
                continue
            }

            if tripDate < now {
                skippedPast += 1
                continue
            }

            let lastSector = rosterTrip.sectors.last ?? firstSector
            let tripType = determineTripType(tripNo: rosterTrip.tripNo, sectors: rosterTrip.sectors, dateFormatter: dateFormatter)

            let flight = PlannedFlight(
                tripNumber: rosterTrip.tripNo,
                tripType: tripType,
                flightNumber: firstSector.flightNumber,
                flightDate: tripDate,
                departure: firstSector.depStation,
                arrival: lastSector.arrStation
            )

            var prevSectorJSON: RosterSectorJSON?
            for sectorJSON in rosterTrip.sectors {
                let sectorDate = dateFormatter.date(from: sectorJSON.date) ?? tripDate
                let sector = PlannedSector(
                    sectorIndex: sectorJSON.index,
                    flightNumber: sectorJSON.flightNumber,
                    date: sectorDate,
                    departureStation: sectorJSON.depStation,
                    arrivalStation: sectorJSON.arrStation,
                    departureTime: sectorJSON.depTime,
                    arrivalTime: sectorJSON.arrTime
                )
                if let dur = sectorJSON.durationStr, !dur.isEmpty {
                    sector.savedFlightTime = dur
                }
                if let prev = prevSectorJSON {
                    let gap = Self.gapMinutes(
                        arrTime: prev.arrTime, arrDate: prev.date,
                        depTime: sectorJSON.depTime, depDate: sectorJSON.date,
                        formatter: dateFormatter
                    )
                    sector.savedIsLayover = gap > 360
                }
                sector.parentTrip = flight
                flight.sectors.append(sector)
                prevSectorJSON = sectorJSON
            }

            modelContext.insert(flight)
            imported += 1
        }

        try? modelContext.save()

        var parts: [String] = []
        if imported > 0 { parts.append("\(imported) upcoming trip\(imported == 1 ? "" : "s") imported") }
        if replacedCount > 0 { parts.append("\(replacedCount) previous future trip\(replacedCount == 1 ? "" : "s") replaced") }
        if pastCount > 0 { parts.append("\(pastCount) past trip\(pastCount == 1 ? "" : "s") kept") }
        importSummary = parts.isEmpty ? "No changes made." : parts.joined(separator: ", ") + "."
        showSummary = true
    }

    private func tripKey(_ tripNumber: String, _ date: Date) -> String {
        let cal = Calendar.current
        let components = cal.dateComponents([.year, .month, .day], from: date)
        return "\(tripNumber)_\(components.year ?? 0)_\(components.month ?? 0)_\(components.day ?? 0)"
    }

    private func determineTripType(tripNo: String, sectors: [RosterSectorJSON], dateFormatter: DateFormatter) -> TripType {
        let trimmed = tripNo.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("2") || trimmed.last?.isLetter == true {
            return .special
        }

        if sectors.count > 2 {
            return .transit
        }

        if sectors.count == 2,
           let firstDate = dateFormatter.date(from: sectors[0].date),
           let lastDate = dateFormatter.date(from: sectors[1].date) {
            let cal = Calendar.current
            if cal.isDate(firstDate, inSameDayAs: lastDate) {
                return .turnaround
            }
            return .layover
        }

        return .layover
    }

    // MARK: - Gap Calculation

    private static func gapMinutes(arrTime: String, arrDate: String, depTime: String, depDate: String, formatter: DateFormatter) -> Int {
        guard let aDate = formatter.date(from: arrDate),
              let dDate = formatter.date(from: depDate) else { return 0 }
        let aParts = arrTime.split(separator: ":").compactMap { Int($0) }
        let dParts = depTime.split(separator: ":").compactMap { Int($0) }
        guard aParts.count == 2, dParts.count == 2 else { return 0 }
        let cal = Calendar.current
        guard let arrival = cal.date(bySettingHour: aParts[0], minute: aParts[1], second: 0, of: aDate),
              let departure = cal.date(bySettingHour: dParts[0], minute: dParts[1], second: 0, of: dDate)
        else { return 0 }
        return Int(departure.timeIntervalSince(arrival) / 60)
    }

    // MARK: - Flush Temporary Data

    private func flushTemporaryData(completion: @escaping () -> Void) {
        let dataStore = WKWebsiteDataStore.default()
        let loginDomains = ["login.microsoftonline.com", "microsoft.com",
                            "sharepoint.com", "emiratesgroup.sharepoint.com",
                            "login.live.com", "microsoftonline.com"]
        let typesToRemove: Set<String> = [
            WKWebsiteDataTypeDiskCache,
            WKWebsiteDataTypeMemoryCache,
            WKWebsiteDataTypeLocalStorage,
            WKWebsiteDataTypeSessionStorage,
            WKWebsiteDataTypeIndexedDBDatabases,
            WKWebsiteDataTypeServiceWorkerRegistrations
        ]
        dataStore.removeData(ofTypes: typesToRemove, modifiedSince: .distantPast) {
            let cookieStore = dataStore.httpCookieStore
            cookieStore.getAllCookies { cookies in
                let group = DispatchGroup()
                for cookie in cookies {
                    let domain = cookie.domain.lowercased()
                    let isLogin = loginDomains.contains { domain.hasSuffix($0) }
                    if !isLogin {
                        group.enter()
                        cookieStore.delete(cookie) { group.leave() }
                    }
                }
                group.notify(queue: .main) {
                    completion()
                }
            }
        }
    }

    // MARK: - Scraper JavaScript

    static let rosterScraperScript: String = """
    (function() {
        // Find the roster table by checking header CELLS directly.
        // Search in reverse so innermost tables are checked first.
        var tables = document.querySelectorAll("table");
        var rosterTable = null;
        var headerRowIdx = -1;
        var debugInfo = "tables:" + tables.length;

        for (var t = tables.length - 1; t >= 0; t--) {
            var tbl = tables[t];
            if (tbl.rows.length < 5) continue;
            for (var r = 0; r < Math.min(3, tbl.rows.length); r++) {
                var cells = tbl.rows[r].cells;
                if (cells.length < 8) continue;
                var hasFlightNo = false, stationCount = 0, timeCount = 0;
                for (var c = 0; c < cells.length; c++) {
                    var h = cells[c].textContent.trim();
                    if (h.indexOf("Flight") >= 0) hasFlightNo = true;
                    if (h === "Station") stationCount++;
                    if (h === "Time") timeCount++;
                }
                if (hasFlightNo && stationCount >= 2 && timeCount >= 2) {
                    rosterTable = tbl;
                    headerRowIdx = r;
                    debugInfo += ",tblIdx:" + t + ",hdrRow:" + r;
                    break;
                }
            }
            if (rosterTable) break;
        }

        if (!rosterTable) {
            return JSON.stringify({ error: "noRoster", sampleKeys: [debugInfo] });
        }

        // Determine month/year from the day-of-week in the table data.
        // The select elements on the page are unreliable (they show the
        // previously-viewed month, not the currently-displayed one).
        // Instead, find the row for day "01" and use its day-of-week
        // to identify the correct month via the calendar.
        var dayNames = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"];
        var firstDayOfWeek = -1;
        var rows = rosterTable.rows;

        for (var r = headerRowIdx + 1; r < rows.length; r++) {
            var c0 = rows[r].cells[0];
            if (!c0) continue;
            var m01 = c0.textContent.trim().match(/^01\\s+(Mon|Tue|Wed|Thu|Fri|Sat|Sun)/i);
            if (m01) {
                var dn = m01[1].charAt(0).toUpperCase() + m01[1].substring(1,3).toLowerCase();
                firstDayOfWeek = dayNames.indexOf(dn);
                break;
            }
        }

        var monthNum = "";
        var yearFull = "";

        if (firstDayOfWeek >= 0) {
            // Search months near the current date for one whose 1st matches
            var now = new Date();
            for (var offset = -3; offset <= 3; offset++) {
                var testDate = new Date(now.getFullYear(), now.getMonth() + offset, 1);
                if (testDate.getDay() === firstDayOfWeek) {
                    monthNum = (testDate.getMonth() + 1 < 10 ? "0" : "") + (testDate.getMonth() + 1);
                    yearFull = "" + testDate.getFullYear();
                    break;
                }
            }
        }

        if (!monthNum) {
            // Fallback: try select elements
            var monthMap = {
                JAN:"01",FEB:"02",MAR:"03",APR:"04",MAY:"05",JUN:"06",
                JUL:"07",AUG:"08",SEP:"09",OCT:"10",NOV:"11",DEC:"12",
                JANUARY:"01",FEBRUARY:"02",MARCH:"03",APRIL:"04",
                JUNE:"06",JULY:"07",AUGUST:"08",SEPTEMBER:"09",
                OCTOBER:"10",NOVEMBER:"11",DECEMBER:"12"
            };
            var selects = document.querySelectorAll("select");
            for (var s = 0; s < selects.length; s++) {
                var opt = selects[s].options[selects[s].selectedIndex];
                if (!opt) continue;
                var sm = opt.text.match(/(\\w+)\\s+(\\d{4})/);
                if (sm && monthMap[sm[1].toUpperCase()]) {
                    monthNum = monthMap[sm[1].toUpperCase()];
                    yearFull = sm[2];
                    break;
                }
            }
        }

        if (!monthNum || !yearFull) {
            var now2 = new Date();
            monthNum = (now2.getMonth() + 1 < 10 ? "0" : "") + (now2.getMonth() + 1);
            yearFull = "" + now2.getFullYear();
        }

        var yearShort = yearFull.substring(2);
        debugInfo += ",month:" + monthNum + "/" + yearFull;

        // Parse flight rows
        var trips = [];
        var currentTrip = null;
        var sectorIdx = 0;
        var sampleRow = null;

        for (var r = headerRowIdx + 1; r < rows.length; r++) {
            var cells = rows[r].cells;
            if (!cells || cells.length < 6) continue;

            var vals = [];
            for (var c = 0; c < cells.length; c++) {
                vals.push(cells[c].textContent.trim());
            }

            var fltIdx = -1;
            for (var c = 0; c < vals.length; c++) {
                if (/^\\d{3}$/.test(vals[c])) {
                    fltIdx = c;
                    break;
                }
            }

            if (fltIdx < 0) continue;
            if (!sampleRow) sampleRow = vals;

            var tripNo = "";
            for (var c = 0; c < fltIdx; c++) {
                if (/^\\d{4,}$/.test(vals[c])) {
                    tripNo = vals[c];
                }
            }

            var dayNum = "";
            for (var c = 0; c < Math.min(3, fltIdx); c++) {
                var dm = vals[c].match(/^(\\d{1,2})/);
                if (dm) {
                    dayNum = dm[1];
                    if (dayNum.length === 1) dayNum = "0" + dayNum;
                    break;
                }
            }
            var dateStr = dayNum + "/" + monthNum + "/" + yearShort;

            var depStation = "";
            var arrStation = "";
            var stnCount = 0;
            for (var c = fltIdx + 1; c < vals.length; c++) {
                if (/^[A-Z]{3}$/.test(vals[c])) {
                    if (stnCount === 0) depStation = vals[c];
                    else if (stnCount === 1) arrStation = vals[c];
                    stnCount++;
                    if (stnCount >= 2) break;
                }
            }

            var depTime = "";
            var arrTime = "";
            var durationStr = "";
            var timeCount = 0;
            for (var c = fltIdx + 1; c < vals.length; c++) {
                if (/^\\d{1,2}:\\d{2}$/.test(vals[c])) {
                    if (timeCount === 0) depTime = vals[c];
                    else if (timeCount === 1) arrTime = vals[c];
                    else if (timeCount === 2) durationStr = vals[c];
                    timeCount++;
                    if (timeCount >= 3) break;
                }
            }

            // Only start a new trip when the trip number CHANGES.
            // The portal repeats the trip number on every row of the same trip.
            if (tripNo && (!currentTrip || tripNo !== currentTrip.tripNo)) {
                if (currentTrip && currentTrip.sectors.length > 0) {
                    trips.push(currentTrip);
                }
                currentTrip = { tripNo: tripNo, sectors: [] };
                sectorIdx = 0;
            }

            if (!currentTrip) {
                currentTrip = { tripNo: tripNo || "", sectors: [] };
                sectorIdx = 0;
            }

            currentTrip.sectors.push({
                index: sectorIdx,
                flightNumber: vals[fltIdx],
                depStation: depStation,
                arrStation: arrStation,
                depTime: depTime,
                arrTime: arrTime,
                date: dateStr,
                duration: 0,
                durationStr: durationStr
            });
            sectorIdx++;
        }

        if (currentTrip && currentTrip.sectors.length > 0) {
            trips.push(currentTrip);
        }

        if (trips.length === 0) {
            return JSON.stringify({ error: "noRoster", sampleKeys: sampleRow || [debugInfo + ",noFlightRows"] });
        }

        return JSON.stringify({
            trips: trips,
            sampleKeys: sampleRow,
            debug: debugInfo
        });
    })();
    """
}

// MARK: - Roster JSON Models

private struct RosterResponse: Decodable {
    let trips: [RosterTripJSON]?
    let error: String?
    let sampleKeys: [String]?
}

private struct RosterTripJSON: Decodable {
    let tripNo: String
    let sectors: [RosterSectorJSON]
}

private struct RosterSectorJSON: Decodable {
    let index: Int
    let flightNumber: String
    let depStation: String
    let arrStation: String
    let depTime: String
    let arrTime: String
    let date: String
    let duration: Double
    let durationStr: String?
}
