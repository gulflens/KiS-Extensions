import SwiftUI

// MARK: - We Care View

struct WeCareView: View {
    @Bindable var state: WeCareState
    let sector: PlannedSector

    @State private var shareItem: WeCareShareItem?

    private var sectorLabel: String {
        "\(sector.departureStation) - \(sector.arrivalStation)"
    }

    private var result: WeCareResult {
        var base = WeCareCalculator.calculate(state: state)
        if !state.crewByCabin.isEmpty {
            WeCareCrewResolver.assignCrew(
                cabinResults: &base.cabinResults,
                crewByCabin: state.crewByCabin,
                breakSchedule: state.breakEntries
            )
        }
        return base
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            cabinFilterBar

            if result.isEligible {
                ScrollView {
                    VStack(spacing: 16) {
                        flightSummaryCard
                        serviceSummaryCard

                        ForEach(result.cabinResults) { cabinResult in
                            cabinCard(cabinResult)
                        }
                    }
                    .padding(16)
                }
            } else {
                ineligibleView
            }
        }
        .sheet(item: $shareItem) { item in
            WeCareShareSheet(items: [item.url])
        }
    }

    // MARK: - Cabin Filter Bar

    private var cabinFilterBar: some View {
        HStack(spacing: 8) {
            ForEach(state.availableCabins) { cabin in
                let enabled = isCabinEnabled(cabin)
                Button {
                    toggleCabin(cabin)
                } label: {
                    Text(cabin.shortCode)
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(enabled ? cabinColor(cabin) : Color(.systemGray5))
                        .foregroundStyle(enabled ? .white : .secondary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            Spacer()

            if !state.aircraftModel.isEmpty {
                Text("\(state.aircraftModel) \(state.numberOfClasses)-class")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .clipShape(Capsule())
            }

            let durH = state.flightDurationMin / 60
            let durM = state.flightDurationMin % 60
            Text(String(format: "%dh %02dm", durH, durM))
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)

            if result.isEligible {
                Menu {
                    Button {
                        WeCarePrinter.print(result: result, state: state, sectorLabel: sectorLabel)
                    } label: {
                        Label("Print", systemImage: "printer")
                    }
                    Button {
                        if let url = WeCarePrinter.sharePDF(result: result, state: state, sectorLabel: sectorLabel) {
                            shareItem = WeCareShareItem(url: url)
                        }
                    } label: {
                        Label("Share as PDF", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 18))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.systemGroupedBackground))
        .overlay(alignment: .bottom) { Divider() }
    }

    // MARK: - Flight Summary Card

    private var flightSummaryCard: some View {
        HStack(spacing: 24) {
            summaryItem("Takeoff", WeCareCalculator.formatMinutes(state.takeoffMin))
            summaryItem("Landing", WeCareCalculator.formatMinutes(state.landingMin))
            summaryItem("Top of descent", WeCareCalculator.formatMinutes(state.topOfDescentMin))
            summaryItem("Services", "\(state.numberOfServices)")
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color(.separator).opacity(0.2), lineWidth: 0.5)
        )
    }

    private func summaryItem(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
        }
    }

    // MARK: - Service Summary Card

    private var serviceSummaryCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "tray.full")
                    .font(.caption2.weight(.semibold))
                Text("Service placements")
                    .font(.caption2.weight(.bold))
                    .tracking(0.6)
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 6)

            ForEach(result.servicePlacements) { svc in
                HStack {
                    Text(serviceName(svc.serviceNumber, of: state.numberOfServices))
                        .font(.system(size: 13))
                    Spacer()
                    if svc.durationJC > 0 {
                        timeBadge(
                            label: "JC",
                            start: WeCareCalculator.formatMinutes(svc.startMin),
                            end: WeCareCalculator.formatMinutes(svc.startMin + svc.durationJC),
                            color: .blue
                        )
                    }
                    if svc.durationJC > 0 && svc.durationYC > 0 {
                        Spacer().frame(width: 6)
                    }
                    if svc.durationYC > 0 {
                        timeBadge(
                            label: "YC",
                            start: WeCareCalculator.formatMinutes(svc.startMin),
                            end: WeCareCalculator.formatMinutes(svc.startMin + svc.durationYC),
                            color: Color(red: 0.0, green: 0.5, blue: 0.0)
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)

                if svc.serviceNumber < state.numberOfServices {
                    Divider().opacity(0.3).padding(.horizontal, 20)
                }
            }

            Spacer().frame(height: 6)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color(.separator).opacity(0.2), lineWidth: 0.5)
        )
    }

    private func timeBadge(label: String, start: String, end: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(color)
            Text("\(start) \u{2013} \(end)")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(color.opacity(0.06), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Cabin Card

    private func cabinCard(_ cabinResult: CabinWeCareResult) -> some View {
        let color = cabinColor(cabinResult.cabin)

        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                Circle().fill(color).frame(width: 8, height: 8)
                Text(cabinResult.cabin.rawValue)
                    .font(.subheadline.weight(.semibold))
                Text("\(cabinResult.cabin.cycleDurationMin)-min cycles")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(cabinResult.totalCycles) cycle\(cabinResult.totalCycles == 1 ? "" : "s")")
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(color.opacity(0.1))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(color.opacity(0.04))

            if cabinResult.gaps.isEmpty {
                HStack {
                    Spacer()
                    Text("No We Care gaps available")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
                .padding(.vertical, 12)
            }

            ForEach(cabinResult.gaps) { gap in
                gapSection(gap, color: color)

                if gap.id != cabinResult.gaps.last?.id {
                    Divider()
                }
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

    @ViewBuilder
    private func gapSection(_ gap: WeCareGap, color: Color) -> some View {
        HStack {
            Text(gap.afterService > 0 ? "After service \(gap.afterService)" : "No services in cabin")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(gap.availableMin) min available")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 5)
        .background(Color(.systemGray6).opacity(0.5))

        ForEach(gap.cycles) { cycle in
            HStack {
                Text("Cycle \(cycle.cycleNumber)")
                    .font(.system(size: 13))
                if let crew = cycle.assignedCrew.first {
                    Text(crew)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray6))
                        .clipShape(Capsule())
                }
                Spacer()
                Text("\(WeCareCalculator.formatMinutes(cycle.startMin)) \u{2013} \(WeCareCalculator.formatMinutes(cycle.endMin))")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(color)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)

            if cycle.id != gap.cycles.last?.id {
                Divider().opacity(0.3).padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Ineligible View

    private var ineligibleView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "clock.badge.xmark")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
            Text(result.ineligibilityReason ?? "Not eligible")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            let durH = state.flightDurationMin / 60
            let durM = state.flightDurationMin % 60
            Text("Current flight duration: \(durH)h \(String(format: "%02d", durM))m")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Spacer()
        }
    }

    // MARK: - Helpers

    private func isCabinEnabled(_ cabin: WeCareCabin) -> Bool {
        switch cabin {
        case .firstClass: return state.enableFC
        case .businessClass: return state.enableJC
        case .premiumEconomy: return state.enableWC
        case .economyClass: return state.enableYC
        }
    }

    private func toggleCabin(_ cabin: WeCareCabin) {
        switch cabin {
        case .firstClass: state.enableFC.toggle()
        case .businessClass: state.enableJC.toggle()
        case .premiumEconomy: state.enableWC.toggle()
        case .economyClass: state.enableYC.toggle()
        }
    }

    private func cabinColor(_ cabin: WeCareCabin) -> Color {
        switch cabin {
        case .firstClass: return Color(red: 0.75, green: 0.55, blue: 0.15)
        case .businessClass: return .blue
        case .premiumEconomy: return .purple
        case .economyClass: return Color(red: 0.0, green: 0.5, blue: 0.0)
        }
    }

    private func serviceName(_ number: Int, of total: Int) -> String {
        if total == 1 { return "Service" }
        switch number {
        case 1: return "First service"
        case _ where number == total: return "Last service"
        default: return "Middle service"
        }
    }
}
