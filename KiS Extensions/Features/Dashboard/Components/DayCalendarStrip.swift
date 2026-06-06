import SwiftUI
import SwiftData

// MARK: - Day Calendar Strip

/// Active calendar strip. A centered month label tracks the centred day in the
/// horizontal scroll. Tapping a day selects it and scrolls it to centre. A
/// "Today" button appears when the selection moves off the current day. Below
/// each day, trip bars stretch under the cells to visually convey the duration
/// of trips away from base. Tapping a trip bar opens a sectors popup.
struct DayCalendarStrip: View {

    /// Invoked when the crew picks a sector from the trip popup.
    var onOpenSector: (PlannedSector) -> Void = { _ in }
    /// Invoked when the crew taps the "Edit Trip" action in the trip popup.
    var onEditTrip: (PlannedFlight) -> Void = { _ in }

    @Query private var sectors: [PlannedSector]
    @Query private var savedTrips: [SavedTrip]
    @Query private var plannedFlights: [PlannedFlight]
    @Query private var duties: [PlannedDuty]

    @State private var visibleDayCount: Int = 7
    @State private var selectedDay: Date = Calendar.current.startOfDay(for: Date())
    @State private var centeredDay: Date?
    @State private var popupContext: FlightPopupContext?

    private let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = .dubai
        return c
    }()

    private var today: Date { calendar.startOfDay(for: Date()) }

    // MARK: - Body

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            header
            GeometryReader { proxy in
                let cellWidth = proxy.size.width / CGFloat(visibleDayCount)
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 0) {
                        ForEach(days, id: \.self) { day in
                            dayCell(day, width: cellWidth)
                                .id(day)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollPosition(id: $centeredDay, anchor: .center)
                .onAppear {
                    updateVisibleCount(for: proxy.size.width)
                    DispatchQueue.main.async {
                        if centeredDay == nil { centeredDay = today }
                    }
                }
                .onChange(of: proxy.size.width) { _, newWidth in
                    updateVisibleCount(for: newWidth)
                }
            }
            .frame(height: 82)
        }
        .sheet(item: $popupContext) { ctx in
            TripSectorsSheet(
                flight: ctx.flight,
                onSelect: { sector in
                    popupContext = nil
                    onOpenSector(sector)
                },
                onEditTrip: {
                    let flight = ctx.flight
                    popupContext = nil
                    onEditTrip(flight)
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Header

    private var header: some View {
        ZStack {
            Text(centeredMonthLabel)
                .font(.system(size: 13, weight: .semibold))
                .tracking(0.4)
                .foregroundStyle(AppColor.textPrimary)
                .animation(.snappy(duration: 0.15), value: centeredMonthLabel)

            HStack {
                Spacer()
                if !calendar.isDate(selectedDay, inSameDayAs: today) {
                    Button {
                        selectToday()
                    } label: {
                        Text("Today")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(AppColor.todayAccent))
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.snappy(duration: 0.2), value: selectedDay)
        }
    }

    // MARK: - Day Cell

    @ViewBuilder
    private func dayCell(_ day: Date, width: CGFloat) -> some View {
        let isToday = calendar.isDate(day, inSameDayAs: today)
        let isSelected = calendar.isDate(day, inSameDayAs: selectedDay)
        let weekdayLabel = isToday ? "Today" : Self.weekdayFormatter.string(from: day)
        let dayNumber = calendar.component(.day, from: day)
        let segment = tripSegment(for: day)
        let isTripStart = segment?.position == .start || segment?.position == .single
        let duty = segment == nil ? duty(for: day) : nil

        VStack(spacing: 4) {
            VStack(spacing: 4) {
                Text(weekdayLabel)
                    .font(.system(size: 11, weight: (isToday || isSelected) ? .semibold : .regular))
                    .foregroundStyle(isToday ? AppColor.todayAccent : AppColor.textTertiary)

                ZStack {
                    if isSelected {
                        Circle()
                            .fill(AppColor.todayAccent)
                            .frame(width: 32, height: 32)
                    } else if isToday {
                        Circle()
                            .stroke(AppColor.todayAccent, lineWidth: 1.5)
                            .frame(width: 32, height: 32)
                    }
                    Text("\(dayNumber)")
                        .font(.system(size: 15, weight: isSelected ? .bold : .medium, design: .rounded))
                        .foregroundStyle(isSelected ? .white :
                                         (isToday ? AppColor.todayAccent : AppColor.textPrimary))
                }
                .frame(height: 32)
            }
            .contentShape(Rectangle())
            .onTapGesture { selectDay(day) }

            if segment != nil {
                tripBar(segment, day: day, width: width)
                    .frame(height: 26)
            } else if let duty {
                DutyChipView(duty: duty)
                    .frame(height: 26)
            } else {
                Color.clear.frame(height: 26)
            }
        }
        .frame(width: width)
        // Lift trip-start cells so their overflowing label renders above
        // adjacent cells covering the rest of the trip's capsule.
        .zIndex(isTripStart ? 1 : 0)
    }

    /// First duty for the given calendar day (if any). Day Off → other types
    /// are prioritised since a duty day with a standby is more relevant
    /// operationally than a generic XX.
    private func duty(for day: Date) -> PlannedDuty? {
        let candidates = duties.filter { calendar.isDate($0.date, inSameDayAs: day) }
        guard !candidates.isEmpty else { return nil }
        if let nonOff = candidates.first(where: { $0.category != .dayOff }) {
            return nonOff
        }
        return candidates.first
    }

    // MARK: - Trip Bar

    @ViewBuilder
    private func tripBar(_ segment: TripSegment?, day: Date, width: CGFloat) -> some View {
        if let segment {
            let (startFrac, endFrac) = timeFractions(for: segment.span, day: day)
            let rawWidth = width * (endFrac - startFrac)
            let isSingle = segment.position == .single
            let isFirstDay = segment.position == .start || isSingle
            // Minimum card width so a 4-digit flight number stays readable on
            // short trips; multi-day trips overflow the label onto the next day.
            let minCardWidth: CGFloat = 42
            let barWidth = max(rawWidth, isSingle ? minCardWidth : 4)
            // Position by start time, but keep a widened single-day card inside
            // its cell so the whole number stays visible.
            let leadingOffset = isSingle
                ? min(width * startFrac, max(width - barWidth, 0))
                : width * startFrac
            let fullCapsuleWidth = max(visualCapsuleWidth(for: segment.span, cellWidth: width),
                                       isFirstDay ? minCardWidth : 8)

            HStack(spacing: 0) {
                Color.clear.frame(width: leadingOffset, height: 22)
                Button {
                    handleBarTap(segment)
                } label: {
                    ZStack(alignment: .leading) {
                        segment.shape
                            .fill(segment.span.color)
                            .frame(width: barWidth, height: 22)

                        if isFirstDay, let labelText = barLabelText(segment.span) {
                            Text(labelText)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(Self.chipTextColor)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                                .padding(.horizontal, 4)
                                .frame(width: fullCapsuleWidth, height: 22, alignment: .center)
                                .allowsHitTesting(false)
                        }
                    }
                    .frame(width: barWidth, height: 22, alignment: .leading)
                }
                .buttonStyle(.plain)
                Spacer(minLength: 0)
            }
            .frame(width: width)
            // Match the duty chip's vertical placement so trip and duty pills
            // share the same size and baseline.
            .padding(.top, 4)
        } else {
            Color.clear
        }
    }

    /// Flight number when present, otherwise destination — never empty.
    private func barLabelText(_ span: TripSpan) -> String? {
        if let number = span.flightNumber, !number.isEmpty { return number }
        if !span.destination.isEmpty { return span.destination }
        return nil
    }

    /// Full visual width of the trip's capsule across all cells it spans.
    private func visualCapsuleWidth(for span: TripSpan, cellWidth: CGFloat) -> CGFloat {
        let durationSec = span.absoluteEnd.timeIntervalSince(span.absoluteStart)
        return max(CGFloat(durationSec / 86_400) * cellWidth, 8)
    }

    /// Fraction of `day` (0..1) the trip occupies, in device local time.
    private func timeFractions(for span: TripSpan, day: Date) -> (Double, Double) {
        let dayStart = calendar.startOfDay(for: day)
        let dayEnd = dayStart.addingTimeInterval(86_400)
        let overlapStart = max(span.absoluteStart, dayStart)
        let overlapEnd = min(span.absoluteEnd, dayEnd)
        guard overlapEnd > overlapStart else { return (0, 0) }
        let startFrac = overlapStart.timeIntervalSince(dayStart) / 86_400
        let endFrac = overlapEnd.timeIntervalSince(dayStart) / 86_400
        return (max(0, min(1, startFrac)), max(0, min(1, endFrac)))
    }

    // MARK: - Actions

    private func selectDay(_ day: Date) {
        withAnimation(.snappy(duration: 0.25)) {
            selectedDay = day
            centeredDay = day
        }
    }

    private func selectToday() {
        withAnimation(.snappy(duration: 0.3)) {
            selectedDay = today
            centeredDay = today
        }
    }

    private func handleBarTap(_ segment: TripSegment) {
        guard let flight = plannedFlights.first(where: { $0.id.uuidString == segment.span.id }) else {
            return
        }
        popupContext = FlightPopupContext(flight: flight)
    }

    // MARK: - Derived: Day Range

    private var days: [Date] {
        let range = dateRange
        var result: [Date] = []
        var cursor = range.start
        while cursor <= range.end {
            result.append(cursor)
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return result
    }

    private var dateRange: (start: Date, end: Date) {
        let all = sectors.map(\.date) + savedTrips.map(\.flightDate)
        let earliest = all.min() ?? today
        let latest = all.max() ?? today

        let startMonth = calendar.dateInterval(of: .month, for: earliest)?.start ?? today
        let endReference = max(latest, today)
        let endMonth = calendar.dateInterval(of: .month, for: endReference)
        let endOfMonth = endMonth.flatMap { calendar.date(byAdding: .day, value: -1, to: $0.end) } ?? today

        return (calendar.startOfDay(for: startMonth), calendar.startOfDay(for: endOfMonth))
    }

    // MARK: - Derived: Centered Month Label

    private var centeredMonthLabel: String {
        let reference = centeredDay ?? selectedDay
        return Self.monthFormatter.string(from: reference)
    }

    // MARK: - Derived: Trips

    /// One bar per trip. PlannedFlight bars are time-precise: from the first
    /// sector's departure (in its station timezone) to the last sector's
    /// arrival (in its station timezone), converted to device local time.
    /// SavedTrip bars cover the full single calendar day since per-sector
    /// times aren't available there.
    private var tripSpans: [TripSpan] {
        var result: [TripSpan] = []

        for flight in plannedFlights {
            let sorted = flight.sectors.sorted { $0.sectorIndex < $1.sectorIndex }
            guard let first = sorted.first, let last = sorted.last else { continue }

            let absoluteStart = absoluteDateTime(date: first.date,
                                                 time: first.departureTime,
                                                 station: first.departureStation)
            let absoluteEnd = arrivalDateTime(sector: last)

            let startDay = calendar.startOfDay(for: absoluteStart)
            let endDay = calendar.startOfDay(for: absoluteEnd)
            let dest = destinationLabel(routeString: flight.routeString)
            // Prefer the parent trip number (covers the whole journey, e.g.
            // "6201"); fall back to the first sector's flight number when the
            // trip number is missing.
            let trimmedTripNumber = flight.tripNumber.trimmingCharacters(in: .whitespaces)
            let number: String? = !trimmedTripNumber.isEmpty
                ? trimmedTripNumber
                : (flight.flightNumber.isEmpty ? nil : flight.flightNumber)
            let label = number.map { "\($0) · \(dest)" } ?? dest
            result.append(TripSpan(id: flight.id.uuidString,
                                   startDay: startDay, endDay: endDay,
                                   absoluteStart: absoluteStart,
                                   absoluteEnd: absoluteEnd,
                                   flightNumber: number,
                                   destination: dest,
                                   label: label,
                                   color: paletteColor(for: flight.id.uuidString)))
        }

        for trip in savedTrips {
            let day = calendar.startOfDay(for: trip.flightDate)
            let dayEnd = day.addingTimeInterval(86_400)
            let dest = destinationLabel(legs: trip.flightLegs)
            let number: String? = trip.flightNumber.isEmpty ? nil : trip.flightNumber
            let label = number.map { "\($0) · \(dest)" } ?? dest
            result.append(TripSpan(id: trip.tripKey,
                                   startDay: day, endDay: day,
                                   absoluteStart: day,
                                   absoluteEnd: dayEnd,
                                   flightNumber: number,
                                   destination: dest,
                                   label: label,
                                   color: paletteColor(for: trip.tripKey)))
        }

        return result
    }

    // MARK: - Absolute Date Helpers

    /// Build an absolute Date from a sector's date + an "HH:mm" time string
    /// interpreted in the given station's timezone.
    private func absoluteDateTime(date: Date, time: String, station: String) -> Date {
        let parts = time.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return date }
        let tz = StationTimezones.timeZone(for: station) ?? .current
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        let day = cal.dateComponents([.year, .month, .day], from: date)
        var components = DateComponents()
        components.year = day.year
        components.month = day.month
        components.day = day.day
        components.hour = parts[0]
        components.minute = parts[1]
        components.timeZone = tz
        return cal.date(from: components) ?? date
    }

    /// Sector arrival as an absolute date. Adds a day if the arrival time
    /// falls before the departure (overnight flight).
    private func arrivalDateTime(sector: PlannedSector) -> Date {
        let timeString = sector.actualLandingTime ?? sector.arrivalTime
        var arrival = absoluteDateTime(date: sector.date,
                                        time: timeString,
                                        station: sector.arrivalStation)
        let departure = absoluteDateTime(date: sector.date,
                                          time: sector.departureTime,
                                          station: sector.departureStation)
        if arrival < departure {
            arrival = arrival.addingTimeInterval(86_400)
        }
        return arrival
    }

    private func destinationLabel(routeString: String) -> String {
        let parts = routeString.split(separator: "-").map { $0.trimmingCharacters(in: .whitespaces) }
        return parts.first(where: { $0 != "DXB" && !$0.isEmpty }) ?? parts.last ?? "—"
    }

    private func destinationLabel(legs: [String]) -> String {
        legs.first(where: { $0 != "DXB" && !$0.isEmpty }) ?? legs.last ?? "—"
    }

    private func tripSegment(for day: Date) -> TripSegment? {
        for span in tripSpans where day >= span.startDay && day <= span.endDay {
            let position: TripSegment.Position
            if calendar.isDate(span.startDay, inSameDayAs: span.endDay) {
                position = .single
            } else if calendar.isDate(day, inSameDayAs: span.startDay) {
                position = .start
            } else if calendar.isDate(day, inSameDayAs: span.endDay) {
                position = .end
            } else {
                position = .middle
            }
            let totalDays = (calendar.dateComponents([.day], from: span.startDay, to: span.endDay).day ?? 0) + 1
            return TripSegment(span: span, position: position, totalDays: max(totalDays, 1))
        }
        return nil
    }

    /// Uniform pastel blue fill for every trip capsule. Distinguishing
    /// adjacent trips visually is handled by the rounded caps at trip
    /// boundaries and the trip-number label, not by color rotation.
    private static let tripFill = Color(red: 0xB9/255.0, green: 0xCC/255.0, blue: 0xEE/255.0)

    /// Dark navy used for any text rendered on top of the pastel chips and
    /// trip capsules.
    private static let chipTextColor = Color(red: 0x16/255.0, green: 0x28/255.0, blue: 0x4F/255.0)

    private func paletteColor(for key: String) -> Color { Self.tripFill }

    // MARK: - Adaptive Day Window

    /// Adapts the visible day window to the available width:
    /// - iPhone / narrow split-screen (< 700pt): 7 days
    /// - iPad portrait (700–1100pt): 10 days
    /// - iPad landscape (≥ 1100pt): 18 days
    private func updateVisibleCount(for width: CGFloat) {
        let next: Int
        if width < 700 { next = 7 }
        else if width < 1100 { next = 10 }
        else { next = 18 }
        if next != visibleDayCount {
            visibleDayCount = next
            DispatchQueue.main.async {
                centeredDay = selectedDay
            }
        }
    }

    // MARK: - Formatters

    private static let weekdayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_GB")
        f.dateFormat = "EEE"
        return f
    }()

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_GB")
        f.dateFormat = "MMMM yyyy"
        return f
    }()
}

// MARK: - Trip Span

private struct TripSpan {
    let id: String
    /// Calendar day (start-of-day) of the trip's first day.
    let startDay: Date
    /// Calendar day (start-of-day) of the trip's last day.
    let endDay: Date
    /// Absolute moment the trip starts (device local timezone).
    let absoluteStart: Date
    /// Absolute moment the trip ends (device local timezone).
    let absoluteEnd: Date
    let flightNumber: String?
    let destination: String
    let label: String
    let color: Color
}

// MARK: - Trip Segment

private struct TripSegment {
    enum Position { case start, middle, end, single }

    let span: TripSpan
    let position: Position
    let totalDays: Int

    /// Rounded-rect shape with caps only on outer edges of the trip.
    var shape: some Shape {
        let radius: CGFloat = 8
        switch position {
        case .single: return UnevenRoundedRectangle(
            topLeadingRadius: radius, bottomLeadingRadius: radius,
            bottomTrailingRadius: radius, topTrailingRadius: radius,
            style: .continuous)
        case .start: return UnevenRoundedRectangle(
            topLeadingRadius: radius, bottomLeadingRadius: radius,
            bottomTrailingRadius: 0, topTrailingRadius: 0,
            style: .continuous)
        case .end: return UnevenRoundedRectangle(
            topLeadingRadius: 0, bottomLeadingRadius: 0,
            bottomTrailingRadius: radius, topTrailingRadius: radius,
            style: .continuous)
        case .middle: return UnevenRoundedRectangle(
            topLeadingRadius: 0, bottomLeadingRadius: 0,
            bottomTrailingRadius: 0, topTrailingRadius: 0,
            style: .continuous)
        }
    }
}

// MARK: - Flight Popup Context

private struct FlightPopupContext: Identifiable {
    let flight: PlannedFlight
    var id: UUID { flight.id }
}

// MARK: - Trip Sectors Sheet

/// Bottom sheet listing all sectors of the tapped trip. Tapping a sector
/// dismisses the sheet and forwards selection to `onSelect`.
private struct TripSectorsSheet: View {
    let flight: PlannedFlight
    var onSelect: (PlannedSector) -> Void
    var onEditTrip: () -> Void

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_GB")
        f.dateFormat = "EEE, dd MMM"
        return f
    }()

    private var sortedSectors: [PlannedSector] {
        flight.sectors.sorted { $0.sectorIndex < $1.sectorIndex }
    }

    var body: some View {
        NavigationStack {
            List(sortedSectors) { sector in
                Button {
                    onSelect(sector)
                } label: {
                    HStack(spacing: AppSpacing.md) {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(sector.flightNumber.isEmpty ? "EK—" : sector.flightNumber)
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundStyle(AppColor.textPrimary)
                                Text("·")
                                    .foregroundStyle(AppColor.textTertiary)
                                Text("\(sector.departureStation) – \(sector.arrivalStation)")
                                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                                    .foregroundStyle(AppColor.textPrimary)
                            }
                            Text(Self.dateFormatter.string(from: sector.date))
                                .font(.system(size: 12))
                                .foregroundStyle(AppColor.textSecondary)
                            HStack(spacing: 4) {
                                Text(sector.departureTime)
                                Text("→")
                                Text(sector.arrivalTime)
                            }
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(AppColor.textTertiary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppColor.textTertiary)
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
            .navigationTitle(sheetTitle)
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                Button(action: onEditTrip) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Edit Trip")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(AppColor.navyAccent))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.sm)
                .background(.bar)
            }
        }
    }

    private var sheetTitle: String {
        let route = flight.routeString
        if flight.flightNumber.isEmpty { return route }
        return "\(flight.flightNumber) · \(route)"
    }
}

// MARK: - Duty Chip View

/// Tappable duty chip. Shows the short code on the calendar strip; tapping
/// presents a portal-style popover with the duty's title and date/time range.
private struct DutyChipView: View {
    let duty: PlannedDuty

    @State private var isShowingPopover = false

    private static let popoverBackground = Color(red: 0x1F/255.0, green: 0x2D/255.0, blue: 0x3F/255.0)
    private static let chipTextColor = Color(red: 0x16/255.0, green: 0x28/255.0, blue: 0x4F/255.0)

    var body: some View {
        Button {
            isShowingPopover = true
        } label: {
            chip
        }
        .buttonStyle(.plain)
        .popover(isPresented: $isShowingPopover, arrowEdge: .top) {
            popoverContent
                .presentationCompactAdaptation(.popover)
        }
        .accessibilityLabel(Text(duty.title.isEmpty ? duty.category.label : duty.title))
    }

    // MARK: Chip

    private var chip: some View {
        ZStack {
            Capsule(style: .continuous)
                .fill(duty.category.color)
                .frame(height: 22)
            Text(duty.category.shortCode)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(Self.chipTextColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 4)
                .allowsHitTesting(false)
        }
        .padding(.horizontal, 6)
        .padding(.top, 4)
    }

    // MARK: Popover

    private var popoverContent: some View {
        HStack(alignment: .top, spacing: 0) {
            Rectangle()
                .fill(duty.category.color)
                .frame(width: 5)

            VStack(alignment: .leading, spacing: 6) {
                Text(popoverTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                if let range = dateRangeLabel {
                    Text(range)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(2)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minWidth: 260, idealWidth: 320)
        .background(Self.popoverBackground)
        .presentationBackground(Self.popoverBackground)
    }

    // MARK: Derived

    private var popoverTitle: String {
        let trimmed = duty.title.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? duty.category.label : trimmed
    }

    private var dateRangeLabel: String? {
        let f = DateFormatter()
        f.dateFormat = "EEE dd-MMM-yy, HH:mm"
        f.locale = Locale(identifier: "en_GB")
        if let start = duty.startDate, let end = duty.endDate {
            return "\(f.string(from: start)) - \(f.string(from: end))"
        }
        if let start = duty.startDate {
            return f.string(from: start)
        }
        return nil
    }
}

// MARK: - Preview

#Preview {
    DayCalendarStrip()
        .padding()
        .background(AppColor.background)
}
