import SwiftUI
import SwiftData
import WebKit

// MARK: - Roster Import View

/// Loads the SharePoint crew portal in a WebView and extracts the full month's
/// roster directly from the portal's own `localStorage` (`Roster_*` entries
/// plus `Position_*` per-flight detail for aircraft registration).
///
/// Imports are upserts: trips that already exist in SwiftData get their
/// portal-sourced fields refreshed, while user-entered fields
/// (`savedActualLandingTime`, `savedFlightTime`, annotations, crew positions,
/// evidence photos, etc.) are preserved. Trips already in SwiftData that no
/// longer appear in the portal are left untouched.
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

    /// Tracks the last successful sync timestamp so Flight Planner home can
    /// surface a "stale roster" banner when this gets too old.
    @AppStorage("rosterLastSyncedAt") private var lastSyncedAtRaw: Double = 0

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
        .alert("Import Error", isPresented: $showError) {
            Button("OK") {}
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

    // MARK: - Import Trigger

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

    // MARK: - Processing

    private func processRosterJSON(_ jsonString: String) {
        guard let data = jsonString.data(using: .utf8) else {
            errorMessage = "Failed to read extracted data."
            showError = true
            return
        }

        let decoded: RosterPayload
        do {
            decoded = try JSONDecoder().decode(RosterPayload.self, from: data)
        } catch {
            errorMessage = "Failed to parse roster data: \(error.localizedDescription)\n\nTap 'Copy Raw Data' to inspect."
            showError = true
            return
        }

        if let err = decoded.error {
            switch err {
            case "notLoggedIn":
                errorMessage = "Not logged in. Please sign in to the crew portal first."
            case "noRoster":
                errorMessage = "No roster data found. Make sure your roster is loaded on the page."
            default:
                errorMessage = "Extraction error: \(err)"
            }
            showError = true
            return
        }

        let trips = decoded.trips ?? []
        let duties = decoded.duties ?? []

        if trips.isEmpty && duties.isEmpty {
            errorMessage = "No trips or duties found in the roster data."
            showError = true
            return
        }

        let tripResult = upsertTrips(trips)
        let dutyResult = upsertDuties(duties)
        lastSyncedAtRaw = Date().timeIntervalSince1970

        var parts: [String] = []
        if tripResult.inserted + dutyResult.inserted > 0 {
            parts.append("\(tripResult.inserted + dutyResult.inserted) new")
        }
        if tripResult.updated + dutyResult.updated > 0 {
            parts.append("\(tripResult.updated + dutyResult.updated) updated")
        }
        if tripResult.unchanged + dutyResult.unchanged > 0 {
            parts.append("\(tripResult.unchanged + dutyResult.unchanged) unchanged")
        }
        if tripResult.mergedDuplicates > 0 {
            parts.append("\(tripResult.mergedDuplicates) duplicate\(tripResult.mergedDuplicates == 1 ? "" : "s") merged")
        }
        let monthLabel = decoded.monthLabel ?? "roster"
        importSummary = parts.isEmpty
            ? "No changes found in \(monthLabel)."
            : "\(monthLabel): " + parts.joined(separator: " · ") + "."
        showSummary = true
    }

    // MARK: - Upsert

    /// Outcome of a roster import. Counters are over the trips parsed from the
    /// portal; trips already in SwiftData that aren't in this batch are left
    /// untouched (we never destructively delete on import).
    private struct UpsertResult {
        var inserted: Int = 0
        var updated: Int = 0
        var unchanged: Int = 0
        var mergedDuplicates: Int = 0
    }

    private func upsertTrips(_ trips: [PortalTripJSON]) -> UpsertResult {
        let allExisting: [PlannedFlight]
        do {
            allExisting = try modelContext.fetch(FetchDescriptor<PlannedFlight>())
        } catch {
            return UpsertResult()
        }

        let dateOnlyParser = DateFormatter()
        dateOnlyParser.dateFormat = "dd/MM/yy"
        dateOnlyParser.locale = Locale(identifier: "en_US_POSIX")

        var result = UpsertResult()
        let cal = Calendar.current

        // STEP 1: Deduplicate existing trips by (digit-only tripNumber, calendar day).
        // Earlier imports could produce variants like "6201" vs "EK 6201" with subtle
        // formatting drift, leaving duplicate trips on disk. Merge them by keeping
        // the one with the most sector data and dropping the rest.
        var groups: [String: [PlannedFlight]] = [:]
        for trip in allExisting {
            let key = Self.tripKey(tripNumber: trip.tripNumber, date: trip.flightDate, calendar: cal)
            groups[key, default: []].append(trip)
        }

        var deduped: [PlannedFlight] = []
        for (_, members) in groups {
            if members.count == 1 {
                deduped.append(members[0])
                continue
            }
            // Multiple trips for the same logical (tripNumber, day). Keep the one
            // with the richest sector data; if tied, the most recently created.
            let keeper = members.max { lhs, rhs in
                if lhs.sectors.count != rhs.sectors.count { return lhs.sectors.count < rhs.sectors.count }
                return lhs.createdAt < rhs.createdAt
            } ?? members[0]
            deduped.append(keeper)
            for stale in members where stale.id != keeper.id {
                for sector in stale.sectors { modelContext.delete(sector) }
                modelContext.delete(stale)
                result.mergedDuplicates += 1
            }
        }

        // STEP 2: Upsert against deduped trips.
        for portalTrip in trips {
            guard !portalTrip.sectors.isEmpty,
                  let firstSector = portalTrip.sectors.first,
                  let tripDate = dateOnlyParser.date(from: firstSector.depDate) else { continue }

            let portalKey = Self.tripKey(tripNumber: portalTrip.tripNo, date: tripDate, calendar: cal)

            let match = deduped.first { trip in
                Self.tripKey(tripNumber: trip.tripNumber, date: trip.flightDate, calendar: cal) == portalKey
            }

            if let trip = match {
                let changed = applyUpdate(to: trip, from: portalTrip, tripDate: tripDate)
                if changed { result.updated += 1 } else { result.unchanged += 1 }
            } else {
                insertNew(portalTrip: portalTrip, tripDate: tripDate)
                result.inserted += 1
            }
        }

        try? modelContext.save()
        return result
    }

    /// Stable key for a trip independent of trip-number formatting drift
    /// (whitespace, casing, leading zeros). Uses digits-only + calendar day.
    private static func tripKey(tripNumber: String, date: Date, calendar: Calendar) -> String {
        let digits = tripNumber.filter(\.isNumber)
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(digits)_\(comps.year ?? 0)_\(comps.month ?? 0)_\(comps.day ?? 0)"
    }

    // MARK: - Duty Upsert

    private struct DutyUpsertResult {
        var inserted: Int = 0
        var updated: Int = 0
        var unchanged: Int = 0
    }

    private func upsertDuties(_ duties: [PortalDutyJSON]) -> DutyUpsertResult {
        guard !duties.isEmpty else { return DutyUpsertResult() }

        let existing: [PlannedDuty]
        do {
            existing = try modelContext.fetch(FetchDescriptor<PlannedDuty>())
        } catch {
            return DutyUpsertResult()
        }

        let dateOnlyParser = DateFormatter()
        dateOnlyParser.dateFormat = "dd/MM/yy"
        dateOnlyParser.locale = Locale(identifier: "en_US_POSIX")

        let cal = Calendar.current
        var byKey: [String: PlannedDuty] = [:]
        for d in existing {
            byKey[Self.dutyKey(code: d.code, date: d.date, calendar: cal)] = d
        }

        var result = DutyUpsertResult()
        let now = Date()

        for portalDuty in duties {
            guard let date = dateOnlyParser.date(from: portalDuty.date) else { continue }
            let dayStart = cal.startOfDay(for: date)
            let normalisedCode = portalDuty.code.uppercased()
            let key = Self.dutyKey(code: normalisedCode, date: dayStart, calendar: cal)

            let category = DutyClassifier.category(forCode: normalisedCode)
            let startDate = absoluteDate(date: portalDuty.date, time: portalDuty.startTime ?? "", parser: dateOnlyParser)
            let endDateStr = portalDuty.endDate ?? portalDuty.date
            let endDate = absoluteDate(date: endDateStr, time: portalDuty.endTime ?? "", parser: dateOnlyParser)

            if let duty = byKey[key] {
                var didChange = false
                if duty.title != portalDuty.title { duty.title = portalDuty.title; didChange = true }
                if duty.startTime != portalDuty.startTime { duty.startTime = portalDuty.startTime?.nilIfEmpty; didChange = true }
                if duty.endTime != portalDuty.endTime { duty.endTime = portalDuty.endTime?.nilIfEmpty; didChange = true }
                if duty.startDate != startDate { duty.startDate = startDate; didChange = true }
                if duty.endDate != endDate { duty.endDate = endDate; didChange = true }
                if duty.category != category { duty.categoryRaw = category.rawValue; didChange = true }
                duty.lastSyncedAt = now
                if didChange { result.updated += 1 } else { result.unchanged += 1 }
            } else {
                let new = PlannedDuty(
                    date: dayStart,
                    code: normalisedCode,
                    category: category,
                    title: portalDuty.title,
                    startTime: portalDuty.startTime?.nilIfEmpty,
                    endTime: portalDuty.endTime?.nilIfEmpty,
                    startDate: startDate,
                    endDate: endDate,
                    lastSyncedAt: now
                )
                modelContext.insert(new)
                result.inserted += 1
            }
        }

        try? modelContext.save()
        return result
    }

    private static func dutyKey(code: String, date: Date, calendar: Calendar) -> String {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(code.uppercased())_\(comps.year ?? 0)_\(comps.month ?? 0)_\(comps.day ?? 0)"
    }

    private func absoluteDate(date: String, time: String, parser: DateFormatter) -> Date? {
        guard let base = parser.date(from: date) else { return nil }
        let parts = time.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return base }
        return Calendar.current.date(bySettingHour: parts[0], minute: parts[1], second: 0, of: base) ?? base
    }

    /// Updates portal-sourced fields on `trip`, preserving every `saved*`
    /// field and per-sector annotations / crew data. Returns `true` if any
    /// field actually changed.
    private func applyUpdate(to trip: PlannedFlight,
                              from portalTrip: PortalTripJSON,
                              tripDate: Date) -> Bool {
        let dateOnlyParser = DateFormatter()
        dateOnlyParser.dateFormat = "dd/MM/yy"
        dateOnlyParser.locale = Locale(identifier: "en_US_POSIX")

        var didChange = false

        // Trip-level
        if trip.tripNumber != portalTrip.tripNo { trip.tripNumber = portalTrip.tripNo; didChange = true }
        if !Calendar.current.isDate(trip.flightDate, inSameDayAs: tripDate) {
            trip.flightDate = tripDate; didChange = true
        }
        let inferredType = determineTripType(sectors: portalTrip.sectors, dateParser: dateOnlyParser)
        if trip.tripType != inferredType { trip.tripType = inferredType; didChange = true }

        let firstSector = portalTrip.sectors.first!
        let lastSector = portalTrip.sectors.last ?? firstSector
        let prefixedFlightNumber = "EK " + firstSector.flightNumber.trimmingCharacters(in: .whitespaces)
        if trip.flightNumber != prefixedFlightNumber { trip.flightNumber = prefixedFlightNumber; didChange = true }
        if trip.departure != firstSector.depStation { trip.departure = firstSector.depStation; didChange = true }
        if trip.arrival != lastSector.arrStation { trip.arrival = lastSector.arrStation; didChange = true }

        // Sectors — match by index. Preserve every `saved*` field.
        var existingByIndex: [Int: PlannedSector] = [:]
        for sector in trip.sectors {
            existingByIndex[sector.sectorIndex] = sector
        }

        for (i, portalSector) in portalTrip.sectors.enumerated() {
            let sectorDate = dateOnlyParser.date(from: portalSector.depDate) ?? tripDate
            let prefixedSectorFlight = "EK " + portalSector.flightNumber.trimmingCharacters(in: .whitespaces)
            let registration = portalSector.registration?.trimmingCharacters(in: .whitespaces).nilIfEmpty
            let duration = portalSector.duration?.trimmingCharacters(in: .whitespaces).nilIfEmpty

            if let sector = existingByIndex[i] {
                if sector.flightNumber != prefixedSectorFlight { sector.flightNumber = prefixedSectorFlight; didChange = true }
                if !Calendar.current.isDate(sector.date, inSameDayAs: sectorDate) {
                    sector.date = sectorDate; didChange = true
                }
                if sector.departureStation != portalSector.depStation { sector.departureStation = portalSector.depStation; didChange = true }
                if sector.arrivalStation != portalSector.arrStation { sector.arrivalStation = portalSector.arrStation; didChange = true }
                if sector.departureTime != portalSector.depTime { sector.departureTime = portalSector.depTime; didChange = true }
                if sector.arrivalTime != portalSector.arrTime { sector.arrivalTime = portalSector.arrTime; didChange = true }
                if let reg = registration, sector.registration != reg {
                    sector.registration = reg; didChange = true
                }
                if let dur = duration, sector.savedFlightTime != dur {
                    sector.savedFlightTime = dur; didChange = true
                }
                // Note: sector.saved* fields (actuals, annotations, crew, evidence)
                // are deliberately untouched.
            } else {
                // Sector index added on the portal side — create new.
                let new = PlannedSector(
                    sectorIndex: i,
                    flightNumber: prefixedSectorFlight,
                    date: sectorDate,
                    departureStation: portalSector.depStation,
                    arrivalStation: portalSector.arrStation,
                    departureTime: portalSector.depTime,
                    arrivalTime: portalSector.arrTime
                )
                new.registration = registration
                new.savedFlightTime = duration
                new.parentTrip = trip
                trip.sectors.append(new)
                didChange = true
            }
        }

        // If the portal removed sectors that we previously had, drop the extras.
        // Keep only indices that exist in the portal payload.
        let portalIndices = Set(0..<portalTrip.sectors.count)
        for sector in trip.sectors where !portalIndices.contains(sector.sectorIndex) {
            modelContext.delete(sector)
            didChange = true
        }

        return didChange
    }

    private func insertNew(portalTrip: PortalTripJSON, tripDate: Date) {
        let dateOnlyParser = DateFormatter()
        dateOnlyParser.dateFormat = "dd/MM/yy"
        dateOnlyParser.locale = Locale(identifier: "en_US_POSIX")

        let firstSector = portalTrip.sectors.first!
        let lastSector = portalTrip.sectors.last ?? firstSector
        let tripType = determineTripType(sectors: portalTrip.sectors, dateParser: dateOnlyParser)

        let flight = PlannedFlight(
            tripNumber: portalTrip.tripNo,
            tripType: tripType,
            flightNumber: "EK " + firstSector.flightNumber.trimmingCharacters(in: .whitespaces),
            flightDate: tripDate,
            departure: firstSector.depStation,
            arrival: lastSector.arrStation
        )

        var prevSector: PortalSectorJSON?
        for (i, sectorJSON) in portalTrip.sectors.enumerated() {
            let sectorDate = dateOnlyParser.date(from: sectorJSON.depDate) ?? tripDate
            let sector = PlannedSector(
                sectorIndex: i,
                flightNumber: "EK " + sectorJSON.flightNumber.trimmingCharacters(in: .whitespaces),
                date: sectorDate,
                departureStation: sectorJSON.depStation,
                arrivalStation: sectorJSON.arrStation,
                departureTime: sectorJSON.depTime,
                arrivalTime: sectorJSON.arrTime
            )
            sector.registration = sectorJSON.registration?.trimmingCharacters(in: .whitespaces).nilIfEmpty
            sector.savedFlightTime = sectorJSON.duration?.trimmingCharacters(in: .whitespaces).nilIfEmpty

            if let prev = prevSector {
                let gap = Self.gapMinutes(
                    arrTime: prev.arrTime, arrDate: prev.arrDate,
                    depTime: sectorJSON.depTime, depDate: sectorJSON.depDate,
                    parser: dateOnlyParser
                )
                sector.savedIsLayover = gap > 360 // 6 hours, matches TripRules.continuousMaxMinutes
            }

            sector.parentTrip = flight
            flight.sectors.append(sector)
            prevSector = sectorJSON
        }

        modelContext.insert(flight)
    }

    // MARK: - Trip Type Inference

    private func determineTripType(sectors: [PortalSectorJSON], dateParser: DateFormatter) -> TripType {
        if sectors.count > 2 { return .transit }
        if sectors.count == 2,
           let firstDate = dateParser.date(from: sectors[0].depDate),
           let lastDate = dateParser.date(from: sectors[1].depDate),
           Calendar.current.isDate(firstDate, inSameDayAs: lastDate) {
            return .turnaround
        }
        return .layover
    }

    // MARK: - Gap Helper

    private static func gapMinutes(arrTime: String, arrDate: String,
                                    depTime: String, depDate: String,
                                    parser: DateFormatter) -> Int {
        guard let aDate = parser.date(from: arrDate),
              let dDate = parser.date(from: depDate) else { return 0 }
        let aParts = arrTime.split(separator: ":").compactMap { Int($0) }
        let dParts = depTime.split(separator: ":").compactMap { Int($0) }
        guard aParts.count == 2, dParts.count == 2 else { return 0 }
        let cal = Calendar.current
        guard let arrival = cal.date(bySettingHour: aParts[0], minute: aParts[1], second: 0, of: aDate),
              let departure = cal.date(bySettingHour: dParts[0], minute: dParts[1], second: 0, of: dDate)
        else { return 0 }
        return Int(departure.timeIntervalSince(arrival) / 60)
    }

    // MARK: - Cache Flush

    /// Clears caches and non-login cookies so SharePoint serves fresh roster
    /// data while keeping the Microsoft auth session intact.
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
                group.notify(queue: .main) { completion() }
            }
        }
    }

    // MARK: - Scraper Script

    /// Pulls the full month from two sources on the portal page:
    ///
    /// 1. **`localStorage` (`Roster_*` + `Position_*`)** — rich trip + sector data
    ///    including dates, times, durations, and aircraft registration.
    /// 2. **DOM scrape of `a.duty` elements** — non-flight duties (Day Off,
    ///    AVD, Airport / Home / High-Quality Standby, training, ground duty)
    ///    that aren't otherwise represented in localStorage.
    ///
    /// Returns a normalized JSON payload with both `trips` and `duties`.
    static let rosterScraperScript: String = """
    (function() {
        function safeParse(str) {
            try { return JSON.parse(str); } catch(e) { return null; }
        }

        // Convert "DD/MM/YYYY HH:mm" / "DD/MM/YY HH:mm" → { date: "DD/MM/YY", time: "HH:mm" }.
        function parseStamp(raw) {
            if (!raw) return { date: "", time: "" };
            var parts = String(raw).split(" ");
            var d = parts[0] || "";
            var t = parts[1] || "";
            var dp = d.split("/");
            if (dp.length === 3) {
                var dd = dp[0].padStart(2, "0");
                var mm = dp[1].padStart(2, "0");
                var yy = dp[2];
                if (yy.length === 4) yy = yy.substring(2);
                d = dd + "/" + mm + "/" + yy.padStart(2, "0");
            }
            // HH:mm extraction (drops seconds if present).
            var tp = t.split(":");
            if (tp.length >= 2) t = tp[0].padStart(2, "0") + ":" + tp[1].padStart(2, "0");
            return { date: d, time: t };
        }

        var staffNo = localStorage.getItem("CurrentStaffNo");
        if (!staffNo) {
            return JSON.stringify({ error: "notLoggedIn" });
        }

        // Find all Roster_<staff>_* entries.
        var rosterKeys = Object.keys(localStorage).filter(function(k) {
            return k.indexOf("Roster_" + staffNo) === 0
                && k.indexOf("TimeOut") < 0
                && k.indexOf("Destination") < 0;
        });

        if (rosterKeys.length === 0) {
            return JSON.stringify({ error: "noRoster" });
        }

        // Build an aircraft-registration index from Position_* keys.
        // Position keys look like Position_..._<FltNo>_<DD-MM-YY>
        var regIndex = {};
        Object.keys(localStorage).forEach(function(k) {
            if (k.indexOf("Position_") !== 0 || k.indexOf("TimeOut") >= 0) return;
            var val = safeParse(localStorage.getItem(k));
            if (!val) return;
            var flightArr = val.FlightData || (val.flightData && val.flightData.FlightData);
            if (!flightArr) return;
            for (var f = 0; f < flightArr.length; f++) {
                var fd = flightArr[f];
                var fltNo = fd.FltNo || fd.flightNo || "";
                var dep = parseStamp(fd.DepDate || fd.depDate);
                if (!fltNo || !dep.date) continue;
                var reg = fd.Reg || fd.reg || fd.AircraftReg || fd.aircraftReg || "";
                if (!reg) continue;
                regIndex[fltNo + "_" + dep.date] = String(reg).trim();
            }
        });

        var trips = [];
        var monthLabel = "";

        rosterKeys.forEach(function(rk) {
            var v = safeParse(localStorage.getItem(rk));
            if (!v || !v.StaffRosters || !v.StaffRosters[0]) return;
            var roster = v.StaffRosters[0];
            var trp = roster.RosterData && roster.RosterData.CrewRosterResonse
                && roster.RosterData.CrewRosterResonse.Trips
                && roster.RosterData.CrewRosterResonse.Trips.Trp;
            if (!trp) return;

            // Month label inference from the first trip's date.
            if (!monthLabel && trp.length > 0 && trp[0].StartDate) {
                var s = parseStamp(trp[0].StartDate);
                if (s.date) {
                    var dp = s.date.split("/");
                    var mNames = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
                    var mIdx = parseInt(dp[1], 10) - 1;
                    if (mIdx >= 0 && mIdx < 12) {
                        monthLabel = mNames[mIdx] + " 20" + dp[2];
                    }
                }
            }

            trp.forEach(function(t) {
                if (!t.Dty || t.Dty.length === 0) return;
                var sectors = [];
                var idx = 0;
                t.Dty.forEach(function(duty) {
                    if (!duty.Flt) return;
                    duty.Flt.forEach(function(flt) {
                        var dep = parseStamp(flt.DepDate);
                        var arr = parseStamp(flt.ArrDate);
                        var fltNo = String(flt.FltNo || "").trim();
                        var key = fltNo + "_" + dep.date;
                        sectors.push({
                            index: idx,
                            flightNumber: fltNo,
                            depStation: String(flt.DepStn || "").trim(),
                            arrStation: String(flt.ArrStn || "").trim(),
                            depDate: dep.date,
                            depTime: dep.time,
                            arrDate: arr.date,
                            arrTime: arr.time,
                            duration: String(flt.Duration || "").trim(),
                            registration: regIndex[key] || ""
                        });
                        idx++;
                    });
                });
                if (sectors.length === 0) return;
                trips.push({
                    tripNo: String(t.TripNo || "").trim(),
                    sectors: sectors
                });
            });
        });

        // ---- DOM pass: non-flight duties (XX, AVD, standby, etc.) ----
        // Each duty is rendered as <a class="duty trip-popover ..."> with:
        //   data-trip-type   "leave" | "training" | "trip"
        //   data-original-title  human-readable label
        //   data-content     "Wed 03-Jun-26, 00:01 - Thu 04-Jun-26, 00:00"
        //   custom attribute like xxr_3'  (we use the prefix to pin a code)
        var duties = [];
        var monthAbbrev = {
            JAN:"01",FEB:"02",MAR:"03",APR:"04",MAY:"05",JUN:"06",
            JUL:"07",AUG:"08",SEP:"09",OCT:"10",NOV:"11",DEC:"12"
        };
        function parseDutyStamp(s) {
            // "Wed 03-Jun-26, 00:01" → { date: "03/06/26", time: "00:01" }
            if (!s) return null;
            var m = s.match(/(\\d{1,2})-([A-Za-z]{3})-(\\d{2,4}),\\s*(\\d{1,2}):(\\d{2})/);
            if (!m) return null;
            var dd = m[1].padStart(2, "0");
            var mm = monthAbbrev[m[2].toUpperCase()] || "01";
            var yy = m[3];
            if (yy.length === 4) yy = yy.substring(2);
            return { date: dd + "/" + mm + "/" + yy.padStart(2, "0"),
                     time: m[4].padStart(2, "0") + ":" + m[5] };
        }
        function splitDutyContent(content) {
            // "Wed 03-Jun-26, 00:01 - Thu 04-Jun-26, 00:00"
            if (!content) return { start: null, end: null };
            var parts = content.split(" - ");
            return {
                start: parts[0] ? parseDutyStamp(parts[0].trim()) : null,
                end: parts[1] ? parseDutyStamp(parts[1].trim()) : null
            };
        }
        function dutyCodeFromAttrs(el) {
            // Look for the custom marker attribute like xxr_3'='' on the element.
            // Returns the prefix uppercased (XXR, AVD, SA0200, SL08, S06, etc.).
            var attrs = el.attributes;
            for (var i = 0; i < attrs.length; i++) {
                var name = attrs[i].name || "";
                var stripped = name.replace(/'$/, "");
                var m = stripped.match(/^([a-z]+\\d*)_\\d+$/i);
                if (m) return m[1].toUpperCase();
            }
            return "";
        }
        var dutyEls = document.querySelectorAll("a.duty");
        for (var di = 0; di < dutyEls.length; di++) {
            var el = dutyEls[di];
            var tripType = (el.getAttribute("data-trip-type") || "").toLowerCase();
            if (tripType === "trip") continue; // trips come from localStorage
            var content = el.getAttribute("data-content") || "";
            var title = (el.getAttribute("data-original-title") || "").trim();
            var range = splitDutyContent(content);
            if (!range.start) continue;
            var code = dutyCodeFromAttrs(el);
            if (!code) {
                if (tripType === "leave") {
                    code = "XX";
                } else {
                    // Fall back to the visible label, uppercased and de-spaced.
                    var visible = (el.textContent || "").trim().replace(/\\s+/g, "");
                    code = visible.toUpperCase() || "GD";
                }
            }
            duties.push({
                code: code,
                tripType: tripType,
                title: title,
                date: range.start.date,
                startTime: range.start.time,
                endTime: range.end ? range.end.time : "",
                endDate: range.end ? range.end.date : range.start.date
            });
        }

        if (trips.length === 0 && duties.length === 0) {
            return JSON.stringify({ error: "noRoster" });
        }

        return JSON.stringify({
            trips: trips,
            duties: duties,
            monthLabel: monthLabel
        });
    })();
    """
}

// MARK: - JSON Models

private struct RosterPayload: Decodable {
    let trips: [PortalTripJSON]?
    let duties: [PortalDutyJSON]?
    let monthLabel: String?
    let error: String?
}

private struct PortalTripJSON: Decodable {
    let tripNo: String
    let sectors: [PortalSectorJSON]
}

private struct PortalSectorJSON: Decodable {
    let index: Int
    let flightNumber: String
    let depStation: String
    let arrStation: String
    let depDate: String
    let depTime: String
    let arrDate: String
    let arrTime: String
    let duration: String?
    let registration: String?
}

private struct PortalDutyJSON: Decodable {
    let code: String
    let tripType: String
    let title: String
    let date: String
    let startTime: String?
    let endTime: String?
    let endDate: String?
}

// MARK: - String Helper

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
