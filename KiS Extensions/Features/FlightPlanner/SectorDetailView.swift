import SwiftUI
import SwiftData

// MARK: - Sector Detail View

struct SectorDetailView: View {
    let sector: PlannedSector
    @Environment(\.dismiss) private var dismiss
    @Query private var settingsArray: [AppSettings]

    private var openAllCards: Bool {
        settingsArray.first?.openAllCardsSimultaneously ?? true
    }

    @State private var sidebarExpanded = false
    @State private var selectedTab: SidebarTab = .timeline
    @State private var selectedRowID: String?
    @State private var briefingExpanded = true
    @State private var groundDutiesExpanded = true
    @State private var inflightExpanded = true
    @State private var afterLandingExpanded = true

    // MARK: - Crew Rest (embedded)

    @State private var crewRestState = CrewRestState()
    @State private var showCrewRestResults = false
    @State private var crewRestInitialized = false

    // MARK: - Adjustable Time Fields

    @State private var std: Date = Date()
    @State private var scheduledBlockTime: Date = Date()
    @State private var sta: Date = Date()
    @State private var flightTime: Date = Date()
    @State private var pushBack: Date = Date()
    @State private var takeOffTime: Date = Date()
    @State private var takeOffManuallyEdited = false

    // MARK: - Service Fields

    @State private var numberOfServices: Int = 1
    @State private var service1JC: Int = 0
    @State private var service1WC: Int = 0
    @State private var service1YC: Int = 0
    @State private var service2JC: Int = 0
    @State private var service2WC: Int = 0
    @State private var service2YC: Int = 0
    @State private var service3JC: Int = 0
    @State private var service3WC: Int = 0
    @State private var service3YC: Int = 0

    private static let serviceDurations: [Int] = stride(from: 0, through: 180, by: 15).map { $0 }

    private func formatDuration(_ minutes: Int) -> String {
        if minutes == 0 { return "None" }
        let h = minutes / 60
        let m = minutes % 60
        return String(format: "%d:%02d", h, m)
    }

    // MARK: - Ground Duties Actual Times

    @State private var actualArriveAircraft: Date? = nil
    @State private var actualCabinAppearance: Date? = nil
    @State private var actualSafetyChecks: Date? = nil
    @State private var actualAutoBoarding: Date? = nil
    @State private var actualOffloadNoShow: Date? = nil
    @State private var actualClosingDoor: Date? = nil
    @State private var actualArmingDoor: Date? = nil

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd-MMM-yy"
        return f
    }()

    private var trip: PlannedFlight? { sector.parentTrip }

    // MARK: - Timezone Helpers

    private static let durationTZ = TimeZone(identifier: "UTC")!
    private static let dxbTZ = TimeZone(identifier: "Asia/Dubai")!

    private var depTZ: TimeZone {
        StationTimezones.timeZone(for: sector.departureStation) ?? TimeZone(identifier: "Asia/Dubai")!
    }

    private var arrTZ: TimeZone {
        StationTimezones.timeZone(for: sector.arrivalStation) ?? TimeZone(identifier: "Asia/Dubai")!
    }

    private func formatTime(_ date: Date, in tz: TimeZone) -> String {
        var cal = Calendar.current
        cal.timeZone = tz
        let h = cal.component(.hour, from: date)
        let m = cal.component(.minute, from: date)
        return String(format: "%02d:%02d", h, m)
    }

    private func formatDepTime(_ date: Date) -> String {
        formatTime(date, in: Self.dxbTZ)
    }

    private func formatArrTime(_ date: Date) -> String {
        formatTime(date, in: Self.dxbTZ)
    }

    private func formatDurationTime(_ date: Date) -> String {
        formatTime(date, in: Self.durationTZ)
    }

    private var takeOffTimeManualBinding: Binding<Date> {
        Binding(
            get: { takeOffTime },
            set: { newValue in
                takeOffTime = newValue
                takeOffManuallyEdited = true
            }
        )
    }

    // MARK: - Sector Flight Type

    private enum SectorFlightType {
        case dxbDeparture
        case turnaroundTransit
        case layoverReturn
    }

    private var sectorFlightType: SectorFlightType {
        guard let trip = sector.parentTrip else {
            return sector.departureStation == "DXB" ? .dxbDeparture : .turnaroundTransit
        }
        let sorted = trip.sortedSectors
        guard let currentIndex = sorted.firstIndex(where: { $0.id == sector.id }) else {
            return sector.departureStation == "DXB" ? .dxbDeparture : .turnaroundTransit
        }
        if currentIndex == 0 && sector.departureStation == "DXB" {
            return .dxbDeparture
        }
        if sector.savedIsLayover == true {
            return .layoverReturn
        }
        if currentIndex > 0 {
            let prev = sorted[currentIndex - 1]
            let prevArrTZ = StationTimezones.timeZone(for: prev.arrivalStation) ?? Self.dxbTZ
            let curDepTZ = StationTimezones.timeZone(for: sector.departureStation) ?? Self.dxbTZ
            let prevArrival = timeFromString(prev.arrivalTime, in: prevArrTZ, on: prev.date)
            var adjustedPrevArrival = prevArrival
            let prevDep = timeFromString(prev.departureTime, in: StationTimezones.timeZone(for: prev.departureStation) ?? Self.dxbTZ, on: prev.date)
            if prevArrival < prevDep {
                adjustedPrevArrival = Calendar.current.date(byAdding: .day, value: 1, to: prevArrival) ?? prevArrival
            }
            let curDeparture = timeFromString(sector.departureTime, in: curDepTZ, on: sector.date)
            let gapHours = curDeparture.timeIntervalSince(adjustedPrevArrival) / 3600
            if gapHours >= 12 {
                return .layoverReturn
            }
        }
        return .turnaroundTransit
    }

    private var showsBriefingSection: Bool {
        sectorFlightType != .turnaroundTransit
    }

    // MARK: - Time Helpers

    private func timeFromString(_ str: String, in tz: TimeZone) -> Date {
        timeFromString(str, in: tz, on: sector.date)
    }

    private func timeFromString(_ str: String, in tz: TimeZone, on date: Date) -> Date {
        let components = str.split(separator: ":").compactMap { Int($0) }
        guard components.count == 2 else { return Date() }
        var cal = Calendar.current
        cal.timeZone = tz
        let base = cal.startOfDay(for: date)
        return cal.date(bySettingHour: components[0], minute: components[1], second: 0, of: base) ?? base
    }

    private func addMinutes(_ date: Date, _ minutes: Int) -> Date {
        Calendar.current.date(byAdding: .minute, value: minutes, to: date) ?? date
    }

    private var calculatedLandingTime: Date {
        var cal = Calendar.current
        cal.timeZone = Self.durationTZ
        let flightMinutes = Int(flightTime.timeIntervalSince(cal.startOfDay(for: flightTime))) / 60
        return addMinutes(takeOffTime, flightMinutes)
    }

    private var blockTimeMinutes: Int {
        var cal = Calendar.current
        cal.timeZone = Self.durationTZ
        return Int(scheduledBlockTime.timeIntervalSince(cal.startOfDay(for: scheduledBlockTime))) / 60
    }

    private var isLongHaul: Bool {
        blockTimeMinutes >= 210 // 3h30m
    }

    private var hasWCCabin: Bool {
        guard let reg = sector.registration,
              let typeCode = FleetRegistry.fleet[reg],
              let acType = AircraftTypes.types[typeCode] else { return false }
        return acType.classes >= 4
    }

    private var settlingInStart: Date {
        addMinutes(takeOffTime, 10)
    }

    private var settlingInEnd: Date {
        addMinutes(takeOffTime, 30)
    }

    private var serviceStartTime: Date {
        isLongHaul ? settlingInEnd : addMinutes(takeOffTime, 10)
    }

    private var twentyToTop: Date {
        addMinutes(calculatedLandingTime, -50)
    }

    private var topOfDescent: Date {
        addMinutes(calculatedLandingTime, -30)
    }

    private var cabinSecure: Date {
        addMinutes(calculatedLandingTime, -15)
    }

    private let collapsedWidth: CGFloat = 56
    private let expandedWidth: CGFloat = 240

    private var serviceSnapshot: ServiceSnapshot {
        ServiceSnapshot(
            numberOfServices: numberOfServices,
            s1jc: service1JC, s1wc: service1WC, s1yc: service1YC,
            s2jc: service2JC, s2wc: service2WC, s2yc: service2YC,
            s3jc: service3JC, s3wc: service3WC, s3yc: service3YC,
            a1: actualArriveAircraft, a2: actualCabinAppearance,
            a3: actualSafetyChecks, a4: actualAutoBoarding,
            a5: actualOffloadNoShow, a6: actualClosingDoor,
            a7: actualArmingDoor
        )
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            contentArea
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        .animation(.easeInOut(duration: 0.25), value: sidebarExpanded)
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack(spacing: 20) {
            // Back button
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.bold())
                    .foregroundStyle(Color.accentColor)
            }
            .padding(.leading, 4)

            // Route
            VStack(alignment: .leading, spacing: 2) {
                Text("Route")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    Text(sector.departureStation)
                        .font(.body.bold())
                    Image(systemName: "airplane")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                    Text(sector.arrivalStation)
                        .font(.body.bold())
                }
            }

            Divider()
                .frame(height: 34)

            // Flight number
            VStack(alignment: .leading, spacing: 2) {
                Text("Flight No.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(sector.flightNumber)
                    .font(.body.bold())
            }

            Divider()
                .frame(height: 34)

            // Flight date
            VStack(alignment: .leading, spacing: 2) {
                Text("Flight Date")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(Self.dateFormatter.string(from: sector.date))
                    .font(.body.bold())
            }

            Divider()
                .frame(height: 34)

            // STD
            VStack(alignment: .leading, spacing: 2) {
                Text("STD")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(sector.departureTime)
                    .font(.body.bold().monospaced())
            }

            Divider()
                .frame(height: 34)

            // STA
            VStack(alignment: .leading, spacing: 2) {
                Text("STA")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(sector.arrivalTime)
                    .font(.body.bold().monospaced())
            }

            Divider()
                .frame(height: 34)

            // Block Time
            VStack(alignment: .leading, spacing: 2) {
                Text("Block Time")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(formatDurationTime(scheduledBlockTime))
                    .font(.body.bold().monospaced())
            }

            Divider()
                .frame(height: 34)

            // AC Registration
            VStack(alignment: .leading, spacing: 2) {
                Text("Registration")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(sector.registration ?? "—")
                    .font(.body.bold())
            }

            Spacer()

            NavigationLink(value: trip.map { FlightPlannerDestination.editTrip($0.id) }) {
                HStack(spacing: 4) {
                    Image(systemName: "pencil")
                    Text("Edit Flight")
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(.systemBackground))
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    // MARK: - Content Area

    private var contentArea: some View {
        ZStack(alignment: .leading) {
            HStack(spacing: 0) {
                // Collapsed icon rail (always visible)
                iconRail
                    .frame(width: collapsedWidth)
                    .background(Color(.systemBackground))

                Divider()

                // Main content area
                mainContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGroupedBackground))
            }

            // Flyover expanded sidebar
            if sidebarExpanded {
                // Dimmed backdrop
                Color.black.opacity(0.15)
                    .onTapGesture {
                        sidebarExpanded = false
                    }

                // Expanded panel
                expandedSidebar
                    .frame(width: expandedWidth)
                    .frame(maxHeight: .infinity)
                    .background(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.12), radius: 12, x: 4, y: 0)
                    .transition(.move(edge: .leading))
            }
        }
    }

    // MARK: - Icon Rail (collapsed sidebar)

    private var iconRail: some View {
        VStack(spacing: 0) {
            // Expand chevron
            Button {
                sidebarExpanded = true
            } label: {
                Image(systemName: "chevron.right.2")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .frame(width: 40, height: 32)
            }
            .buttonStyle(.plain)

            Divider()
                .padding(.vertical, 4)

            // Tab icons
            VStack(spacing: 8) {
                ForEach(SidebarTab.allCases, id: \.self) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        Image(systemName: tab.icon)
                            .font(.body)
                            .frame(width: 40, height: 40)
                            .background(
                                selectedTab == tab
                                    ? Color.accentColor.opacity(0.1)
                                    : Color.clear,
                                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                            )
                            .foregroundStyle(selectedTab == tab ? Color.accentColor : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()
        }
    }

    // MARK: - Expanded Sidebar (flyover)

    private var expandedSidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Close button
            Button {
                sidebarExpanded = false
            } label: {
                Image(systemName: "xmark")
                    .font(.body.bold())
                    .foregroundStyle(.secondary)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
            .padding(.leading, 12)

            Divider()
                .padding(.vertical, 4)

            // Tab items with labels
            VStack(spacing: 2) {
                ForEach(SidebarTab.allCases, id: \.self) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: tab.icon)
                                .font(.body)
                                .frame(width: 24)

                            Text(tab.label)
                                .font(.subheadline)

                            Spacer()

                            if tab == .timeline {
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            selectedTab == tab
                                ? Color.accentColor.opacity(0.1)
                                : Color.clear,
                            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                        )
                        .foregroundStyle(selectedTab == tab ? Color.accentColor : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)

            Spacer()
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        Group {
            switch selectedTab {
            case .timeline:
                timelineMainContent
            case .crewRest:
                crewRestMainContent
            case .weCare:
                weCareMainContent
            case .evidence:
                evidenceMainContent
            case .positions:
                positionsMainContent
            case .flightCrewChecklist:
                flightCrewChecklistMainContent
            }
        }
    }

    // MARK: - Positions Main Content

    private var positionsMainContent: some View {
        SavedPositionsTabView(
            sector: sector,
            flightNumber: trip?.flightNumber ?? sector.flightNumber,
            flightDate: trip?.flightDate ?? sector.date
        )
    }

    // MARK: - Timeline Main Content (50/50 split)

    private var timelineMainContent: some View {
        GeometryReader { geo in
            let available = geo.size.width - 24 - 12 // padding (12*2) + spacing
            let leftWidth = available * 0.5
            let rightWidth = available * 0.5

            HStack(alignment: .top, spacing: 12) {
                AnyView(timelineInputPanel(width: leftWidth))

                AnyView(timelineOutputPanel(width: rightWidth))
            }
            .padding(12)
        }
    }

    // MARK: - Timeline Input Panel

    private func timelineInputPanel(width: CGFloat) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("All times in DXB timezone (GMT+4)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 2)

                    Text("Update with actual time")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.red.opacity(0.8))
                        .frame(maxWidth: .infinity, alignment: .center)

                    adjustableTimeField("Push Back", time: $pushBack, timeZone: Self.dxbTZ)
                    Divider().padding(.horizontal, 16)

                    adjustableTimeField("Take Off Time", time: takeOffTimeManualBinding, timeZone: Self.dxbTZ)
                    Divider().padding(.horizontal, 16)

                    adjustableTimeField("Flight Duration", time: $flightTime, timeZone: Self.durationTZ)

                    Divider().padding(.horizontal, 16)

                    Text("Select your service timing")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.red.opacity(0.8))
                        .frame(maxWidth: .infinity, alignment: .center)
                    Divider().padding(.horizontal, 16)

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Number of services")
                                .font(.body)
                            Spacer()
                            Picker("", selection: $numberOfServices) {
                                Text("1").tag(1)
                                Text("2").tag(2)
                                Text("3").tag(3)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 140)
                        }
                        Divider().padding(.horizontal, 16)

                        serviceTimingTable
                    }
                }
                .padding()
            }

            Spacer(minLength: 0)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Landing Time")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(sector.arrivalStation == "DXB" ? "DXB local" : "DXB time")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.65))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatArrTime(calculatedLandingTime))
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                    if sector.arrivalStation != "DXB" {
                        Text("\(sector.arrivalStation) local: \(formatTime(calculatedLandingTime, in: arrTZ))")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.65))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.85, green: 0.15, blue: 0.15), Color(red: 0.75, green: 0.1, blue: 0.1)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        }
        .onAppear {
            initializeTimeFields()
            saveLandingTime()
            if !showsBriefingSection {
                briefingExpanded = false
                groundDutiesExpanded = true
            }
        }
        .onChange(of: pushBack) {
            if !takeOffManuallyEdited {
                takeOffTime = addMinutes(pushBack, 20)
            }
            saveAllTimes()
        }
        .onChange(of: takeOffTime) { saveAllTimes() }
        .onChange(of: flightTime) { saveAllTimes() }
        .onChange(of: serviceSnapshot) { saveAllTimes() }
        .frame(width: width)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
    }

    // MARK: - Timeline Output Panel

    private func timelineOutputPanel(width: CGFloat) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if showsBriefingSection {
                    timelineCard(
                        title: "Briefing",
                        icon: "person.3",
                        headerColor: Color(red: 0.4, green: 0.55, blue: 0.85),
                        isExpanded: $briefingExpanded
                    ) {
                        switch sectorFlightType {
                        case .dxbDeparture:
                            timelineRow("e-Gate open", time: addMinutes(std, -150), index: 0)
                            timelineRow("e-Gate close", time: addMinutes(std, -100), index: 1)
                            timelineRow("Briefing start", time: addMinutes(std, -90), index: 2)
                            timelineRow("Briefing end", time: addMinutes(std, -80), index: 3)
                            timelineRow("Bus leave EGHQ", time: addMinutes(std, -75), index: 4, showDivider: false)
                        case .layoverReturn:
                            timelineRow("Briefing", time: addMinutes(std, -80), index: 0, showDivider: false)
                        case .turnaroundTransit:
                            EmptyView()
                        }
                    }
                }

                timelineCard(
                    title: "Ground Duties",
                    icon: "airplane.arrival",
                    headerColor: Color(red: 0.2, green: 0.35, blue: 0.65),
                    isExpanded: $groundDutiesExpanded
                ) {
                    switch sectorFlightType {
                    case .dxbDeparture:
                        editableTimelineRow("Arrive to aircraft", calculated: addMinutes(std, -60), actual: $actualArriveAircraft, index: 0)
                        editableTimelineRow("Cabin appearance check", calculated: addMinutes(std, -55), actual: $actualCabinAppearance, index: 1)
                        editableTimelineRow("Pre-flight safety checks", calculated: addMinutes(std, -50), actual: $actualSafetyChecks, index: 2)
                        editableTimelineRow("Auto Boarding", calculated: addMinutes(std, -45), actual: $actualAutoBoarding, index: 3)
                        editableTimelineRow("Offloading No-Show pax", calculated: addMinutes(std, -15), actual: $actualOffloadNoShow, index: 4)
                        editableTimelineRow("Closing last door", calculated: addMinutes(std, -5), actual: $actualClosingDoor, index: 5)
                        editableTimelineRow("Arming door", calculated: addMinutes(std, -3), actual: $actualArmingDoor, index: 6, showDivider: false)
                    case .turnaroundTransit, .layoverReturn:
                        editableTimelineRow("Arrive to aircraft", calculated: addMinutes(std, -65), actual: $actualArriveAircraft, index: 0)
                        editableTimelineRow("Appearance check", calculated: addMinutes(std, -60), actual: $actualCabinAppearance, index: 1)
                        editableTimelineRow("Safety and security search", calculated: addMinutes(std, -55), actual: $actualSafetyChecks, index: 2)
                        editableTimelineRow("Auto Boarding", calculated: addMinutes(std, -40), actual: $actualAutoBoarding, index: 3)
                        editableTimelineRow("Offload last minute pax", calculated: addMinutes(std, -10), actual: $actualOffloadNoShow, index: 4)
                        editableTimelineRow("Closing last door", calculated: addMinutes(std, -5), actual: $actualClosingDoor, index: 5)
                        editableTimelineRow("Arming doors", calculated: addMinutes(std, -3), actual: $actualArmingDoor, index: 6, showDivider: false)
                    }
                }

                timelineCard(
                    title: "Inflight",
                    icon: "airplane",
                    headerColor: Color(red: 0.05, green: 0.15, blue: 0.45),
                    isExpanded: $inflightExpanded
                ) {
                    var rowIndex = 0

                    if isLongHaul {
                        timelineRangeRow("Settling in duties", start: settlingInStart, end: settlingInEnd, index: rowIndex)
                        let _ = rowIndex += 1
                    }

                    if numberOfServices == 1 {
                        inflightServiceRow("Service time", start: serviceStartTime, jcEnd: addMinutes(serviceStartTime, service1JC), wcEnd: addMinutes(serviceStartTime, service1WC), ycEnd: addMinutes(serviceStartTime, service1YC), index: rowIndex)
                        let _ = rowIndex += 1
                    } else if numberOfServices == 2 {
                        let firstJCEnd = addMinutes(serviceStartTime, service1JC)
                        let firstWCEnd = addMinutes(serviceStartTime, service1WC)
                        let firstYCEnd = addMinutes(serviceStartTime, service1YC)
                        inflightServiceRow("First Service", start: serviceStartTime, jcEnd: firstJCEnd, wcEnd: firstWCEnd, ycEnd: firstYCEnd, index: rowIndex)
                        let _ = rowIndex += 1

                        let lastStart = addMinutes(twentyToTop, -max(service2JC, service2WC, service2YC))
                        let firstEndDate = Date(timeIntervalSince1970: max(firstJCEnd.timeIntervalSince1970, firstWCEnd.timeIntervalSince1970, firstYCEnd.timeIntervalSince1970))
                        let gapMinutes = Int(lastStart.timeIntervalSince(firstEndDate)) / 60
                        availableTimeRow(minutes: gapMinutes, index: rowIndex)
                        let _ = rowIndex += 1

                        inflightServiceRow("Last Service", start: lastStart, jcEnd: addMinutes(lastStart, service2JC), wcEnd: addMinutes(lastStart, service2WC), ycEnd: addMinutes(lastStart, service2YC), index: rowIndex)
                        let _ = rowIndex += 1
                    } else if numberOfServices == 3 {
                        let firstJCEnd = addMinutes(serviceStartTime, service1JC)
                        let firstWCEnd = addMinutes(serviceStartTime, service1WC)
                        let firstYCEnd = addMinutes(serviceStartTime, service1YC)
                        inflightServiceRow("First Service", start: serviceStartTime, jcEnd: firstJCEnd, wcEnd: firstWCEnd, ycEnd: firstYCEnd, index: rowIndex)
                        let _ = rowIndex += 1

                        let lastStart = addMinutes(twentyToTop, -max(service3JC, service3WC, service3YC))
                        let firstEndDate = Date(timeIntervalSince1970: max(firstJCEnd.timeIntervalSince1970, firstWCEnd.timeIntervalSince1970, firstYCEnd.timeIntervalSince1970))
                        let middleGap = lastStart.timeIntervalSince1970 - firstEndDate.timeIntervalSince1970
                        let middleStart = Date(timeIntervalSince1970: firstEndDate.timeIntervalSince1970 + (middleGap - Double(max(service2JC, service2WC, service2YC)) * 60) / 2)
                        let middleJCEnd = addMinutes(middleStart, service2JC)
                        let middleWCEnd = addMinutes(middleStart, service2WC)
                        let middleYCEnd = addMinutes(middleStart, service2YC)

                        let gap1Minutes = Int(middleStart.timeIntervalSince(firstEndDate)) / 60
                        availableTimeRow(minutes: gap1Minutes, index: rowIndex)
                        let _ = rowIndex += 1

                        inflightServiceRow("Middle Service", start: middleStart, jcEnd: middleJCEnd, wcEnd: middleWCEnd, ycEnd: middleYCEnd, index: rowIndex)
                        let _ = rowIndex += 1

                        let middleEndDate = Date(timeIntervalSince1970: max(middleJCEnd.timeIntervalSince1970, middleWCEnd.timeIntervalSince1970, middleYCEnd.timeIntervalSince1970))
                        let gap2Minutes = Int(lastStart.timeIntervalSince(middleEndDate)) / 60
                        availableTimeRow(minutes: gap2Minutes, index: rowIndex)
                        let _ = rowIndex += 1

                        inflightServiceRow("Last Service", start: lastStart, jcEnd: addMinutes(lastStart, service3JC), wcEnd: addMinutes(lastStart, service3WC), ycEnd: addMinutes(lastStart, service3YC), index: rowIndex)
                        let _ = rowIndex += 1
                    }

                    timelineRow("20 to top", time: twentyToTop, index: rowIndex, color: .red)
                    let _ = rowIndex += 1
                    timelineRow("Top of descent", time: topOfDescent, index: rowIndex, color: .red)
                    let _ = rowIndex += 1
                    timelineRow("Cabin secure", time: cabinSecure, index: rowIndex, showDivider: false)
                }

                timelineCard(
                    title: "After Landing",
                    icon: "airplane.arrival",
                    headerColor: Color(red: 0.45, green: 0.3, blue: 0.15),
                    isExpanded: $afterLandingExpanded
                ) {
                    timelineRow("Disarming doors", time: calculatedLandingTime, index: 0)
                    timelineRow("Opening doors", time: addMinutes(calculatedLandingTime, 3), index: 1)
                    timelineRow("Deboarding", time: addMinutes(calculatedLandingTime, 5), index: 2)
                    timelineRow("Cabin check", time: addMinutes(calculatedLandingTime, 20), index: 3)
                    timelineRow("Crew debrief", time: addMinutes(calculatedLandingTime, 30), index: 4, showDivider: false)
                }
            }
        }
        .frame(width: width)
        .onChange(of: briefingExpanded) {
            if briefingExpanded && !openAllCards {
                groundDutiesExpanded = false
                inflightExpanded = false
                afterLandingExpanded = false
            }
        }
        .onChange(of: groundDutiesExpanded) {
            if groundDutiesExpanded && !openAllCards {
                briefingExpanded = false
                inflightExpanded = false
                afterLandingExpanded = false
            }
        }
        .onChange(of: inflightExpanded) {
            if inflightExpanded && !openAllCards {
                briefingExpanded = false
                groundDutiesExpanded = false
                afterLandingExpanded = false
            }
        }
        .onChange(of: afterLandingExpanded) {
            if afterLandingExpanded && !openAllCards {
                briefingExpanded = false
                groundDutiesExpanded = false
                inflightExpanded = false
            }
        }
    }

    // MARK: - Crew Rest Main Content

    private var crewRestMainContent: some View {
        VStack(spacing: 0) {
            if showCrewRestResults {
                HStack {
                    Button {
                        showCrewRestResults = false
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Edit inputs")
                                .font(.subheadline.weight(.medium))
                        }
                    }
                    Spacer()
                    if let result = crewRestState.result {
                        Menu {
                            Button {
                                SchedulePrinter.print(
                                    c: result,
                                    breakGroups: sectorBreakGroups,
                                    sectorLabel: "\(sector.departureStation) - \(sector.arrivalStation)",
                                    layout: .onePerSheet
                                )
                            } label: {
                                Label("1 per sheet", systemImage: "doc")
                            }
                            Button {
                                SchedulePrinter.print(
                                    c: result,
                                    breakGroups: sectorBreakGroups,
                                    sectorLabel: "\(sector.departureStation) - \(sector.arrivalStation)",
                                    layout: .twoPerSheet
                                )
                            } label: {
                                Label("2 per sheet", systemImage: "doc.on.doc")
                            }
                        } label: {
                            Label("Print", systemImage: "printer")
                                .font(.subheadline.weight(.medium))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.systemGroupedBackground))
                .overlay(alignment: .bottom) { Divider() }

                CrewRestResultsView(embedded: true, breakGroups: sectorBreakGroups)
                    .environment(crewRestState)
            } else {
                CrewRestInputView(onCalculate: {
                    saveCrewRestState()
                    crewRestState.result = Calculator.calc(crewRestState)
                    showCrewRestResults = true
                })
                .environment(crewRestState)
            }
        }
        .onAppear {
            initializeCrewRestState()
        }
    }

    private func initializeCrewRestState() {
        guard !crewRestInitialized else { return }
        crewRestInitialized = true

        let toSource = sector.savedTakeOffTime ?? sector.departureTime
        let toParts = toSource.split(separator: ":").compactMap { Int($0) }
        if toParts.count == 2 {
            crewRestState.takeoffMin = toParts[0] * 60 + toParts[1]
        }

        let fltSource = sector.savedFlightTime ?? ""
        let fltParts = fltSource.split(separator: ":").compactMap { Int($0) }
        if fltParts.count == 2 {
            crewRestState.flightMin = fltParts[0] * 60 + fltParts[1]
        }

        if let savedReg = sector.savedCrewRestRegistration {
            crewRestState.registration = savedReg
            crewRestState.aircraft = sector.savedCrewRestAircraft ?? "B777"
            if let facStr = sector.savedCrewRestFacility, let fac = Facility(rawValue: facStr) {
                crewRestState.facility = fac
            }
            if let fc = sector.savedCrewRestHasFC {
                crewRestState.hasFC = fc
            }
        } else if let reg = sector.registration, reg.count >= 3 {
            crewRestState.registration = String(reg.suffix(3))
            if let fleet = crewRestState.matchedFleet {
                crewRestState.aircraft = fleet.type
                if let best = fleet.facilityOptions.first {
                    crewRestState.facility = best
                }
                crewRestState.hasFC = crewRestState.fcAvailable
            }
        }

        if let settling = sector.savedCrewRestSettlingMin {
            crewRestState.settlingMin = settling
        }

        if let n = sector.savedNumberOfServices {
            crewRestState.numServices = n
        }
        let s1 = max(sector.savedService1JC ?? 0, sector.savedService1YC ?? 0)
        let s2 = max(sector.savedService2JC ?? 0, sector.savedService2YC ?? 0)
        let s3 = max(sector.savedService3JC ?? 0, sector.savedService3YC ?? 0)
        crewRestState.services = [s1, s2, s3]
    }

    private func saveCrewRestState() {
        sector.savedCrewRestRegistration = crewRestState.registration
        sector.savedCrewRestAircraft = crewRestState.aircraft
        sector.savedCrewRestFacility = crewRestState.facility.rawValue
        sector.savedCrewRestHasFC = crewRestState.hasFC
        sector.savedCrewRestSettlingMin = crewRestState.settlingMin
        sector.savedNumberOfServices = crewRestState.numServices
        let svcs = crewRestState.services
        sector.savedService1JC = svcs.count > 0 ? svcs[0] : 0
        sector.savedService2JC = svcs.count > 1 ? svcs[1] : 0
        sector.savedService3JC = svcs.count > 2 ? svcs[2] : 0
        sector.savedService1YC = sector.savedService1JC
        sector.savedService2YC = sector.savedService2JC
        sector.savedService3YC = sector.savedService3JC
    }

    // MARK: - We Care Main Content

    private var weCareMainContent: some View {
        WeCareInputView(
            sector: sector,
            timelineTakeoffMinute: minuteOfDay(takeOffTime),
            timelineLandingMinute: minuteOfDay(calculatedLandingTime)
        )
    }

    /// Minutes from midnight (Dubai) for a timeline date, carried into We Care.
    private func minuteOfDay(_ date: Date) -> Int {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
    }

    // MARK: - Sector Break Groups

    private var sectorBreakGroups: [BreakGroupEntry] {
        guard let data = sector.crewPositionsJSON,
              let positions = try? JSONDecoder().decode([SectorCrewPosition].self, from: data) else {
            return []
        }
        struct MemberInfo {
            let nickname: String
            let grade: String
        }
        var grouped: [Int: [MemberInfo]] = [:]
        for crew in positions {
            guard crew.breakGroup > 0 else { continue }
            grouped[crew.breakGroup, default: []].append(MemberInfo(nickname: crew.nickname, grade: crew.grade))
        }
        return grouped
            .sorted { $0.key < $1.key }
            .map { entry in
                let members = entry.value
                let seniors = members.filter { ["PUR", "CSV"].contains($0.grade) }.map(\.nickname).joined(separator: ", ")
                let fg1 = members.filter { $0.grade == "FG1" }.map(\.nickname).joined(separator: ", ")
                let gr1 = members.filter { ["GR1", "W"].contains($0.grade) }.map(\.nickname).joined(separator: ", ")
                let gr2 = members.filter { ["GR2", "CSA"].contains($0.grade) }.map(\.nickname).joined(separator: ", ")
                return BreakGroupEntry(breakNumber: entry.key, count: members.count, seniors: seniors, fg1: fg1, gr1: gr1, gr2: gr2)
            }
    }

    // MARK: - Evidence Main Content

    private var evidenceMainContent: some View {
        SectorEvidenceView(sector: sector)
    }

    // MARK: - Flight Crew Checklist Main Content

    private var flightCrewChecklistMainContent: some View {
        FlightCrewChecklistView(
            initialTakeoff: takeOffTime,
            initialDurationMinutes: flightDurationMinutes,
            sector: sector
        )
    }

    private var flightDurationMinutes: Int {
        var cal = Calendar.current
        cal.timeZone = Self.durationTZ
        let start = cal.startOfDay(for: flightTime)
        return Int(flightTime.timeIntervalSince(start)) / 60
    }

    // MARK: - Initialize Time Fields

    private func initializeTimeFields() {
        std = timeFromString(sector.departureTime, in: depTZ)
        sta = timeFromString(sector.arrivalTime, in: arrTZ)

        // Block time: STA(arrival local) - STD(departure local), both converted to absolute Dates
        let interval = sta.timeIntervalSince(std)
        let adjustedInterval = interval >= 0 ? interval : interval + 86400
        let blockHours = Int(adjustedInterval) / 3600
        let blockMinutes = (Int(adjustedInterval) % 3600) / 60
        var dCal = Calendar.current
        dCal.timeZone = Self.durationTZ
        let base = dCal.startOfDay(for: Date())
        scheduledBlockTime = dCal.date(bySettingHour: blockHours, minute: blockMinutes, second: 0, of: base) ?? base

        // Load saved or use defaults (push back / take off saved in DXB time, flight time is a duration)
        pushBack = sector.savedPushBack.map { timeFromString($0, in: Self.dxbTZ) } ?? std
        takeOffTime = sector.savedTakeOffTime.map { timeFromString($0, in: Self.dxbTZ) } ?? addMinutes(pushBack, 20)
        flightTime = sector.savedFlightTime.map { timeFromString($0, in: Self.durationTZ) } ?? addMinutes(scheduledBlockTime, -30)

        if sector.savedTakeOffTime != nil {
            let autoTakeOff = addMinutes(pushBack, 20)
            takeOffManuallyEdited = formatDepTime(takeOffTime) != formatDepTime(autoTakeOff)
        }

        numberOfServices = sector.savedNumberOfServices ?? 1
        service1JC = sector.savedService1JC ?? 0
        service1WC = sector.savedService1WC ?? 0
        service1YC = sector.savedService1YC ?? 0
        service2JC = sector.savedService2JC ?? 0
        service2WC = sector.savedService2WC ?? 0
        service2YC = sector.savedService2YC ?? 0
        service3JC = sector.savedService3JC ?? 0
        service3WC = sector.savedService3WC ?? 0
        service3YC = sector.savedService3YC ?? 0

        // Load saved actual times (ground duties saved in DXB time)
        actualArriveAircraft = sector.savedActualArriveAircraft.map { timeFromString($0, in: Self.dxbTZ) }
        actualCabinAppearance = sector.savedActualCabinAppearance.map { timeFromString($0, in: Self.dxbTZ) }
        actualSafetyChecks = sector.savedActualSafetyChecks.map { timeFromString($0, in: Self.dxbTZ) }
        actualAutoBoarding = sector.savedActualAutoBoarding.map { timeFromString($0, in: Self.dxbTZ) }
        actualOffloadNoShow = sector.savedActualOffloadNoShow.map { timeFromString($0, in: Self.dxbTZ) }
        actualClosingDoor = sector.savedActualClosingDoor.map { timeFromString($0, in: Self.dxbTZ) }
        actualArmingDoor = sector.savedActualArmingDoor.map { timeFromString($0, in: Self.dxbTZ) }
    }

    private func saveAllTimes() {
        sector.savedPushBack = formatDepTime(pushBack)
        sector.savedTakeOffTime = formatDepTime(takeOffTime)
        sector.savedFlightTime = formatDurationTime(flightTime)
        sector.savedNumberOfServices = numberOfServices
        sector.savedService1JC = service1JC
        sector.savedService1WC = service1WC
        sector.savedService1YC = service1YC
        sector.savedService2JC = service2JC
        sector.savedService2WC = service2WC
        sector.savedService2YC = service2YC
        sector.savedService3JC = service3JC
        sector.savedService3WC = service3WC
        sector.savedService3YC = service3YC

        sector.savedActualArriveAircraft = actualArriveAircraft.map { formatDepTime($0) }
        sector.savedActualCabinAppearance = actualCabinAppearance.map { formatDepTime($0) }
        sector.savedActualSafetyChecks = actualSafetyChecks.map { formatDepTime($0) }
        sector.savedActualAutoBoarding = actualAutoBoarding.map { formatDepTime($0) }
        sector.savedActualOffloadNoShow = actualOffloadNoShow.map { formatDepTime($0) }
        sector.savedActualClosingDoor = actualClosingDoor.map { formatDepTime($0) }
        sector.savedActualArmingDoor = actualArmingDoor.map { formatDepTime($0) }

        sector.actualLandingTime = formatArrTime(calculatedLandingTime)
    }

    private func saveLandingTime() {
        sector.actualLandingTime = formatArrTime(calculatedLandingTime)
    }

    // MARK: - Adjustable Time Field

    @ViewBuilder
    private func adjustableTimeField(_ label: String, time: Binding<Date>, timeZone: TimeZone) -> some View {
        HStack {
            Text(label)
                .font(.body)

            Spacer()

            HStack(spacing: 10) {
                Button {
                    time.wrappedValue = addMinutes(time.wrappedValue, -1)
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(.red, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)

                DatePicker("", selection: time, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .scaleEffect(1.15)
                    .environment(\.locale, Locale(identifier: "en_GB"))
                    .environment(\.timeZone, timeZone)

                Button {
                    time.wrappedValue = addMinutes(time.wrappedValue, 1)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(Color(red: 0.0, green: 0.5, blue: 0.0), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Read-Only Time Field

    @ViewBuilder
    private func readOnlyTimeField(_ label: String, time: Date, timeZone: TimeZone) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()
            Text(formatTime(time, in: timeZone))
                .font(.subheadline.monospaced())
        }
    }

    // MARK: - Inflight Service Row

    @ViewBuilder
    private func inflightServiceRow(_ label: String, start: Date, jcEnd: Date, wcEnd: Date? = nil, ycEnd: Date, index: Int = 0, showDivider: Bool = true) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .regular))
            Spacer()
            inflightCabinBadge("JC", start: start, end: jcEnd, color: .blue)

            if let wcEnd, hasWCCabin {
                Spacer().frame(width: 6)
                inflightCabinBadge("WC", start: start, end: wcEnd, color: .purple)
            }

            Spacer().frame(width: 6)
            inflightCabinBadge("YC", start: start, end: ycEnd, color: Color(red: 0.0, green: 0.5, blue: 0.0))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 7)
        .modifier(RowSelect(rowID: label, selectedRowID: $selectedRowID))
        if showDivider {
            Divider().opacity(0.4).padding(.horizontal, 20)
        }
    }

    @ViewBuilder
    private func inflightCabinBadge(_ cabin: String, start: Date, end: Date, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(cabin)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(color)
            Text(formatDepTime(start) + " \u{2013} " + formatDepTime(end))
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(color)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(color.opacity(0.06), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Service Timing Table

    private let tableBorder = Color(.separator)

    private static let jcBackground = Color.blue.opacity(0.08)
    private static let wcBackground = Color.purple.opacity(0.08)
    private static let ycBackground = Color.green.opacity(0.08)

    private var serviceTimingTable: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 0) {
                Text("")
                    .frame(width: 60)
                tableBorder.frame(width: 0.5)
                Text("JC")
                    .font(.subheadline.bold())
                    .foregroundStyle(.blue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 32)
                    .background(Self.jcBackground)
                if hasWCCabin {
                    tableBorder.frame(width: 0.5)
                    Text("WC")
                        .font(.subheadline.bold())
                        .foregroundStyle(.purple)
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background(Self.wcBackground)
                }
                tableBorder.frame(width: 0.5)
                Text("YC")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color(red: 0.0, green: 0.5, blue: 0.0))
                    .frame(maxWidth: .infinity)
                    .frame(height: 32)
                    .background(Self.ycBackground)
            }
            .frame(height: 32)
            .background(Color(.tertiarySystemGroupedBackground))

            tableBorder.frame(height: 0.5)

            // Rows
            if numberOfServices == 1 {
                serviceTableRow("Service", jc: $service1JC, wc: $service1WC, yc: $service1YC)
            } else {
                serviceTableRow("First", jc: $service1JC, wc: $service1WC, yc: $service1YC)
                tableBorder.frame(height: 0.5)

                if numberOfServices == 3 {
                    serviceTableRow("Middle", jc: $service2JC, wc: $service2WC, yc: $service2YC)
                    tableBorder.frame(height: 0.5)
                    serviceTableRow("Last", jc: $service3JC, wc: $service3WC, yc: $service3YC)
                } else {
                    serviceTableRow("Last", jc: $service2JC, wc: $service2WC, yc: $service2YC)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(tableBorder, lineWidth: 0.5)
        )
    }

    @ViewBuilder
    private func serviceTableRow(_ label: String, jc: Binding<Int>, wc: Binding<Int>, yc: Binding<Int>) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .font(.subheadline)
                .frame(width: 60)
            tableBorder.frame(width: 0.5)
            serviceDurationCell(value: jc, color: .blue)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Self.jcBackground)
            if hasWCCabin {
                tableBorder.frame(width: 0.5)
                serviceDurationCell(value: wc, color: .purple)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Self.wcBackground)
            }
            tableBorder.frame(width: 0.5)
            serviceDurationCell(value: yc, color: Color(red: 0.0, green: 0.5, blue: 0.0))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Self.ycBackground)
        }
        .frame(height: 44)
    }

    @ViewBuilder
    private func serviceDurationCell(value: Binding<Int>, color: Color) -> some View {
        Picker("", selection: value) {
            ForEach(Self.serviceDurations, id: \.self) { minutes in
                Text(formatDuration(minutes))
                    .tag(minutes)
            }
        }
        .labelsHidden()
        .tint(color)
    }

    // MARK: - Timeline Card

    @ViewBuilder
    private func timelineCard<Content: View>(
        title: String,
        icon: String,
        headerColor: Color,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(headerColor)
                    .frame(width: 24)

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Spacer()

                Toggle("", isOn: isExpanded)
                    .labelsHidden()
                    .tint(headerColor.opacity(0.7))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(headerColor.opacity(0.06))

            if isExpanded.wrappedValue {
                Divider().padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 0) {
                    content()
                }
                .padding(.vertical, 6)
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color(.separator).opacity(0.2), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    // MARK: - Available Time Row

    @ViewBuilder
    private func availableTimeRow(minutes: Int, index: Int = 0, showDivider: Bool = true) -> some View {
        HStack {
            Text("Available time")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.secondary)
            Spacer()
            Text(String(format: "%dh %02dm", minutes / 60, minutes % 60))
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 5)
        .background(Color(.systemGray6).opacity(0.5))
        .modifier(RowSelect(rowID: "available-\(index)", selectedRowID: $selectedRowID))
        if showDivider {
            Divider().opacity(0.4).padding(.horizontal, 20)
        }
    }

    // MARK: - Timeline Range Row

    @ViewBuilder
    private func timelineRangeRow(_ label: String, start: Date, end: Date, index: Int = 0, showDivider: Bool = true) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .regular))
            Spacer()
            Text(formatDepTime(start) + "  \u{2013}  " + formatDepTime(end))
                .font(.system(size: 13, weight: .medium, design: .monospaced))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 7)
        .modifier(RowSelect(rowID: label, selectedRowID: $selectedRowID))
        if showDivider {
            Divider().opacity(0.4).padding(.horizontal, 20)
        }
    }

    // MARK: - Timeline Row

    @ViewBuilder
    private func timelineRow(_ label: String, time: Date?, index: Int = 0, showDivider: Bool = true, color: Color? = nil) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(color ?? .primary)
            Spacer()
            if let time {
                Text(formatDepTime(time))
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(color ?? Color(.label))
            } else {
                Text("--:--")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 7)
        .modifier(RowSelect(rowID: label, selectedRowID: $selectedRowID))
        if showDivider {
            Divider().opacity(0.4).padding(.horizontal, 20)
        }
    }

    // MARK: - Editable Timeline Row

    @ViewBuilder
    private func editableTimelineRow(_ label: String, calculated: Date, actual: Binding<Date?>, index: Int = 0, showDivider: Bool = true) -> some View {
        HStack {
            HStack(spacing: 4) {
                Text(label)
                    .font(.system(size: 13, weight: .regular))
                if let time = actual.wrappedValue {
                    let diffMin = Int(time.timeIntervalSince(calculated)) / 60
                    if diffMin != 0 {
                        Text("(\(diffMin > 0 ? "+" : "")\(diffMin)m)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(diffMin > 0 ? .red : Color(red: 0.0, green: 0.5, blue: 0.0))
                    }
                }
            }

            Spacer()

            Text(formatDepTime(calculated))
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(Color(.label))
                .padding(.trailing, 10)

            HStack(spacing: 5) {
                Button {
                    let base = actual.wrappedValue ?? calculated
                    let newTime = addMinutes(base, -1)
                    actual.wrappedValue = formatDepTime(newTime) == formatDepTime(calculated) ? nil : newTime
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(Color(red: 0.0, green: 0.5, blue: 0.0), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .buttonStyle(.plain)

                if let time = actual.wrappedValue {
                    let diff = time.timeIntervalSince(calculated)
                    Text(formatDepTime(time))
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(diff > 0 ? .red : diff < 0 ? Color(red: 0.0, green: 0.5, blue: 0.0) : .primary)
                } else {
                    Text("--:--")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(.tertiary)
                }

                Button {
                    let base = actual.wrappedValue ?? calculated
                    let newTime = addMinutes(base, 1)
                    actual.wrappedValue = formatDepTime(newTime) == formatDepTime(calculated) ? nil : newTime
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(.red, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 7)
        .modifier(RowSelect(rowID: label, selectedRowID: $selectedRowID))
        if showDivider {
            Divider().opacity(0.4).padding(.horizontal, 20)
        }
    }

    // MARK: - Sidebar Helpers

    @ViewBuilder
    private func sidebarRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
        }
    }
}

// MARK: - Sidebar Tab

enum SidebarTab: String, CaseIterable {
    case timeline
    case crewRest
    case weCare
    case evidence
    case positions
    case flightCrewChecklist

    var label: String {
        switch self {
        case .timeline: "Timeline"
        case .crewRest: "EK Crew Rest"
        case .weCare: "We Care"
        case .evidence: "Evidence"
        case .positions: "Positions"
        case .flightCrewChecklist: "Flight Crew"
        }
    }

    var icon: String {
        switch self {
        case .timeline: "clock.arrow.circlepath"
        case .crewRest: "bed.double"
        case .weCare: "heart.circle"
        case .evidence: "camera.viewfinder"
        case .positions: "person.2"
        case .flightCrewChecklist: "person.bust"
        }
    }
}
// MARK: - Service Snapshot

private struct ServiceSnapshot: Equatable {
    let numberOfServices: Int
    let s1jc: Int, s1wc: Int, s1yc: Int
    let s2jc: Int, s2wc: Int, s2yc: Int
    let s3jc: Int, s3wc: Int, s3yc: Int
    let a1: Date?, a2: Date?, a3: Date?, a4: Date?
    let a5: Date?, a6: Date?, a7: Date?
}

// MARK: - Row Select Modifier

private struct RowSelect: ViewModifier {
    let rowID: String
    @Binding var selectedRowID: String?

    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(selectedRowID == rowID ? Color.accentColor.opacity(0.12) : Color.clear)
            )
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.15)) {
                    selectedRowID = selectedRowID == rowID ? nil : rowID
                }
            }
    }
}

